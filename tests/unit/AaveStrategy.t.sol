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

import { AaveStrategyTestBase } from "../utils/TestBase.sol";

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

    function test_pool() external view {
        assertEq(strategy.pool(), address(pool));
    }

    function test_poolManager() external view {
        assertEq(strategy.poolManager(), address(poolManager));
    }

    function test_securityAdmin() external view {
        assertEq(strategy.securityAdmin(), address(securityAdmin));
    }

    function test_treasury() external view {
        assertEq(strategy.treasury(), address(treasury));
    }

}

contract MapleAaveStrategyAssetsUnderManagementTests is AaveStrategyTestBase {

    function testFuzz_assetsUnderManagement(
        uint256 currentTotalAssets,
        uint256 lastRecordedTotalAssets,
        uint256 strategyFeeRate
    ) external {
        currentTotalAssets      = bound(currentTotalAssets,      0, 1e30);
        lastRecordedTotalAssets = bound(lastRecordedTotalAssets, 0, 1e30);
        strategyFeeRate         = bound(strategyFeeRate,         0, 1e6);

        aaveToken.__setCurrentTotalAssets(currentTotalAssets);
        strategy.__setLastRecordedTotalAssets(lastRecordedTotalAssets);
        strategy.__setStrategyFeeRate(strategyFeeRate);

        uint256 AUM = currentTotalAssets;

        if (currentTotalAssets > lastRecordedTotalAssets) {
            AUM -= (currentTotalAssets - lastRecordedTotalAssets) * strategyFeeRate / 1e6;
        }

        assertEq(strategy.assetsUnderManagement(), AUM);
    }

}

contract MapleAaveStrategyFundStrategyTests is AaveStrategyTestBase {

    uint256 assets = 1e18;

    function setUp() public override {
        super.setUp();
    }

    function test_fund_failReentrancy() external {
        strategy.__setLocked(2);

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
        vm.expectRevert("MAS:FS:INVALID_AAVE_TOKEN");
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

    uint256 assets = 1e18;

    function setUp() public override {
        super.setUp();

        aaveToken.__setCurrentTotalAssets(assets);
    }

    function test_withdrawFromStrategy_failReentrancy() external {
        strategy.__setLocked(2);

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

contract MapleAaveStrategySetStrategyFeeRateTests is AaveStrategyTestBase {

    uint256 balance    = 8_500_000e6;
    uint256 gain       = 16_301e6;
    uint256 loss       = 14_125e6;
    uint256 newFeeRate = 420;
    uint256 oldFeeRate = 1337;

    function test_setStrategyFeeRate_failReentrancy() external {
        strategy.__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_failWhenNotAdmin() external {
        vm.expectRevert("MS:NOT_ADMIN");
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_failWhenInvalidStrategyFeeRate() external {
        vm.expectRevert("MAS:SSFR:INVALID_FEE_RATE");
        vm.prank(poolDelegate);
        strategy.setStrategyFeeRate(1e6 + 1);
    }

    function test_setStrategyFeeRate_successWithPoolDelegate() external {
        vm.prank(poolDelegate);
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_successWithGovernor() external {
        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_successWithOperationalAdmin() external {
        vm.prank(operationalAdmin);
        strategy.setStrategyFeeRate(newFeeRate);
    }

    function test_setStrategyFeeRate_unfundedStrategy_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(0);
        strategy.__setStrategyFeeRate(0);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), 0);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_unfundedStrategy_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(0);
        strategy.__setStrategyFeeRate(oldFeeRate);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), 0);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_normalGain_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), balance + gain);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_normalGain_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(oldFeeRate);

        vm.expectEmit();
        emit StrategyFeesCollected(gain * oldFeeRate / 1e6);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), balance + gain * (1e6 - oldFeeRate) / 1e6);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_normalGain_1e6() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(1e6);

        vm.expectEmit();
        emit StrategyFeesCollected(gain);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), balance);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_normalLoss_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - loss);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), balance - loss);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_normalLoss_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - loss);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(oldFeeRate);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), balance - loss);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_totalLoss_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), 0);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

    function test_setStrategyFeeRate_totalLoss_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.expectEmit();
        emit StrategyFeeRateSet(newFeeRate);

        vm.prank(governor);
        strategy.setStrategyFeeRate(newFeeRate);

        assertEq(strategy.lastRecordedTotalAssets(), 0);
        assertEq(strategy.strategyFeeRate(),         newFeeRate);
    }

}

contract MapleAaveStrategyAccrueFeesTests is AaveStrategyTestBase {

    uint256 balance = 8_500_000e6;
    uint256 feeRate = 1337;
    uint256 gain    = 16_301e6;
    uint256 loss    = 14_125e6;

    function test_accrueFees_unfundedStrategy_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(0);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_unfundedStrategy_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(0);
        strategy.__setStrategyFeeRate(feeRate);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_minimumGain_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + 1);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance + 1);
    }

    function test_accrueFees_minimumGain_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + 1);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(feeRate);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance + 1);
    }

    function test_accrueFees_normalGain_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance + gain);
    }

    function test_accrueFees_normalGain_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(feeRate);

        vm.expectEmit();
        emit StrategyFeesCollected(gain * feeRate / 1e6);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance + gain * (1e6 - feeRate) / 1e6);
    }

    function test_accrueFees_normalGain_minimumFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(1);

        vm.expectEmit();
        emit StrategyFeesCollected(gain / 1e6);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance + gain * (1e6 - 1) / 1e6);
    }

    function test_accrueFees_normalGain_maximumFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance + gain);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(1e6);

        vm.expectEmit();
        emit StrategyFeesCollected(gain);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance);
    }

    function test_accrueFees_minimumLoss_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - 1);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance - 1);
    }

    function test_accrueFees_minimumLoss_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - 1);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(feeRate);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance - 1);
    }

    function test_accrueFees_normalLoss_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - loss);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance - loss);
    }

    function test_accrueFees_normalLoss_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(balance - loss);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(feeRate);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), balance - loss);
    }

    function test_accrueFees_totalLoss_zeroFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(0);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_totalLoss_realisticFeeRate() external {
        aaveToken.__setCurrentTotalAssets(0);
        strategy.__setLastRecordedTotalAssets(balance);
        strategy.__setStrategyFeeRate(feeRate);

        vm.prank(governor);
        strategy.__accrueFees(address(aavePool), address(aaveToken), address(asset));

        assertEq(strategy.lastRecordedTotalAssets(), 0);
    }

}
