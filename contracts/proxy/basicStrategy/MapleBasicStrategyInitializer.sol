// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { MapleProxiedInternals } from "../../../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleBasicStrategyInitializer } from "../../interfaces/basicStrategy/IMapleBasicStrategyInitializer.sol";

import { IGlobalsLike, IMapleProxyFactoryLike, IPoolLike, IPoolManagerLike } from "../../interfaces/Interfaces.sol";

import { MapleBasicStrategyStorage } from "./MapleBasicStrategyStorage.sol";

// TODO: Note each strategy will need its own config, need to think of the best way to manage this. 
contract MapleBasicStrategyInitializer is IMapleBasicStrategyInitializer, MapleBasicStrategyStorage, MapleProxiedInternals {

    fallback() external {
        ( address pool_ ) = abi.decode(msg.data, (address));

        _initialize(pool_);
    }

    function _initialize(address pool_) internal {
        require(pool_ != address(0), "MSI:ZERO_POOL");

        address globals_     = IMapleProxyFactoryLike(msg.sender).mapleGlobals();
        address poolManager_ = IPoolLike(pool_).manager();
        address factory_     = IPoolManagerLike(poolManager_).factory();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_MANAGER_FACTORY", factory_), "MSI:I:INVALID_PM_FACTORY");
        require(IMapleProxyFactoryLike(factory_).isInstance(poolManager_),             "MSI:I:INVALID_PM");

        locked = 1;

        pool        = pool_;
        poolManager = poolManager_;

        emit Initialized(pool_, poolManager_);
    }

}
