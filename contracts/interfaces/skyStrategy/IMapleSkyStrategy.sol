// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleSkyStrategyStorage } from "./IMapleSkyStrategyStorage.sol";

interface IMapleSkyStrategy is IMapleSkyStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Emitted when the strategy is deactivated.
     */
    event StrategyDeactivated();

    /**
     *  @dev   The fees earned by the Strategy for the Maple Protocol.
     *  @param feeAmount The amount of fees sent to the Maple Treasury.
     */
    event StrategyFeesCollected(uint256 feeAmount);

    /**
     *  @dev   The strategy contract has set the strategyFeeRate to `feeRate`.
     *  @param feeRate The strategy fee rate set.
     */
    event StrategyFeeRateSet(uint256 feeRate);

    /**
     *  @dev   The strategy contract has exchanged `assets` for `shares` and are held by the strategy contract.
     *  @param assets The amount of assets deposited.
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
     *  @dev   The strategy contract has withdrawn shares for `assets` into the Pool.
     *  @param assets The amount of assets withdrawn.
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
     *          Fee rates can only be set when the strategy is active.
     *  @param  feeRate Percentage of yield that accrues to the Maple treasury.
     */
    function setStrategyFeeRate(uint256 feeRate) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the current amount of assets under management.
     *  @return assetsUnderManagement Amount of assets managed by the strategy.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

    /**
     *  @dev    Returns the current amount of unrealized losses.
     *  @return unrealizedLosses Amount of assets marked as unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses);

}
