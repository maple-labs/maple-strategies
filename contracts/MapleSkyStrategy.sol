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

import { MapleAbstractStrategy } from "./MapleAbstractStrategy.sol";

contract MapleSkyStrategy is IMapleSkyStrategy, MapleSkyStrategyStorage, MapleAbstractStrategy {

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Should we pass a min amount of shares we expect and validate
    // TODO: consider fees.
    function fundStrategy(uint256 assets_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address globals_ = globals();
        address psm_     = psm;

        require(IGlobalsLike(globals_).isInstanceOf("STRATEGY_VAULT", savingsUsds), "MSS:FS:INVALID_STRATEGY_VAULT");
        require(IGlobalsLike(globals_).isInstanceOf("PSM", psm_),                   "MSS:FS:INVALID_PSM");

        _prepareFundsForStrategy(psm_, assets_);

        // NOTE: Assume Gem asset and USDS are interchangeable 1:1 for the purposes of Pool Accounting
        uint256 usdsOut_ = IPSMLike(psm_).sellGem(address(this), assets_);

        // Deposit into sUSDS
        uint256 shares_ = IERC4626Like(savingsUsds).deposit(usdsOut_, address(this));

        emit StrategyFunded(assets_, shares_, usdsOut_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function assetsUnderManagement() external view virtual override returns (uint256) {
        // TODO: CONSIDER PSM FEES
        return IERC4626Like(savingsUsds).convertToAssets(IERC20Like(savingsUsds).balanceOf(address(this)));
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/


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

}
