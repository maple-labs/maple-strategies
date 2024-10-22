// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Vm } from "../../modules/forge-std/src/Test.sol";

import { IMapleBasicStrategy } from "../../contracts/interfaces/basicStrategy/IMapleBasicStrategy.sol";

import {
    IERC20Like,
    IERC4626Like,
    IGlobalsLike,
    IPoolManagerLike
} from "../../contracts/interfaces/Interfaces.sol";

import { BasicStrategyTestBase }     from "../utils/TestBase.sol";
import { MapleBasicStrategyHarness } from "../utils/Harnesses.sol";

contract MapleBasicStrategyViewFunctionTests is BasicStrategyTestBase {

    MapleBasicStrategyHarness basicStrategy;

    function setUp() public override {
        super.setUp();
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        basicStrategy = MapleBasicStrategyHarness(address(strategy));
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

    function test_treasury() external view {
        assertEq(strategy.treasury(), treasury);
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

    function test_assetsUnderManagement_strategyNotFunded() external view {
        assertEq(basicStrategy.assetsUnderManagement(), 0);
    }

    function test_assetsUnderManagement_strategyFundedAndZeroFee() external {
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
        assertEq(basicStrategy.strategyFeeRate(),         0);

        vault.__setBalanceOf(address(basicStrategy), 1e6);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e6))
        );

        assertEq(basicStrategy.assetsUnderManagement(), 1e6);
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndLoss() external {
        basicStrategy.__setLastRecordedTotalAssets(2e6);
        basicStrategy.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(basicStrategy.lastRecordedTotalAssets(), 2e6);
        assertEq(basicStrategy.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(basicStrategy), 1e6);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e6))
        );

        assertEq(basicStrategy.assetsUnderManagement(), 1e6);
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndTotalAssetsIncreased() external {
        basicStrategy.__setLastRecordedTotalAssets(2e6);
        basicStrategy.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(basicStrategy.lastRecordedTotalAssets(), 2e6);
        assertEq(basicStrategy.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(basicStrategy), 5e6);
        vault.__setExchangeRate(1);

        uint256 strategyFee = ((5e6 - 2e6) * 1500) / 1e6;

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (5e6))
        );

        assertEq(basicStrategy.assetsUnderManagement(), 5e6 - strategyFee);
    }

}

contract MapleBasicStrategyFundStrategyTests is BasicStrategyTestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_fund_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        MapleBasicStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.fundStrategy(1e6);
    }

    function test_fund_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.fundStrategy(1e6);
    }

    function test_fund_failIfNotStrategyManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.fundStrategy(1e6);
    }

    function test_fund_failInvalidStrategyVault() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MBS:FS:INVALID_STRATEGY_VAULT");
        vm.prank(poolDelegate);
        strategy.fundStrategy(1e6);
    }

    function test_fund_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyFunded(1e6);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), 1e6))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(vault), 1e6))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (1e6, address(strategy)))
        );


        vm.prank(poolDelegate);
        strategy.fundStrategy(1e6);
    }

    function test_fund_successWithStrategyManager() external {
        assertEq(globals.isInstanceOf("STRATEGY_MANAGER", strategyManager), true);

        vm.expectEmit();
        emit StrategyFunded(1e6);

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), 1e6))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(vault), 1e6))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (1e6, address(strategy)))
        );

        vm.prank(strategyManager);
        strategy.fundStrategy(1e6);
    }

}

contract MapleBasicStrategyWithdrawFromStrategyTests is BasicStrategyTestBase {

    uint256 assets = 1e6;

    function setUp() public override {
        super.setUp();

        vault.__setBalanceOf(address(strategy), assets);
        vault.__setExchangeRate(1);
    }

    function test_withdrawFromStrategy_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        MapleBasicStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failIfNotStrategyManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failLowAssets() external {
        vm.expectRevert("MBS:WFS:LOW_ASSETS");
        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(assets + 1);
    }

    function test_withdrawFromStrategy_successWithPoolDelegate() external {
        vault.__setBalanceOf(address(strategy), 1e6);
        vault.__setExchangeRate(1);

        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleBasicStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.poolDelegate, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (assets))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (assets, address(pool), address(strategy)))
        );

        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_successWithStrategyManager() external {
        assertEq(globals.isInstanceOf("STRATEGY_MANAGER", strategyManager), true);

        vault.__setBalanceOf(address(strategy), 1e6);
        vault.__setExchangeRate(1);

        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleBasicStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isInstanceOf, ("STRATEGY_MANAGER", strategyManager))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (assets))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (assets, address(pool), address(strategy)))
        );

        vm.prank(strategyManager);
        strategy.withdrawFromStrategy(assets);
    }

}

