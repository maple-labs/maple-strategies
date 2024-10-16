// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleBasicStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   The strategy contract has exchanged `assets` for `shares` and are held by the strategy contract.
     *  @param assets The amount of assets deposited.
     *  @param shares The amount of shares minted.
     */
    event StrategyFunded(uint256 assets, uint256 shares);

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Funds the MapleStrategy with the given pool.
     *  @param assets Amount of the Pool assets to deploy into the strategy.
     */
    function fundStrategy(uint256 assets) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the amount of assets under the management of the Strategy.
     *  @return assetsUnderManagement The amount of assets under the management of the Strategy.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Returns the address of the underlying pool asset.
     *  @param asset Address of the underlying pool asset.
     */
    function asset() external view returns (address asset);

}
