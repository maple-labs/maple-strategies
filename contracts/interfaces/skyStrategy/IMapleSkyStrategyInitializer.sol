// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleSkyStrategyInitializer {

    /**
     *  @dev               Emitted when the proxy contract is initialized.
     *  @param pool        Address of the pool contract.
     *  @param poolManager Address of the pool manager contract.
     *  @param savingsUsds Address of the savings usds contract.
     *  @param psm         Address of the psm contract.
     *  @param usds        Address of the usds contract.
     *  @dev               Only 3 parameters can be indexed.
     */
    event Initialized(
        address indexed pool,
        address indexed savingsUsds,
        address indexed psm,
        address poolManager,
        address usds
    );

}
