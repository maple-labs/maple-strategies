// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { IMapleBasicStrategy } from "./interfaces/basicStrategy/IMapleBasicStrategy.sol";

import {
    IERC20Like,
    IERC4626Like,
    IGlobalsLike,
    IPoolLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { MapleBasicStrategyStorage } from "./proxy/basicStrategy/MapleBasicStrategyStorage.sol";

import { MapleAbstractStrategy } from "./MapleAbstractStrategy.sol";

/*
    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

    ███████╗████████╗██████╗  █████╗ ████████╗███████╗ ██████╗██╗   ██╗
    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝╚██╗ ██╔╝
    ███████╗   ██║   ██████╔╝███████║   ██║   █████╗  ██║  ███╗╚████╔╝
    ╚════██║   ██║   ██╔══██╗██╔══██║   ██║   ██╔══╝  ██║   ██║ ╚██╔╝
    ███████║   ██║   ██║  ██║██║  ██║   ██║   ███████╗╚██████╔╝  ██║
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝   ╚═╝

*/

// TODO Ensure events are consistent across strategies
contract MapleBasicStrategy is IMapleBasicStrategy, MapleBasicStrategyStorage , MapleAbstractStrategy {

    uint256 public override constant HUNDRED_PERCENT = 1e6;  // 100.0000%

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Validation before and after funding
    // TODO: Should we pass a min amount of shares we expect and validate
    function fundStrategy(uint256 assets_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address strategyVault_ = strategyVault;

        require(IGlobalsLike(globals()).isInstanceOf("STRATEGY_VAULT", strategyVault_), "MBS:FS:INVALID_STRATEGY_VAULT");

        _accrueFees(strategyVault_);

        lastRecordedTotalAssets += assets_;

        _prepareFundsForStrategy(strategyVault_, assets_);

        IERC4626Like(strategyVault_).deposit(assets_, address(this));

        emit StrategyFunded(assets_);
    }

    // TODO: Validation before and after funding
    // TODO: Should we pass in the min amount of assets we expect and validate
    function withdrawFromStrategy(uint256 assets_) public override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        require(assets_ <= assetsUnderManagement(), "MBS:WFS:LOW_ASSETS");

        address strategyVault_ = strategyVault;

        _accrueFees(strategyVault_);

        lastRecordedTotalAssets -= assets_;

        IERC4626Like(strategyVault_).withdraw(assets_, address(pool), address(this));

        emit StrategyWithdrawal(assets_);
    }

    function setStrategyFeeRate(uint256 strategyFeeRate_) external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins {
        require(strategyFeeRate_ <= HUNDRED_PERCENT, "MBS:SSFR:INVALID_STRATEGY_FEE_RATE");

        address strategyVault_ = strategyVault;

        // Account for any fees before changing the fee rate
        _accrueFees(strategyVault_);

        strategyFeeRate = strategyFeeRate_;

        emit StrategyFeeRateSet(strategyFeeRate_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function assetsUnderManagement() public view override returns (uint256 assetsUnderManagement_) {
        address strategyVault_      = strategyVault;
        uint256 currentTotalAssets_ = IERC4626Like(strategyVault_).convertToAssets(IERC20Like(strategyVault_).balanceOf(address(this)));
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
        uint256 currentTotalAssets_ = IERC4626Like(strategyVault_).convertToAssets(IERC20Like(strategyVault_).balanceOf(address(this)));

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
            IERC4626Like(strategyVault_).withdraw(strategyFee_, treasury(), address(this));

            emit FeeWithdrawal(strategyFee_);
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
        require(ERC20Helper.approve(fundsAsset, destination_, amount_), "MBS:PFFS:APPROVE_FAILED");
    }

    function _setLock(uint256 lock_) internal override {
        locked = lock_;
    }

    function _locked() internal view override returns (uint256) {
        return locked;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function asset() public view override returns (address asset_) {
        asset_ = fundsAsset;
    }

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
