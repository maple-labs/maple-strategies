// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleBasicStrategyStorage {

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
     *  @dev   Funds the MapleStrategy with the given pool.
     *         Funding can be attempted if the strategy is active.
     *  @param assetsIn Amount of the Pool assets to deploy into the strategy.
     */
    function fundStrategy(uint256 assetsIn) external;

    /**
     *  @dev    Withdraws the given amount of assets from the strategy.
     *          Withdrawals can be attempted even if the strategy is impaired or inactive.
     *  @param  assetsOut Amount of assets to withdraw from the strategy.
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
     *  @dev    Sets the strategyFeeRate to the given fee rate.
     *          Adjust for 1e6 which is equal to 100.0000% (e.g 1500 = 0.15%)
     *          The Strategy Fee can only be set when the strategy is active.
     *  @param  strategyFeeRate The new strategy fee rate.
     */
    function setStrategyFeeRate(uint256 strategyFeeRate) external;

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

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Returns the address of the underlying pool asset.
     *  @param asset Address of the underlying pool asset.
     */
    function asset() external view returns (address asset);

    /**
     *  @dev    Returns the value considered as the hundred percent.
     *  @return hundredPercent_ The value considered as the hundred percent.
     */
    function HUNDRED_PERCENT() external returns (uint256 hundredPercent_);

    /**
     *  @dev    Return the address of the Maple Treasury.
     *  @return treasury The Maple Treasury Address.
     */
    function treasury() external view returns (address treasury);

}
