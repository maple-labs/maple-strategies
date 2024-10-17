// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { MapleStrategyFactory } from "../../contracts/proxy/MapleStrategyFactory.sol";
import { MapleBasicStrategy }   from "../../contracts/MapleBasicStrategy.sol";
import { MapleSkyStrategy }     from "../../contracts/MapleSkyStrategy.sol";

import { MockVault } from "../utils/Mocks.sol";
import { BasicStrategyTestBase }  from "../utils/TestBase.sol";
import { SkyStrategyTestBase }    from "../utils/TestBase.sol";

contract MapleBasicStrategyCreateInstanceTests is BasicStrategyTestBase {

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

        MapleBasicStrategy strategy_ = MapleBasicStrategy(factory.createInstance(calldata_, "SALT"));

        assertEq(strategy_.locked(), 1);

        assertEq(strategy_.fundsAsset(),    address(asset));
        assertEq(strategy_.pool(),          address(pool));
        assertEq(strategy_.poolManager(),   pm);
        assertEq(strategy_.strategyVault(), address(vault));
    }

}

contract MapleSkyStrategyCreateInstanceTests is SkyStrategyTestBase {

    event Initialized(
        address indexed pool,
        address indexed savingsUsds,
        address indexed psm,
        address poolManager,
        address usds
    );

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
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        globals.__setCanDeploy(false);

        vm.expectRevert("MSF:CI:CANNOT_DEPLOY");
        factory.createInstance(calldata_, "SALT");

        globals.__setCanDeploy(true);

        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_zeroPool() external {
        bytes memory calldata_ = abi.encode(address(0), address(vault), address(psm));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidFactory() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        globals.__setIsInstanceOf(false);

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidInstance() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        poolManagerFactory.__setIsInstance(false);

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidSavingsUsds() external {
        bytes memory calldata_ = abi.encode(address(pool), address(0), address(psm));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidPSM() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(0));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_nonAuthorizedPSM() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        globals.__setIsInstanceOf(false);

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidGemPSM() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        psm.__setGem(address(makeAddr("newGem")));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_invalidUsdsPSM() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        psm.__setUsds(address(makeAddr("newUsds")));

        vm.expectRevert("MPF:CI:FAILED");
        factory.createInstance(calldata_, "SALT");
    }

    function test_createInstance_success() external {
        bytes memory calldata_ = abi.encode(address(pool), address(vault), address(psm));

        vm.expectEmit();
        emit Initialized(address(pool), address(vault), address(psm), pm, address(usds));

        MapleSkyStrategy strategy_ = MapleSkyStrategy(factory.createInstance(calldata_, "SALT"));

        assertEq(strategy_.locked(), 1);

        assertEq(strategy_.pool(),        address(pool));
        assertEq(strategy_.poolManager(), pm);
        assertEq(strategy_.fundsAsset(),  address(asset));
        assertEq(strategy_.usds(),        address(usds));
        assertEq(strategy_.psm(),         address(psm));
    }

}
