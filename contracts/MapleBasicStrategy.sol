// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleStrategy } from "./interfaces/IMapleStrategy.sol";

import {
    IERC20Like,
    IGlobalsLike,
    IPoolLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { MapleStrategyStorage } from "./proxy/MapleStrategyStorage.sol";

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

contract MapleBasicStrategy is IMapleStrategy, MapleStrategyStorage , MapleProxiedInternals {

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    // TODO: Can we use transient storage?
    modifier nonReentrant() {
        require(_locked == 1, "MS:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier whenProtocolNotPaused() {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "MS:PAUSED");
        _;
    }

    /**************************************************************************************************************************************/
    /*** Proxy Functions                                                                                                                ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenProtocolNotPaused {
        require(msg.sender == _factory(),        "MS:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "MS:M:FAILED");
    }

    function setImplementation(address implementation_) external override whenProtocolNotPaused {
        require(msg.sender == _factory(), "MS:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override whenProtocolNotPaused {
        address poolDelegate_ = poolDelegate();

        require(msg.sender == poolDelegate_ || msg.sender == securityAdmin(), "MS:U:NOT_AUTHORIZED");

        IGlobalsLike mapleGlobals_ = IGlobalsLike(globals());

        if (msg.sender == poolDelegate_) {
            require(mapleGlobals_.isValidScheduledCall(msg.sender, address(this), "MS:UPGRADE", msg.data), "MS:U:INVALID_SCHED_CALL");

            mapleGlobals_.unscheduleCall(msg.sender, "MS:UPGRADE", msg.data);
        }

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function asset() public view override returns (address asset_) {
        asset_ = IPoolLike(pool).asset();
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

}
