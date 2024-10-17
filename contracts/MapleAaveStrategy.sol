// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { IMapleAaveStrategy } from "./interfaces/aaveStrategy/IMapleAaveStrategy.sol";
import {
    IAavePoolLike,
    IAaveTokenLike,
    IGlobalsLike,
    IMapleProxyFactoryLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { MapleAaveStrategyStorage } from "./proxy/aaveStrategy/MapleAaveStrategyStorage.sol";

import { MapleAaveStrategy }     from "./MapleAaveStrategy.sol";
import { MapleAbstractStrategy } from "./MapleAbstractStrategy.sol";

// TODO: Add functions/state for both defaults (`setDefault`, `isDefaulted`) and impairments (`setImpairment`, `isImpaired`).
// TODO: Include management fees (percentage of yield).
contract MapleAaveStrategy is IMapleAaveStrategy, MapleAbstractStrategy, MapleAaveStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function fundStrategy(uint256 assets_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address aavePool_   = aavePool;
        address fundsAsset_ = fundsAsset;

        require(IGlobalsLike(globals()).isInstanceOf("STRATEGY_VAULT", aavePool_), "MAS:FS:INVALID_STRATEGY_VAULT");
        require(ERC20Helper.approve(fundsAsset_, aavePool_, assets_),              "MAS:FS:APPROVE_FAIL");

        IPoolManagerLike(poolManager).requestFunds(address(this), assets_);

        IAavePoolLike(aavePool_).supply(fundsAsset_, assets_, address(this), 0);

        emit StrategyFunded(assets_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function assetsUnderManagement() external view virtual override returns (uint256) {
        return IAaveTokenLike(aaveToken).balanceOf(address(this));
    }

    /**************************************************************************************************************************************/
    /*** Utility Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

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

}
