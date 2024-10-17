// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMapleSkyStrategyStorage {

    /**
     *  @dev    Returns the address of the underlying asset.
     *  @return fundsAsset Address of the underlying asset.
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
     *  @dev    Returns the address of the PSM contract.
     *  @return psm Address of the PSM contract.
     */
    function psm() external view returns (address psm);

    /**
     *  @dev    Returns the address of the savings USDS contract.
     *  @return savingsUsds Address of the savings USDS contract.
     */
    function savingsUsds() external view returns (address savingsUsds);

    /**
     *  @dev    Returns the address of the USDS contract.
     *  @return usds Address of the USDS contract.
     */
    function usds() external view returns (address usds);

}
