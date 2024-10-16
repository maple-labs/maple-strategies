// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleBasicStrategy as MapleStrategy } from "../../contracts/MapleBasicStrategy.sol";

import { MockGlobals, MockStrategiesMigrator } from "../utils/Mocks.sol";
import { TestBase }                            from "../utils/TestBase.sol";

contract MapleBasicStrategyUpgradeTests is TestBase {

    address internal migrator;
    address internal newImplementation;

    function setUp() public override {
        super.setUp();

        migrator          = address(new MockStrategiesMigrator());
        newImplementation = address(new MapleStrategy());

        vm.startPrank(governor);
        factory.registerImplementation(2, newImplementation, initializer);
        factory.enableUpgradePath(1, 2, migrator);
        vm.stopPrank();
    }

    function test_upgrade_protocolPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.upgrade(2, abi.encode(address(0)));
    }

    function test_upgrade_notSecurityAdmin() external {
        vm.expectRevert("MS:U:NOT_AUTHORIZED");
        strategy.upgrade(2, "");

        vm.prank(securityAdmin);
        strategy.upgrade(2, abi.encode(address(0)));
    }

    function test_upgrade_notPoolDelegate() external {
        vm.expectRevert("MS:U:NOT_AUTHORIZED");
        strategy.upgrade(2, "");

        MockGlobals(globals).__setIsValidScheduledCall(true);

        vm.prank(poolDelegate);
        strategy.upgrade(2, abi.encode(address(0)));
    }

    function test_upgrade_notScheduled() external {
        vm.prank(poolDelegate);
        vm.expectRevert("MS:U:INVALID_SCHED_CALL");
        strategy.upgrade(2, "");
    }

    function test_upgrade_upgradeFailed() external {
        MockGlobals(globals).__setIsValidScheduledCall(true);

        vm.prank(poolDelegate);
        vm.expectRevert("MPF:UI:FAILED");
        strategy.upgrade(2, "1");
    }

    function test_upgrade_success() external {
        assertEq(strategy.implementation(), implementation);

        MockGlobals(globals).__setIsValidScheduledCall(true);

        vm.prank(poolDelegate);
        strategy.upgrade(2, abi.encode(address(0)));

        assertEq(strategy.implementation(), newImplementation);
    }

}
