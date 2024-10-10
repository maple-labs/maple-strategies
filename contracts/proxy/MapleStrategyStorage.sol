// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import { IMapleStrategyStorage } from "../interfaces/IMapleStrategyStorage.sol";

contract MapleStrategyStorage is IMapleStrategyStorage {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    uint256 internal _locked;  // Used when checking for reentrancy.

    address public override pool;
    address public override poolManager;

}
