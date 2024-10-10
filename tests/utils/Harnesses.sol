// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleBasicStrategy as MapleStrategy } from "../../contracts/MapleBasicStrategy.sol";

contract MapleStrategyHarness is MapleStrategy {

    function locked() external view returns (uint256) {
        return _locked;
    }

}
