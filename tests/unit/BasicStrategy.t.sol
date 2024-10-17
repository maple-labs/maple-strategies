// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Vm } from "../../modules/forge-std/src/Test.sol";

import { IERC20Like, IERC4626Like, IPoolManagerLike } from "../../contracts/interfaces/Interfaces.sol";

import { BasicStrategyTestBase }     from "../utils/TestBase.sol";
import { MapleBasicStrategyHarness } from "../utils/Harnesses.sol";

// TODO: Need to add AUM tests when fee logic added
contract MapleBasicStrategyViewFunctionTests is BasicStrategyTestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_asset() external view {
        assertEq(strategy.asset(), address(asset));
    }

    function test_factory() external view {
        assertEq(strategy.factory(), address(factory));
    }

    function test_globals() external view {
        assertEq(strategy.globals(), address(globals));
    }

    function test_governor() external view {
        assertEq(strategy.governor(), address(governor));
    }

    function test_implementation() external view {
        assertEq(strategy.implementation(), address(implementation));
    }

    function test_poolDelegate() external view {
        assertEq(strategy.poolDelegate(), address(poolDelegate));
    }

    function test_securityAdmin() external view {
        assertEq(strategy.securityAdmin(), address(securityAdmin));
    }

    function test_locked() external view {
        assertEq(strategy.locked(), 1);
    }

    function test_fundsAsset() external view {
        assertEq(strategy.fundsAsset(), address(asset));
    }

    function test_pool() external view {
        assertEq(strategy.pool(), address(pool));
    }

    function test_poolManager() external view {
        assertEq(strategy.poolManager(), address(poolManager));
    }

    function test_strategyVault() external view {
        assertEq(strategy.strategyVault(), address(vault));
    }

}

contract MapleBasicStrategyFundStrategyTests is BasicStrategyTestBase {

    event StrategyFunded(uint256 assets, uint256 shares);

    function setUp() public override {
        super.setUp();
    }

    function test_fund_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        MapleBasicStrategyHarness(address(strategy)).setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.fundStrategy(1e18);
    }

    function test_fund_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.fundStrategy(1e18);
    }

    function test_fund_failIfNotStrategyManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.fundStrategy(1e18);
    }

    function test_fund_failInvalidStrategyVault() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MBS:FS:INVALID_STRATEGY_VAULT");
        vm.prank(poolDelegate);
        strategy.fundStrategy(1e18);
    }

    function test_fund_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyFunded(1e18, 1e18);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), 1e18))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(vault), 1e18))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (1e18, address(strategy)))
        );


        vm.prank(poolDelegate);
        strategy.fundStrategy(1e18);
    }

    function test_fund_successWithStrategyManager() external {
        assertEq(globals.isInstanceOf("STRATEGY_MANAGER", strategyManager), true);

        vm.expectEmit();
        emit StrategyFunded(1e18, 1e18);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), 1e18))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(vault), 1e18))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (1e18, address(strategy)))
        );

        vm.prank(strategyManager);
        strategy.fundStrategy(1e18);
    }

}

contract MapleBasicStrategyWithdrawFromStrategyTests is BasicStrategyTestBase {

    event StrategyWithdrawal(uint256 assets, uint256 shares);

    function setUp() public override {
        super.setUp();
    }

    function test_withdrawFromStrategy_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        MapleBasicStrategyHarness(address(strategy)).setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.withdrawFromStrategy(1e18, false);
    }

    function test_withdrawFromStrategy_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.withdrawFromStrategy(1e18, false);
    }

    function test_withdrawFromStrategy_failIfNotStrategyManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.withdrawFromStrategy(1e18, false);
    }

    function test_withdrawFromStrategy_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyWithdrawal(1e18, 1e18);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (1e18, address(pool), address(strategy)))
        );

        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(1e18, false);
    }

    function test_withdrawFromStrategy_successWithStrategyManager() external {
        assertEq(globals.isInstanceOf("STRATEGY_MANAGER", strategyManager), true);

        vm.expectEmit();
        emit StrategyWithdrawal(1e18, 1e18);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (1e18, address(pool), address(strategy)))
        );

        vm.prank(strategyManager);
        strategy.withdrawFromStrategy(1e18, false);
    }

    function test_withdrawFromStrategy_successWithPoolDelegate_maximum() external {
        // Set Balance to mock increase in AUM
        vault.__setBalanceOf(address(strategy), 2e18);
        vault.__setExchangeRate(1);

        vm.expectEmit();
        emit StrategyWithdrawal(2e18, 2e18);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (2e18, address(pool), address(strategy)))
        );

        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(2e18, true);
    }

}

