// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleAaveStrategyStorage {

    /**
     *  @dev    Returns the address of the Aave pool.
     *  @return aavePool Address of the Aave pool.
     */
    function aavePool() external view returns (address aavePool);

    /**
     *  @dev    Returns the address of the Aave token.
     *  @return aaveToken Address of the Aave token.
     */
    function aaveToken() external view returns (address aaveToken);

    /**
     *  @dev    Returns the address of the underlying asset.
     *  @return fundsAsset Address of the underlying asset.
     */
    function fundsAsset() external view returns (address fundsAsset);

    /**
     *  @dev    Returns the address of the underlying asset.
     *  @return pool Address of the Maple pool.
     */
    function pool() external view returns (address pool);

    /**
     *  @dev    Returns the address of the Maple pool manager.
     *  @return poolManager Address of the Maple pool manager.
     */
    function poolManager() external view returns (address poolManager);

}
