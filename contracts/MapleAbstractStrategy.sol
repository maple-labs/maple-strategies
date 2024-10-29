// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { IMapleProxied }         from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import {
    IERC20Like,
    IGlobalsLike,
    IPoolLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

// TODO: Add NatSpec
enum StrategyState {
    Active,
    Impaired,
    Inactive
}

// @dev This is the base contract for all Maple strategies to inherit from.
abstract contract MapleAbstractStrategy is IMapleProxied, MapleProxiedInternals {

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyActive() {
        require(_strategyState() == StrategyState.Active, "MS:NOT_ACTIVE");

        _;
    }

    modifier nonReentrant() {
        require(_locked() == 1, "MS:LOCKED");

        _setLock(2);

        _;

        _setLock(1);
    }

    modifier whenProtocolNotPaused() {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "MS:PAUSED");
        _;
    }

    modifier onlyProtocolAdmins {
        require(
            msg.sender == poolDelegate() ||
            msg.sender == governor() ||
            msg.sender == IGlobalsLike(globals()).operationalAdmin(),
            "MS:NOT_ADMIN"
        );

        _;
    }

    modifier onlyStrategyManager {
        require(
            msg.sender == poolDelegate() ||
            IGlobalsLike(globals()).isInstanceOf("STRATEGY_MANAGER", msg.sender),
            "MS:NOT_MANAGER"
        );

        _;
    }

    /**************************************************************************************************************************************/
    /*** Proxy Functions                                                                                                                ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external whenProtocolNotPaused {
        require(msg.sender == _factory(),        "MS:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "MS:M:FAILED");
    }

    function setImplementation(address implementation_) external whenProtocolNotPaused {
        require(msg.sender == _factory(), "MS:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external whenProtocolNotPaused {
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
    /*** Virtual Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    function globals() public view virtual returns (address globals_);

    function governor() public view virtual returns (address governor_);

    function implementation() external view virtual returns (address implementation_);

    function poolDelegate() public view virtual returns (address poolDelegate_);

    function securityAdmin() public view virtual returns (address securityAdmin_);

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _setLock(uint256 lock_) internal virtual;

    function _locked() internal view virtual returns (uint256);

    function _strategyState() internal view virtual returns (StrategyState);

}
