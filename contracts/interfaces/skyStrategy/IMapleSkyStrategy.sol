// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleSkyStrategyStorage } from "./IMapleSkyStrategyStorage.sol";

interface IMapleSkyStrategy is IMapleSkyStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

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
     *  @dev   The strategy contract has withdrawn shares for `assets` into the Pool.
     *  @param assets The amount of assets withdrawn.
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
     *  @dev    Sets the strategyFeeRate to the given fee rate.
     *  @param  strategyFeeRate_ The new strategy fee rate.
     */
    function setStrategyFeeRate(uint256 strategyFeeRate_) external;

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/
   
    /**
     *  @dev    Returns the total amount of assets under management.
     *  @return assetsUnderManagement Total amount of assets managed.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

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