contract MapleBasicStrategyAccrueFeesTests is BasicStrategyTestBase {

    MapleBasicStrategyHarness basicStrategy;

    function setUp() public override {
        super.setUp();
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        basicStrategy = MapleBasicStrategyHarness(address(strategy));

        basicStrategy.__setStrategyFeeRate(1500);  // 15 basis points
    }

    function test_accrueFees_zeroStrategyFeeRateAndNoChangeInTotalAssets() external {
        basicStrategy.__setStrategyFeeRate(0);

        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (0))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_totalAssetsDecreased() external {
        basicStrategy.__setLastRecordedTotalAssets(1e6);

        assertEq(currentTotalAssets(),                    0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
        assertEq(basicStrategy.strategyFeeRate(),         1500);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (0))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(currentTotalAssets(),                    0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_zeroStrategyFeeRate_totalAssetsUnchanged() external {
        basicStrategy.__setLastRecordedTotalAssets(1e6);
        basicStrategy.__setStrategyFeeRate(0);

        vault.__setBalanceOf(address(basicStrategy), 1e6);
        vault.__setExchangeRate(1);

        assertEq(currentTotalAssets(),                    1e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
        assertEq(basicStrategy.strategyFeeRate(),         0);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e6))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(currentTotalAssets(),                    1e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
    }

    function test_accrueFees_zeroStrategyFeeRate_totalAssetsIncreased() external {
        basicStrategy.__setStrategyFeeRate(0);

        vault.__setBalanceOf(address(basicStrategy), 1e6);
        vault.__setExchangeRate(1);

        assertEq(currentTotalAssets(),                    1e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
        assertEq(basicStrategy.strategyFeeRate(),         0);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e6))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(currentTotalAssets(),                    1e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
    }

    function test_accrueFees_strategyFeeRoundedDown() external {
        basicStrategy.__setLastRecordedTotalAssets(100);

        vault.__setBalanceOf(address(basicStrategy), 101);
        vault.__setExchangeRate(1);

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 100);
        assertEq(currentTotalAssets(),                    101);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (101))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.lastRecordedTotalAssets(), 101);
    }

    function test_accrueFees_strategyFeeOneHundredPercent() external {
        basicStrategy.__setLastRecordedTotalAssets(100);
        basicStrategy.__setStrategyFeeRate(1e6);

        vault.__setBalanceOf(address(basicStrategy), 101);
        vault.__setExchangeRate(1);

        assertEq(basicStrategy.strategyFeeRate(),         1e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 100);
        assertEq(currentTotalAssets(),                    101);

        vm.expectEmit();
        emit StrategyFeesCollected(1);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (101))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (1, treasury, address(basicStrategy)))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.lastRecordedTotalAssets(), 100);
    }

    function test_accrueFees_totalAssetsIncreased() external {
        basicStrategy.__setLastRecordedTotalAssets(1e6);

        vault.__setBalanceOf(address(basicStrategy), 3e6);
        vault.__setExchangeRate(1);

        assertEq(currentTotalAssets(),                    3e6);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
        assertEq(basicStrategy.strategyFeeRate(),         1500);

        uint256 strategyFee = ((3e6 - 1e6) * 1500) / 1e6;

        vm.expectEmit();
        emit StrategyFeesCollected(strategyFee);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (3e6))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (strategyFee, treasury, address(basicStrategy)))
        );

        basicStrategy.__accrueFees(address(vault));

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 3e6 - strategyFee);
    }

}

contract MapleBasicStrategySetStrategyFeeRateTests is BasicStrategyTestBase {

    uint256 public constant HUNDRED_PERCENT = 1e6;  // 100.0000%

    MapleBasicStrategyHarness basicStrategy;

    function setUp() public override {
        super.setUp();
        vm.etch(address(strategy), address(new MapleBasicStrategyHarness()).code);

        basicStrategy = MapleBasicStrategyHarness(address(strategy));
    }

    function test_setStrategyFeeRate_failReentrancy() external {
        basicStrategy.__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.setStrategyFeeRate(1500);
    }

    function test_setStrategyFeeRate_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.setStrategyFeeRate(1500);
    }

    function test_setStrategyFeeRate_failIfNotProtocolAdmin() external {
        vm.expectRevert("MS:NOT_ADMIN");
        strategy.setStrategyFeeRate(1500);

        vm.prank(poolDelegate);
        strategy.setStrategyFeeRate(1500);

        vm.prank(governor);
        strategy.setStrategyFeeRate(1500);

        vm.prank(operationalAdmin);
        strategy.setStrategyFeeRate(1500);
    }

    function test_setStrategyFeeRate_failInvalidStrategyFeeRate() external {
        vm.expectRevert("MBS:SSFR:INVALID_STRATEGY_FEE_RATE");
        vm.prank(poolDelegate);
        strategy.setStrategyFeeRate(HUNDRED_PERCENT + 1);
    }

    function test_setStrategyFeeRate_zeroPriorFeeRateAndTotalAssets() external {
        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.prank(poolDelegate);
        basicStrategy.setStrategyFeeRate(1500);

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
    }

    function test_setStrategyFeeRate_zeroPriorFeeRate_totalAssetsIncreased() external {
        // Equivalent of a fundStrategy call prior to a fee being set.
        vault.__setBalanceOf(address(basicStrategy), 1e6);
        vault.__setExchangeRate(1);

        assertEq(basicStrategy.strategyFeeRate(),         0);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 0);
        assertEq(currentTotalAssets(),                    1e6);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.prank(poolDelegate);
        basicStrategy.setStrategyFeeRate(1500);

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
    }

    function test_setStrategyFeeRate_nonZeroPriorFeeRate_totalAssetsIncreased() external {
        basicStrategy.__setStrategyFeeRate(1000);
        basicStrategy.__setLastRecordedTotalAssets(1e6);

        vault.__setBalanceOf(address(basicStrategy), 3e6);
        vault.__setExchangeRate(1);

        assertEq(basicStrategy.strategyFeeRate(),         1000);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 1e6);
        assertEq(currentTotalAssets(),                    3e6);

        uint256 strategyFee = ((3e6 - 1e6) * 1000) / 1e6;

        vm.expectEmit();
        emit StrategyFeesCollected(strategyFee);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (3e6))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (strategyFee, treasury, address(basicStrategy)))
        );

        vm.prank(poolDelegate);
        basicStrategy.setStrategyFeeRate(1500);

        assertEq(basicStrategy.strategyFeeRate(),         1500);
        assertEq(basicStrategy.lastRecordedTotalAssets(), 3e6 - strategyFee);
    }

}
