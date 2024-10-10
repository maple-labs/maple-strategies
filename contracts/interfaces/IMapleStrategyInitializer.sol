// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleStrategyInitializer {

    /**
     *  @dev               Emitted when the proxy contract is initialized.
     *  @param pool        Address of the pool contract.
     *  @param poolManager Address of the pool manager contract.
     */
    event Initialized(address indexed pool, address indexed poolManager);

}
