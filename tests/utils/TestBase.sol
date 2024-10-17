// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";
import { MockERC20 }                 from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleStrategyFactory } from "../../contracts/proxy/MapleStrategyFactory.sol";

import { MapleAaveStrategyInitializer }  from "../../contracts/proxy/aaveStrategy/MapleAaveStrategyInitializer.sol";
import { MapleBasicStrategyInitializer } from "../../contracts/proxy/basicStrategy/MapleBasicStrategyInitializer.sol";
import { MapleSkyStrategyInitializer }   from "../../contracts/proxy/skyStrategy/MapleSkyStrategyInitializer.sol";

import { MapleAaveStrategy }  from "../../contracts/MapleAaveStrategy.sol";
import { MapleBasicStrategy } from "../../contracts/MapleBasicStrategy.sol";
import { MapleSkyStrategy }   from "../../contracts/MapleSkyStrategy.sol";

import {
    MockAavePool,
    MockAaveToken,
    MockFactory,
    MockGlobals,
    MockPool,
    MockPoolManager,
    MockPSM,
    MockVault
} from "./Mocks.sol";

contract TestBase is Test {

    address internal governor         = makeAddr("governor");
    address internal lp               = makeAddr("lp");
    address internal operationalAdmin = makeAddr("operationalAdmin");
    address internal poolDelegate     = makeAddr("poolDelegate");
    address internal securityAdmin    = makeAddr("securityAdmin");
    address internal strategyManager  = makeAddr("strategyManager");

    address internal implementation;
    address internal initializer;

    MockERC20       internal asset;
    MockGlobals     internal globals;
    MockFactory     internal poolManagerFactory;
    MockPool        internal pool;
    MockPoolManager internal poolManager;

    MapleStrategyFactory internal factory;

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

        factory = new MapleStrategyFactory(address(globals));
    }

}

contract BasicStrategyTestBase is TestBase {

    MapleBasicStrategy internal strategy;
    MockVault          internal vault;

    function setUp() public virtual override {
        super.setUp();

        implementation = address(new MapleBasicStrategy());
        initializer    = address(new MapleBasicStrategyInitializer());

        vm.startPrank(governor);
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);
        vm.stopPrank();

        vault = new MockVault(address(asset));

        // Create the strategy instance.
        strategy = MapleBasicStrategy(factory.createInstance({
            arguments_: abi.encode(address(pool), address(vault)),
            salt_:      "SALT"
        }));

    }

}

contract SkyStrategyTestBase is TestBase {

    event StrategyFunded(uint256 assets, uint256 shares, uint256 usdsAmount);

    MapleSkyStrategy  strategy;
    MockPSM           psm;
    MockVault         vault;
    MockERC20         usds;

    function setUp() public virtual override {
        super.setUp();

        implementation = address(new MapleSkyStrategy());
        initializer    = address(new MapleSkyStrategyInitializer());

        vm.startPrank(governor);
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);
        vm.stopPrank();

        psm   = new MockPSM();
        usds  = new MockERC20("usds", "USDS", 18);
        vault = new MockVault(address(usds));

        psm.__setUsds(address(usds));
        psm.__setGem(address(asset));

        //Create the strategy instance.
        strategy = MapleSkyStrategy(factory.createInstance({
            arguments_: abi.encode(address(pool), address(vault), address(psm)),
            salt_:      "SALT"
        }));
    }

}

contract AaveStrategyTestBase is TestBase {

    MockAavePool   aavePool;
    MockAaveToken  aaveToken;

    MapleAaveStrategy strategy;

    function setUp() public virtual override {
        super.setUp();

        implementation = address(new MapleAaveStrategy());
        initializer    = address(new MapleAaveStrategyInitializer());

        aavePool  = new MockAavePool();
        aaveToken = new MockAaveToken(address(aavePool), address(asset));

        vm.startPrank(governor);
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);
        vm.stopPrank();

        // Create the strategy instance.
        strategy = MapleAaveStrategy(factory.createInstance({
            arguments_: abi.encode(address(pool), address(aaveToken)),
            salt_:      "SALT"
        }));
    }

}
