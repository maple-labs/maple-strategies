// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";
import { MockERC20 }                 from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleStrategyFactory }     from "../../contracts/proxy/MapleStrategyFactory.sol";
import { MapleStrategyInitializer } from "../../contracts/proxy/MapleStrategyInitializer.sol";

import { MapleStrategyHarness }                                from "./Harnesses.sol";
import { MockFactory, MockGlobals, MockPool, MockPoolManager } from "./Mocks.sol";

contract TestBase is Test {

    address internal governor         = makeAddr("governor");
    address internal lp               = makeAddr("lp");
    address internal operationalAdmin = makeAddr("operationalAdmin");
    address internal poolDelegate     = makeAddr("poolDelegate");
    address internal securityAdmin    = makeAddr("securityAdmin");

    address internal implementation;
    address internal initializer;
    address internal pm;

    MockERC20       internal asset;
    MockGlobals     internal globals;
    MockFactory     internal poolManagerFactory;
    MockPool        internal pool;
    MockPoolManager internal poolManager;

    MapleStrategyFactory internal factory;
    MapleStrategyHarness internal strategy;

    function setUp() public virtual {
        // Create all mocks.
        asset              = new MockERC20("Wrapped Ether", "WETH", 18);
        globals            = new MockGlobals(address(governor));
        pool               = new MockPool("Maple Pool", "MP-WETH", 18, address(asset), poolDelegate);
        poolManager        = new MockPoolManager(address(pool), poolDelegate, address(globals));
        poolManagerFactory = new MockFactory();

        pool.__setPoolManager(address(poolManager));

        poolManager.__setFactory(address(poolManagerFactory));

        poolManagerFactory.__setIsInstance(true);

        globals.__setCanDeploy(true);
        globals.__setIsInstanceOf(true);
        globals.__setOperationalAdmin(operationalAdmin);
        globals.__setSecurityAdmin(securityAdmin);

        implementation = address(new MapleStrategyHarness());
        initializer    = address(new MapleStrategyInitializer());

        vm.startPrank(governor);
        factory = new MapleStrategyFactory(address(globals));
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);
        vm.stopPrank();

        // Create the strategy manager instance.
        strategy = MapleStrategyHarness(factory.createInstance({
            arguments_: abi.encode(address(pool)),
            salt_:      "SALT"
        }));

        pm = address(poolManager);
    }

}
