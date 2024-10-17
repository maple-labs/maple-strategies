// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleSkyStrategyStorage } from "./IMapleSkyStrategyStorage.sol";

interface IMapleSkyStrategy is IMapleSkyStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   The strategy contract has exchanged `assets` for `shares` and are held by the strategy contract.
     *  @param assets     The amount of assets deposited.
     *  @param shares     The amount of shares minted for sUSDS.
     *  @param usdsAmount The total amount of USDS obtained from the PSM.
     */
    event StrategyFunded(uint256 assets, uint256 shares, uint256 usdsAmount);

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
     *  @dev    Returns the assets under management.
     *  @return assetsUnderManagement The assets under management.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement);

}
