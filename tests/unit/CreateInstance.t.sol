// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleBasicStrategy as MapleStrategy } from "../../contracts/MapleBasicStrategy.sol";
import { MapleStrategyFactory }                from "../../contracts/proxy/MapleStrategyFactory.sol";

import { MockVault } from "../utils/Mocks.sol";
import { TestBase }  from "../utils/TestBase.sol";

contract MapleBasicStrategyCreateInstanceTests is TestBase {

    event Initialized(address indexed pool_, address indexed poolManager_, address indexed vault_);

    function setUp() public override {
        super.setUp();

        vm.startPrank(governor);
        factory = new MapleStrategyFactory(address(globals));
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);

        globals.__setCanDeploy(true);
        vm.stopPrank();
    }

    function test_createInstance_invalidCaller() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault));

        globals.__setCanDeploy(false);

        vm.expectRevert("MSF:CI:CANNOT_DEPLOY");
        factory.createInstance(calldata_, "SALT");

        globals.__setCanDeploy(true);

        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_zeroPool() external {
        bytes memory calldata_ = abi.encode(address(0));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidFactory() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault));

        globals.__setIsInstanceOf(false);

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidInstance() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault));

        poolManagerFactory.__setIsInstance(false);

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidStrategyAsset() external {
        vault = new MockVault(address(0));

        bytes memory calldata_ = abi.encode(address(pool), address(vault));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_success() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault));

        vm.expectEmit();
        emit Initialized(address(pool), pm, address(vault));

        MapleStrategy strategy_ = MapleStrategy(factory.createInstance(calldata_, "SALT"));

        assertEq(strategy_.locked(), 1);

        assertEq(strategy_.fundsAsset(),    address(asset));
        assertEq(strategy_.pool(),          address(pool));
        assertEq(strategy_.poolManager(),   pm);
        assertEq(strategy_.strategyVault(), address(vault));
    }

}
