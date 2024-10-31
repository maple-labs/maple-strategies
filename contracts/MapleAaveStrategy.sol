// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { StrategyState }      from "./interfaces/IMapleStrategy.sol";
import { IMapleAaveStrategy } from "./interfaces/aaveStrategy/IMapleAaveStrategy.sol";

import {
    IAavePoolLike,
    IAaveTokenLike,
    IGlobalsLike,
    IMapleProxyFactoryLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { MapleAaveStrategyStorage } from "./proxy/aaveStrategy/MapleAaveStrategyStorage.sol";

import { MapleAbstractStrategy } from "./MapleAbstractStrategy.sol";

// TODO: Add more state variable caching.
contract MapleAaveStrategy is IMapleAaveStrategy, MapleAbstractStrategy, MapleAaveStrategyStorage {

    uint256 public constant HUNDRED_PERCENT = 1e6;

    /**************************************************************************************************************************************/
    /*** Strategy Manager Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    function fundStrategy(uint256 assetsIn_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager onlyActive {
        address aavePool_   = aavePool;
        address aaveToken_  = aaveToken;
        address fundsAsset_ = fundsAsset;

        require(IGlobalsLike(globals()).isInstanceOf("STRATEGY_VAULT", aaveToken_), "MAS:FS:INVALID_AAVE_TOKEN");

        _accrueFees(aavePool_, aaveToken_, fundsAsset_);

        lastRecordedTotalAssets += assetsIn_;

        IPoolManagerLike(poolManager).requestFunds(address(this), assetsIn_);

        IAavePoolLike(aavePool_).supply(fundsAsset_, assetsIn_, address(this), 0);

        emit StrategyFunded(assetsIn_);
    }

    function withdrawFromStrategy(uint256 assetsOut_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address aavePool_   = aavePool;
        address fundsAsset_ = fundsAsset;

        // Strategy only accrues fees when it is active.
        if (_strategyState() == StrategyState.Active) {
            require(assetsOut_ <= assetsUnderManagement(), "MAS:WFS:LOW_ASSETS");

            _accrueFees(aavePool_, aaveToken, fundsAsset_);

            lastRecordedTotalAssets -= assetsOut_;
        }

        IAavePoolLike(aavePool_).withdraw(fundsAsset_, assetsOut_, pool);

        emit StrategyWithdrawal(assetsOut_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy Admin Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function deactivateStrategy() external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins {
        require(_strategyState() != StrategyState.Inactive, "MAS:DS:ALREADY_INACTIVE");

        strategyState = StrategyState.Inactive;

        emit StrategyDeactivated();
    }

    function impairStrategy() external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins {
        require(_strategyState() != StrategyState.Impaired, "MAS:IS:ALREADY_IMPAIRED");

        strategyState = StrategyState.Impaired;

        emit StrategyImpaired();
    }

    function reactivateStrategy(bool updateAccounting_) external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins {
        require(_strategyState() != StrategyState.Active, "MAS:RS:ALREADY_ACTIVE");

        // Updating the fee accounting will result in no fees being charged for the period of impairment and/or inactivity.
        // Otherwise, fees will be charged retroactively as if no impairment and/or deactivation occurred.
        if (updateAccounting_) {
            lastRecordedTotalAssets = _currentTotalAssets(aaveToken);
        }

        strategyState = StrategyState.Active;

        emit StrategyReactivated();
    }

    function setStrategyFeeRate(uint256 strategyFeeRate_)
        external override nonReentrant whenProtocolNotPaused onlyProtocolAdmins onlyActive
    {
        require(strategyFeeRate_ <= HUNDRED_PERCENT, "MAS:SSFR:INVALID_FEE_RATE");

        _accrueFees(aavePool, aaveToken, fundsAsset);

        strategyFeeRate = strategyFeeRate_;

        emit StrategyFeeRateSet(strategyFeeRate_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function assetsUnderManagement() public view override returns (uint256 assetsUnderManagement_) {
        // All assets are marked as zero if the strategy is inactive.
        if (_strategyState() == StrategyState.Inactive) {
            return 0;
        }

        uint256 currentTotalAssets_ = _currentTotalAssets(aaveToken);
        uint256 currentAccruedFees_ = _currentAccruedFees(currentTotalAssets_);

        // TODO: Confirm if we need to account for possible underflows.
        assetsUnderManagement_ = currentTotalAssets_ > currentAccruedFees_ ? currentTotalAssets_ - currentAccruedFees_ : 0;
    }

    function unrealizedLosses() external view override returns (uint256 unrealizedLosses_) {
        if (_strategyState() == StrategyState.Impaired) {
            unrealizedLosses_ = assetsUnderManagement();
        }
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _accrueFees(address aavePool_, address aaveToken_, address fundsAsset_) internal {
        uint256 currentTotalAssets_      = _currentTotalAssets(aaveToken_);
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
        // It is acknowledged that `strategyFee_` may be rounded down to 0 if `yieldAccrued_ * strategyFeeRate_ < HUNDRED_PERCENT`.
        uint256 strategyFee_ = yieldAccrued_ * strategyFeeRate_ / HUNDRED_PERCENT;

        // Withdraw the fees from the strategy vault.
        if (strategyFee_ > 0) {
            IAavePoolLike(aavePool_).withdraw(fundsAsset_, strategyFee_, treasury());

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
        // It is acknowledged that `currentAccruedFees_` may be rounded down to 0 if `yieldAccrued_ * strategyFeeRate_ < HUNDRED_PERCENT`.
        currentAccruedFees_ = yieldAccrued_ * strategyFeeRate_ / HUNDRED_PERCENT;
    }

    function _currentTotalAssets(address aaveToken_) internal view returns (uint256 currentTotalAssets_) {
        currentTotalAssets_ = IAaveTokenLike(aaveToken_).balanceOf(address(this));
    }

    function _locked() internal view override returns (uint256) {
        return locked;
    }

    function _setLock(uint256 lock_) internal override {
        locked = lock_;
    }

    function _strategyState() internal view override returns (StrategyState) {
        return strategyState;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
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
