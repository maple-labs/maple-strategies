// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleAaveStrategyStorage } from "./IMapleAaveStrategyStorage.sol";

interface IMapleAaveStrategy is IMapleAaveStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when the yield fees of the strategy are collected.
     *  @param fees Amount of assets collected by the treasury.
     */
    event StrategyFeesCollected(uint256 fees);

    /**
     *  @dev   Emitted when the fee rate of the strategy is updated.
     *  @param feeRate Percentage of yield that accrues to the treasury.
     */
    event StrategyFeeRateSet(uint256 feeRate);

    /**
     *  @dev   Emitted when assets are deposited into the strategy.
     *  @param assets Amount of assets deposited.
     */
    event StrategyFunded(uint256 assets);

    /**
     *  @dev   Emitted when assets are withdrawn from the strategy.
     *  @param assets Amount of assets withdrawn.
     */
    event StrategyWithdrawal(uint256 assets);

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Deploys assets from the Maple pool into the strategy.
     *  @param assets Amount of assets to deploy.
     */
    function fundStrategy(uint256 assets) external;

    /**
     *  @dev   Withdraw assets from the strategy back into the Maple pool.
     *  @param assets Amount of assets to withdraw.
     */
    function withdrawFromStrategy(uint256 assets) external;

    /**
     *  @dev   Updates the fee rate of the strategy.
     *  @param feeRate Percentage of yield that accrues to the Maple treasury.
     */
    function setStrategyFeeRate(uint256 feeRate) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the total amount of assets under management.
     *  @return assetsUnderManagement Total amount of assets managed.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

}
