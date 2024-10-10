// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleStrategyStorage {

    /**
     *  @dev    Returns the address of the pool contract.
     *  @return pool Address of the pool contract.
     */
    function pool() external view returns (address pool);

    /**
     *  @dev    Returns the address of the pool manager contract.
     *  @return poolManager Address of the pool manager contract.
     */
    function poolManager() external view returns (address poolManager);

}
