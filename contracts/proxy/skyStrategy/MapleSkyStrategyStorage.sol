// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { IMapleSkyStrategyStorage } from "../../interfaces/skyStrategy/IMapleSkyStrategyStorage.sol";

import { StrategyState } from "../../MapleAbstractStrategy.sol";

contract MapleSkyStrategyStorage is IMapleSkyStrategyStorage {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    uint256 public locked; // Used when checking for reentrancy.

    address public override fundsAsset;
    address public override pool;
    address public override poolManager;
    address public override psm;
    address public override savingsUsds;
    address public override usds;

    uint256 public override lastRecordedTotalAssets;
    uint256 public override strategyFeeRate;

    // TODO: Add view function that makes the current state more obvious.
    StrategyState public override strategyState;
    
}
