// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { Sample } from "../contracts/Sample.sol";

contract SampleTest is Test {

    function test_sample() external {
        Sample sample = new Sample();
        assertTrue(sample.sample());
    }

}
