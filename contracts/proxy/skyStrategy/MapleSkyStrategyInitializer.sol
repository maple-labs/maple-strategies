// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { MapleProxiedInternals } from "../../../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import {
    IERC4626Like,
    IGlobalsLike,
    IMapleProxyFactoryLike,
    IPoolLike,
    IPoolManagerLike,
    IPSMLike
} from "../../interfaces/Interfaces.sol";

import { IMapleSkyStrategyInitializer } from "../../interfaces/skyStrategy/IMapleSkyStrategyInitializer.sol";

import { MapleSkyStrategyStorage } from "./MapleSkyStrategyStorage.sol";

contract MapleSkyStrategyInitializer is IMapleSkyStrategyInitializer, MapleSkyStrategyStorage, MapleProxiedInternals {

    fallback() external {
        ( address pool_, address savingsUsds_, address psm_ ) = abi.decode(msg.data, (address, address, address));

        _initialize(pool_, savingsUsds_, psm_);
    }

    function _initialize(address pool_, address savingsUsds_, address psm_) internal {
        require(pool_ != address(0),        "MSSI:I:ZERO_POOL");
        require(savingsUsds_ != address(0), "MSSI:I:ZERO_SAVINGS_USDS");
        require(psm_ != address(0),         "MSSI:I:ZERO_PSM");

        address globals_     = IMapleProxyFactoryLike(msg.sender).mapleGlobals();
        address poolManager_ = IPoolLike(pool_).manager();
        address factory_     = IPoolManagerLike(poolManager_).factory();
        address fundsAsset_  = IPoolLike(pool_).asset();
        address usds_        = IERC4626Like(savingsUsds_).asset();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_MANAGER_FACTORY", factory_), "MSSI:I:INVALID_PM_FACTORY");
        require(IMapleProxyFactoryLike(factory_).isInstance(poolManager_),             "MSSI:I:INVALID_PM");

        require(IGlobalsLike(globals_).isInstanceOf("STRATEGY_VAULT", savingsUsds_), "MSSI:I:INVALID_STRATEGY_VAULT");
        require(IGlobalsLike(globals_).isInstanceOf("PSM", psm_),                    "MSSI:I:INVALID_PSM");
        require(IPSMLike(psm_).gem() == fundsAsset_,                                 "MSSI:I:INVALID_GEM_PSM");
        require(IPSMLike(psm_).usds() == usds_,                                      "MSSI:I:INVALID_USDS_PSM");

        locked = 1;

        pool        = pool_;
        poolManager = poolManager_;
        savingsUsds = savingsUsds_;
        psm         = psm_;
        usds        = usds_;
        fundsAsset  = fundsAsset_;

        emit Initialized(pool_, savingsUsds_, psm_, poolManager_, usds_);
    }

}
