// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleBasicStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   The fees earned by the Strategy for the Maple Protocol.
     *  @param feeAmount The amount of fees sent to the Maple Treasury.
     */
    event FeeWithdrawal(uint256 feeAmount);

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
     *  @dev   The strategy contract has withdrawn shares for `assets` into the Pool.
     *  @param assets The amount of assets withdrawn.
     */
    event StrategyWithdrawal(uint256 assets);

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Funds the MapleStrategy with the given pool.
     *  @param assets Amount of the Pool assets to deploy into the strategy.
     */
    function fundStrategy(uint256 assets) external;

    /**
     *  @dev    Withdraws the given amount of assets from the strategy.
     *  @param  assets Amount of assets to withdraw from the strategy.
     */
    function withdrawFromStrategy(uint256 assets) external;

    /**
     *  @dev    Sets the strategyFeeRate to the given fee rate.
     *          Adjust for 1e6 which is equal to 100.0000% (e.g 1500 = 0.15%)
     *  @param  strategyFeeRate_ The new strategy fee rate.
     */
    function setStrategyFeeRate(uint256 strategyFeeRate_) external;

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
