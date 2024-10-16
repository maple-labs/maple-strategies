// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleBasicStrategyStorage {

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return fundsAsset The address of the funds asset.
     */
    function fundsAsset() external view returns (address fundsAsset);

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

    /**
     *  @dev    Returns the address of the ERC4626 compliant Vault.
     *  @return strategyVault Address of the ERC4626 compliant Vault.
     */
    function strategyVault() external view returns (address strategyVault);

}
