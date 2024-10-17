// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleAaveStrategyStorage } from "./IMapleAaveStrategyStorage.sol";

interface IMapleAaveStrategy is IMapleAaveStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when assets are deposited into the strategy.
     *  @param assets Amount of assets deposited.
     */
    event StrategyFunded(uint256 assets);

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Deploys assets from the Maple pool into the strategy.
     *  @param assets Amount of assets to deploy.
     */
    function fundStrategy(uint256 assets) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the total amount of assets under management.
     *  @return assetsUnderManagement Total amount of assets managed.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

}
