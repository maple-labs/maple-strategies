// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleBasicStrategy } from "../../contracts/MapleBasicStrategy.sol";
import { MapleSkyStrategy }   from "../../contracts/MapleSkyStrategy.sol";

contract MapleBasicStrategyHarness is MapleBasicStrategy {

    function setLocked(uint256 locked_) external {
        locked = locked_;
    }

}

contract MapleSkyStrategyHarness is MapleSkyStrategy {

    function setLocked(uint256 locked_) external {
        locked = locked_;
    }

}
