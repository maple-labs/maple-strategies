// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Vm } from "../../modules/forge-std/src/Test.sol";

import { IMapleAaveStrategy } from "../../contracts/interfaces/aaveStrategy/IMapleAaveStrategy.sol";

import {
    IAavePoolLike,
    IAaveTokenLike,
    IERC20Like,
    IGlobalsLike,
    IPoolManagerLike
} from "../../contracts/interfaces/Interfaces.sol";

import { MapleAaveStrategyHarness } from "../utils/Harnesses.sol";
import { AaveStrategyTestBase }     from "../utils/TestBase.sol";

contract MapleAaveStrategyViewFunctionTests is AaveStrategyTestBase {

    function test_aavePool() external view {
        assertEq(strategy.aavePool(), address(aavePool));
    }

    function test_aaveToken() external view {
        assertEq(strategy.aaveToken(), address(aaveToken));
    }

    function test_factory() external view {
        assertEq(strategy.factory(), address(factory));
    }

    function test_fundsAsset() external view {
        assertEq(strategy.fundsAsset(), address(asset));
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

    function test_locked() external view {
        assertEq(strategy.locked(), 1);
    }

    function test_poolDelegate() external view {
        assertEq(strategy.poolDelegate(), address(poolDelegate));
    }

    function test_securityAdmin() external view {
        assertEq(strategy.securityAdmin(), address(securityAdmin));
    }

    function test_pool() external view {
        assertEq(strategy.pool(), address(pool));
    }

    function test_poolManager() external view {
        assertEq(strategy.poolManager(), address(poolManager));
    }

}

contract MapleAaveStrategyFundStrategyTests is AaveStrategyTestBase {

    event StrategyFunded(uint256 assets);

    uint256 assets = 1e18;

    function setUp() public override {
        super.setUp();
    }

    function test_fund_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleAaveStrategyHarness()).code);

        MapleAaveStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.fundStrategy(assets);
    }

    function test_fund_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.fundStrategy(assets);
    }

    function test_fund_failIfNonManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.fundStrategy(assets);
    }

    function test_fund_failIfInvalidAavePool() external {
        globals.__setIsInstanceOf(false);

        vm.prank(poolDelegate);
        vm.expectRevert("MAS:FS:INVALID_AAVE_POOL");
        strategy.fundStrategy(assets);
    }

    function test_fundStrategy_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyFunded(assets);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), assets))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(aavePool), assets))
        );

        vm.expectCall(
            address(aavePool),
            abi.encodeCall(IAavePoolLike.supply, (address(asset), assets, address(strategy), 0))
        );

        vm.prank(poolDelegate);
        strategy.fundStrategy(assets);
    }

    function test_fundStrategy_successWithStrategyManager() external {
        vm.expectEmit();
        emit StrategyFunded(assets);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), assets))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(aavePool), assets))
        );

        vm.expectCall(
            address(aavePool),
            abi.encodeCall(IAavePoolLike.supply, (address(asset), assets, address(strategy), 0))
        );

        vm.prank(strategyManager);
        strategy.fundStrategy(assets);
    }

}

contract MapleAaveStrategyWithdrawFromStrategyTests is AaveStrategyTestBase {

    event StrategyWithdrawal(uint256 assets);

    uint256 assets = 1e18;

    function setUp() public override {
        super.setUp();

        aaveToken.__setBalanceOf(address(strategy), assets);
    }

    function test_withdrawFromStrategy_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleAaveStrategyHarness()).code);

        MapleAaveStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failIfNonManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failIfLowAssets() external {
        vm.prank(poolDelegate);
        vm.expectRevert("MAS:WFS:LOW_ASSETS");
        strategy.withdrawFromStrategy(assets + 1);
    }

    function test_withdrawFromStrategy_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleAaveStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(aaveToken),
            abi.encodeCall(IAaveTokenLike.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(aavePool),
            abi.encodeCall(IAavePoolLike.withdraw, (address(asset), assets, address(pool)))
        );

        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_successWithStrategyManager() external {
        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleAaveStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isInstanceOf, ("STRATEGY_MANAGER", strategyManager))
        );

        vm.expectCall(
            address(aaveToken),
            abi.encodeCall(IAaveTokenLike.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(aavePool),
            abi.encodeCall(IAavePoolLike.withdraw, (address(asset), assets, address(pool)))
        );

        vm.prank(strategyManager);
        strategy.withdrawFromStrategy(assets);
    }

}
