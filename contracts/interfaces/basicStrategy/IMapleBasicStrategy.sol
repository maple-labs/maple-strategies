// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleStrategy } from "../IMapleStrategy.sol";

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleStrategy, IMapleBasicStrategyStorage {

    /**************************************************************************************************************************************/
    /*** Strategy Manager Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Deploys assets from the Maple pool into the strategy.
     *         Funding can only be attempted when the strategy is active.
     *  @param assetsIn     Amount of assets to deploy.
     *  @param minSharesOut Minimum amount of shares to mint.
     */
    function fundStrategy(uint256 assetsIn, uint256 minSharesOut) external;

}
