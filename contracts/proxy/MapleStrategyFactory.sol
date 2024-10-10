// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { MapleProxyFactory } from "../../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

import { IGlobalsLike } from "../interfaces/Interfaces.sol";

contract MapleStrategyFactory is MapleProxyFactory {

    constructor(address globals_) MapleProxyFactory(globals_) {}

    function createInstance(
        bytes calldata arguments_,
        bytes32 salt_
    )
        public override(MapleProxyFactory) returns (address instance_)
    {
        require(IGlobalsLike(mapleGlobals).canDeploy(msg.sender), "MSF:CI:CANNOT_DEPLOY");

        isInstance[instance_ = super.createInstance(arguments_, salt_)] = true;
    }

}
