// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import {
    IERC20Like,
    IERC4626Like,
    IGlobalsLike,
    IPoolLike,
    IPoolManagerLike,
    IPSMLike
} from "./interfaces/Interfaces.sol";

import { IMapleSkyStrategy } from "./interfaces/skyStrategy/IMapleSkyStrategy.sol";

import { MapleSkyStrategyStorage } from "./proxy/skyStrategy/MapleSkyStrategyStorage.sol";

import { MapleAbstractStrategy, StrategyState } from "./MapleAbstractStrategy.sol";

// TODO: Consider infinite approvals
contract MapleSkyStrategy is IMapleSkyStrategy, MapleSkyStrategyStorage, MapleAbstractStrategy {

    uint256 internal constant WAD = 1e18;

    uint256 public override constant HUNDRED_PERCENT = 1e6;  // 100.0000%

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function fundStrategy(uint256 assetsIn_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address globals_ = globals();
        address psm_     = psm;

        require(IGlobalsLike(globals_).isInstanceOf("STRATEGY_VAULT", savingsUsds), "MSS:FS:INVALID_STRATEGY_VAULT");
        require(IGlobalsLike(globals_).isInstanceOf("PSM", psm_),                   "MSS:FS:INVALID_PSM");

        _accrueFees(savingsUsds);

        lastRecordedTotalAssets += assetsIn_;

        _prepareFundsForStrategy(psm_, assetsIn_);

        // NOTE: Assume Gem asset and USDS are interchangeable 1:1 for the purposes of Pool Accounting
        uint256 usdsOut_ = IPSMLike(psm_).sellGem(address(this), assetsIn_);

        // Deposit into sUSDS
        IERC4626Like(savingsUsds).deposit(usdsOut_, address(this));

        emit StrategyFunded(assetsIn_);
    }

    function withdrawFromStrategy(uint256 assetsOut_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        require(assetsOut_ <= assetsUnderManagement(), "MSS:WFS:LOW_ASSETS");

        address strategyVault_ = savingsUsds;

        _accrueFees(strategyVault_);

        lastRecordedTotalAssets -= assetsOut_;

        _withdraw(strategyVault_, assetsOut_, pool);

        emit StrategyWithdrawal(assetsOut_);
    }

    function setStrategyFeeRate(uint256 strategyFeeRate_) external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins {
        require(strategyFeeRate_ <= HUNDRED_PERCENT, "MSS:SSFR:INVALID_STRATEGY_FEE_RATE");

        address strategyVault_ = savingsUsds;

        // Account for any fees before changing the fee rate
        _accrueFees(strategyVault_);

        strategyFeeRate = strategyFeeRate_;

        emit StrategyFeeRateSet(strategyFeeRate_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function assetsUnderManagement() public view override returns (uint256 assetsUnderManagement_) {
        uint256 currentTotalAssets_ = _currentTotalAssets();
        uint256 currentAccruedFees_ = _currentAccruedFees(currentTotalAssets_);

        // TODO: Confirm we we need to account for this first case.
        currentTotalAssets_ <= currentAccruedFees_
            ? assetsUnderManagement_ = 0
            : assetsUnderManagement_ = currentTotalAssets_ - currentAccruedFees_;
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _accrueFees(address strategyVault_) internal {
        uint256 currentTotalAssets_ = _currentTotalAssets();

        uint256 lastRecordedTotalAssets_ = lastRecordedTotalAssets;
        uint256 strategyFeeRate_         = strategyFeeRate;

        // No fees to accrue if TotalAssets has decreased or fee rate is zero.
        if (currentTotalAssets_ <= lastRecordedTotalAssets_ || strategyFeeRate_ == 0) {
            // Record currentTotalAssets
            lastRecordedTotalAssets = currentTotalAssets_;
            return;
        }

        // Yield accrued since last collection.
        // Can't underflow due to check above.
        uint256 yieldAccrued_ = currentTotalAssets_ - lastRecordedTotalAssets_;

        // Calculate strategy fee.
        // It is acknowledged that `strategyFee_` may be rounded down to 0 if `yieldAccrued_ * strategyFeeRate < HUNDRED_PERCENT`.
        uint256 strategyFee_ = yieldAccrued_ * strategyFeeRate / HUNDRED_PERCENT;

        // Withdraw the fees from the strategy vault.
        if (strategyFee_ != 0) {
            _withdraw(strategyVault_, strategyFee_, treasury());

            emit StrategyFeesCollected(strategyFee_);
        }

        // Record the TotalAssets
        // Can't underflow as `strategyFee_` is <= `currentTotalAssets_`.
        lastRecordedTotalAssets = currentTotalAssets_ - strategyFee_;
    }

    function _currentAccruedFees(uint256 currentTotalAssets_) internal view returns (uint256 currentAccruedFees_) {
        uint256 lastRecordedTotalAssets_ = lastRecordedTotalAssets;
        uint256 strategyFeeRate_         = strategyFeeRate;

        // No fees to accrue if TotalAssets has decreased or fee rate is zero.
        if (currentTotalAssets_ <= lastRecordedTotalAssets_ || strategyFeeRate_ == 0) {
            return 0;
        }

        // Yield accrued since last collection.
        // Can't underflow due to check above.
        uint256 yieldAccrued_ = currentTotalAssets_ - lastRecordedTotalAssets_;

        // Calculate strategy fee.
        // It is acknowledged that `currentAccruedFees_` may be rounded down to 0 if `yieldAccrued_ * strategyFeeRate < HUNDRED_PERCENT`.
        currentAccruedFees_ = yieldAccrued_ * strategyFeeRate / HUNDRED_PERCENT;
    }

    function _prepareFundsForStrategy(address destination_, uint256 amount_) internal {
        // Request funds from Pool Manager.
        IPoolManagerLike(poolManager).requestFunds(address(this), amount_);

        // Approve the strategy to use these funds.
        require(ERC20Helper.approve(fundsAsset, destination_, amount_), "MSS:PFFS:APPROVE_FAILED");
    }

    function _setLock(uint256 lock_) internal override {
        locked = lock_;
    }

    function _locked() internal view override returns (uint256) {
        return locked;
    }

    function _strategyState() internal view override returns (StrategyState) {
        return strategyState;
    }

    function _gemForUsds(uint256 usdsAmount_) internal view returns (uint256 gemAmount_) {
        uint256 tout                 = IPSMLike(psm).tout();
        uint256 to18ConversionFactor = IPSMLike(psm).to18ConversionFactor();

        // Inverse of `_usdsForGem(gemAmount_)`
        gemAmount_ = (usdsAmount_ * WAD) / (to18ConversionFactor * (WAD + tout));
    }

    function _usdsForGem(uint256 gemAmount_) internal view returns (uint256 usdsAmount_) {
        uint256 tout                 = IPSMLike(psm).tout();
        uint256 to18ConversionFactor = IPSMLike(psm).to18ConversionFactor();

        // Inverse of `_gemForUsds(usdsAmount_)`
        usdsAmount_ = (gemAmount_  * to18ConversionFactor * (WAD + tout)) / WAD;
    }

    function _currentTotalAssets() internal view returns (uint256) {
        return _gemForUsds(IERC4626Like(savingsUsds).convertToAssets(IERC20Like(savingsUsds).balanceOf(address(this))));
    }

    function _withdraw(address strategyVault_, uint256 assets_, address destination_) internal {
        uint256 requiredUsds_ = _usdsForGem(assets_);

        IERC4626Like(strategyVault_).withdraw(requiredUsds_, address(this), address(this));

        require(ERC20Helper.approve(usds, psm, requiredUsds_), "MSS:WFS:APPROVE_FAIL");

        // There might be some USDS left over in this contract due to rounding.
        IPSMLike(psm).buyGem(address(this), assets_);

        // Send the asset to the pool
        require(ERC20Helper.transfer(fundsAsset, destination_, assets_), "MSS:WFS:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view override returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function securityAdmin() public view override returns (address securityAdmin_) {
        securityAdmin_ = IGlobalsLike(globals()).securityAdmin();
    }

    function treasury() public view override returns (address treasury_) {
        treasury_ = IGlobalsLike(globals()).mapleTreasury();
    }

}
