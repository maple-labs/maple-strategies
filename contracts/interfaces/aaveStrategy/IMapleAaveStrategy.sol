// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleAaveStrategyStorage } from "./IMapleAaveStrategyStorage.sol";

interface IMapleAaveStrategy is IMapleAaveStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Emitted when the strategy is deactivated.
     */
    event StrategyDeactivated();

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
     *  @dev Emitted when the strategy is impaired.
     */
    event StrategyImpaired();

    /**
     *  @dev Emitted when the strategy is reactivated.
     */
    event StrategyReactivated();

    /**
     *  @dev   Emitted when assets are withdrawn from the strategy.
     *  @param assets Amount of assets withdrawn.
     */
    event StrategyWithdrawal(uint256 assets);

    /**************************************************************************************************************************************/
    /*** Strategy Manager Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Deploys assets from the Maple pool into the strategy.
     *         Funding can only be performed when the strategy is active.
     *  @param assetsIn Amount of assets to deploy.
     */
    function fundStrategy(uint256 assetsIn) external;

    /**
     *  @dev   Withdraw assets from the strategy back into the Maple pool.
     *         Withdrawals can be attempted even if the strategy is impaired or inactive.
     *  @param assetsOut Amount of assets to withdraw.
     */
    function withdrawFromStrategy(uint256 assetsOut) external;

    /**************************************************************************************************************************************/
    /*** Strategy Admin Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Disables funding and marks all assets under management as zero.
     */
    function deactivateStrategy() external;

    /**
     *  @dev Disables funding and marks all assets under management as unrealized losses.
     */
    function impairStrategy() external;

    /**
     *  @dev   Resumes normal operation of the strategy.
     *  @param updateAccounting Flag that defines if fee accounting should be refreshed.
     */
    function reactivateStrategy(bool updateAccounting) external;

    /**
     *  @dev    Sets a new fee rate for the strategy.
     *          Adjust for 1e6 which is equal to 100.0000% (e.g 1500 = 0.15%)
     *          The Strategy Fee can only be set when the strategy is active.
     *  @param  feeRate Percentage of yield that accrues to the Maple treasury.
     */
    function setStrategyFeeRate(uint256 feeRate) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the amount of assets under the management of the Strategy.
     *  @return assetsUnderManagement The amount of assets under the management of the Strategy.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

        /**
     *  @dev    Returns the current amount of unrealized losses.
     *  @return unrealizedLosses Amount of assets marked as unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses);

}
