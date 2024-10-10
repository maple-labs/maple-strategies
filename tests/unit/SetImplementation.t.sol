// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleBasicStrategy as MapleStrategy } from "../../contracts/MapleBasicStrategy.sol";

import { TestBase } from "../utils/TestBase.sol";

contract SetImplementationTests is TestBase {

    address internal newImplementation;

    function setUp() public override {
        super.setUp();

        newImplementation = address(new MapleStrategy());
    }

    function test_setImplementation_protocolPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.setImplementation(newImplementation);
    }

    function test_setImplementation_notFactory() external {
        vm.expectRevert("MS:SI:NOT_FACTORY");
        strategy.setImplementation(newImplementation);
    }

    function test_setImplementation_success() external {
        assertEq(strategy.implementation(), implementation);

        vm.prank(strategy.factory());
        strategy.setImplementation(newImplementation);

        assertEq(strategy.implementation(), newImplementation);
    }

}
