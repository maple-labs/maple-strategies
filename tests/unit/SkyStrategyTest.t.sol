// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console } from "forge-std/console2.sol";

import { IMapleSkyStrategy } from "../../contracts/interfaces/skyStrategy/IMapleSkyStrategy.sol";

import {
    IERC20Like,
    IERC4626Like,
    IGlobalsLike,
    IPoolManagerLike,
    IPSMLike
} from "../../contracts/interfaces/Interfaces.sol";

import { SkyStrategyTestBase }     from "../utils/TestBase.sol";
import { MapleSkyStrategyHarness } from "../utils/Harnesses.sol";

contract MapleSkyStrategyViewFunctionTests is SkyStrategyTestBase {

    MapleSkyStrategyHarness strategyHarness;

    function setUp() public override {
        super.setUp();

        vm.etch(address(strategy), address(new MapleSkyStrategyHarness()).code);

        strategyHarness = MapleSkyStrategyHarness(address(strategy));
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
        assertEq(strategy.treasury(), address(treasury));
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

    function test_savingsUsds() external view {
        assertEq(strategy.savingsUsds(), address(vault));
    }

    function test_assetsUnderManagement_strategyNotFunded() external view {
        assertEq(strategy.assetsUnderManagement(), 0);
    }

    function test_assetsUnderManagement_strategyFundedAndZeroFeeAndZeroTout() external {
        psm.__setTout(0);

        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
        assertEq(strategyHarness.strategyFeeRate(),         0);

        vault.__setBalanceOf(address(strategyHarness), 1e18);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), 1e6);
    }

    function test_assetsUnderManagement_strategyFundedAndZeroFeeWithTout() external {
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
        assertEq(strategyHarness.strategyFeeRate(),         0);

        vault.__setBalanceOf(address(strategyHarness), 1e18);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), _gemForUsds(1e18));
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndLossAndZeroTout() external {
        psm.__setTout(0);

        strategyHarness.__setLastRecordedTotalAssets(2e6);
        strategyHarness.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(strategyHarness.lastRecordedTotalAssets(), 2e6);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(strategy), 1e18);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), 1e6);
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndLossAndTout() external {
        strategyHarness.__setLastRecordedTotalAssets(2e6);
        strategyHarness.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(strategyHarness.lastRecordedTotalAssets(), 2e6);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(strategy), 1e18);
        vault.__setExchangeRate(1);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), _gemForUsds(1e18));
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndTotalAssetsIncreasedAndZeroTout() external {
        psm.__setTout(0);

        strategyHarness.__setLastRecordedTotalAssets(2e6);
        strategyHarness.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(strategyHarness.lastRecordedTotalAssets(), 2e6);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(strategy), 5e18);
        vault.__setExchangeRate(1);

        uint256 strategyFee = ((5e6 - 2e6) * 1500) / 1e6;

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (5e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), 5e6 - strategyFee);
    }

    function test_assetsUnderManagement_strategyFundedWithFeeAndTotalAssetsIncreasedAndAndTout() external {
        strategyHarness.__setLastRecordedTotalAssets(2e6);
        strategyHarness.__setStrategyFeeRate(1500);  // 15 basis points

        assertEq(strategyHarness.lastRecordedTotalAssets(), 2e6);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        vault.__setBalanceOf(address(strategy), 5e18);
        vault.__setExchangeRate(1);

        uint256 strategyFee = ((_gemForUsds(5e18) - 2e6) * 1500) / 1e6;

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (5e18))
        );

        assertEq(strategyHarness.assetsUnderManagement(), _gemForUsds(5e18) - strategyFee);
    }

}

// TODO: Add Test to account for non-zero Tin Value
contract MapleSkyStrategyFundTests is SkyStrategyTestBase {

    uint256 amount = 1e18;

    function setUp() public override {
        super.setUp();

        psm.__setTin(0.01e18);
        psm.__setTout(0.02e18);
    }

    function test_fund_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleSkyStrategyHarness()).code);

        MapleSkyStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.fundStrategy(1e18);
    }

    function test_fund_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("MS:PAUSED");
        strategy.fundStrategy(1e18);
    }

    function test_fund_failIfNonManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.fundStrategy(1e18);
    }

    // Note: To test invalid PSM globals mock needs to be updated.
    function test_fund_failIfInvalidStrategyVault() external {
        globals.__setIsInstanceOf(false);

        vm.prank(poolDelegate);
        vm.expectRevert("MSS:FS:INVALID_STRATEGY_VAULT");
        strategy.fundStrategy(1e18);
    }

    function test_fund_successWithStrategyManager() external {
        assertEq(globals.isInstanceOf("STRATEGY_MANAGER", strategyManager), true);

        vm.expectEmit();
        emit StrategyFunded(amount);

        // Expect call to pool manager to request funds
        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), amount))
        );

        // Expect call to asset for approval of PSM to spend asset
        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(psm), amount))
        );

        // Expect call to PSM for swapping
        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.sellGem, (address(strategy), amount))
        );

        // Expect call to vault for depositing USDS for sUSDS
        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (amount, address(strategy)))
        );

        strategy.fundStrategy(1e18);
    }

    function test_fund_successWithPoolDelegate() external {
        vm.expectEmit();
        emit StrategyFunded(amount);

        // Expect call to pool manager to request funds
        vm.expectCall(
            address(poolManager),
            abi.encodeCall(IPoolManagerLike.requestFunds, (address(strategy), amount))
        );

        // Expect call to asset for approval of PSM to spend asset
        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.approve, (address(psm), amount))
        );

        // Expect call to PSM for swapping
        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.sellGem, (address(strategy), amount))
        );

        // Expect call to vault for depositing USDS for sUSDS
        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.deposit, (amount, address(strategy)))
        );

        vm.startPrank(poolDelegate);
        strategy.fundStrategy(1e18);
    }

}

contract MapleSkyStrategyWithdrawTests is SkyStrategyTestBase {

    uint256 assets = 1e6;
    uint256 shares = 1.02e18;

    function setUp() public override {
        super.setUp();

        psm.__setTin(0.01e18);
        psm.__setTout(0.02e18);
    
        vault.__setExchangeRate(1);
        vault.__setBalanceOf(address(strategy), shares);

        asset.mint(address(strategy), assets); // Mint funds asset to strategy
    }

    function test_withdraw_failReentrancy() external {
        vm.etch(address(strategy), address(new MapleSkyStrategyHarness()).code);

        MapleSkyStrategyHarness(address(strategy)).__setLocked(2);

        vm.expectRevert("MS:LOCKED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdraw_failsIfProtocolPaused() external {
        vm.prank(governor);
        globals.__setFunctionPaused(true);

        vm.prank(strategyManager);
        vm.expectRevert("MS:PAUSED");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdrawFromStrategy_failIfLowAssets() external {
        vm.prank(poolDelegate);
        vm.expectRevert("MSS:WFS:LOW_ASSETS");
        strategy.withdrawFromStrategy(assets + 1);
    }

    function test_withdraw_failsIfNotStrategyManager() external {
        globals.__setIsInstanceOf(false);

        vm.expectRevert("MS:NOT_MANAGER");
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdraw_transferFail() external {
        asset.burn(address(strategy), 1);

        vm.expectRevert("MSS:WFS:TRANSFER_FAILED");
        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdraw_successWithPoolDelegate() external {
        // Expect StrategyWithdrawn event
        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleSkyStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC20Like.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (shares, address(strategy), address(strategy)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), assets))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(pool), assets))
        );

        vm.prank(poolDelegate);
        strategy.withdrawFromStrategy(assets);
    }

    function test_withdraw_successWithStrategyManager() external {
        vm.expectEmit();
        emit StrategyWithdrawal(assets);

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isFunctionPaused, (IMapleSkyStrategy.withdrawFromStrategy.selector))
        );

        vm.expectCall(
            address(globals),
            abi.encodeCall(IGlobalsLike.isInstanceOf, ("STRATEGY_MANAGER", strategyManager))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC20Like.balanceOf, (address(strategy)))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (shares, address(strategy), address(strategy)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), assets))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(pool), assets))
        );

        vm.prank(strategyManager);
        strategy.withdrawFromStrategy(assets);
    }

}

contract MapleSkyStrategyAccrueFeesTests is SkyStrategyTestBase {

    MapleSkyStrategyHarness strategyHarness;

    function setUp() public override {
        super.setUp();
        vm.etch(address(strategy), address(new MapleSkyStrategyHarness()).code);

        strategyHarness = MapleSkyStrategyHarness(address(strategy));

        strategyHarness.__setStrategyFeeRate(1500);  // 15 basis points
    }

    function test_accrueFees_zeroStrategyFeeRateAndNoChangeInTotalAssets() external {
        strategyHarness.__setStrategyFeeRate(0);

        assertEq(strategyHarness.strategyFeeRate(),         0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (0))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.strategyFeeRate(),         0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_totalAssetsDecreased() external {
        strategyHarness.__setLastRecordedTotalAssets(1e18);

        assertEq(currentTotalAssets(),                    0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e18);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (0))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(currentTotalAssets(),                    0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
    }

    function test_accrueFees_zeroStrategyFeeRate_totalAssetsIncreased() external {
        strategyHarness.__setStrategyFeeRate(0);

        vault.__setBalanceOf(address(strategyHarness), 1e18);
        vault.__setExchangeRate(1);

        assertEq(currentTotalAssets(),                      _gemForUsds(1e18));
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
        assertEq(strategyHarness.strategyFeeRate(),         0);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.strategyFeeRate(),         0);
        assertEq(currentTotalAssets(),                      _gemForUsds(1e18));
        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(1e18));
    }

    function test_accrueFees_strategyFeeRoundedDown() external {
        strategyHarness.__setLastRecordedTotalAssets(_gemForUsds(1e18));

        vault.__setBalanceOf(address(strategyHarness), 1e18 + 100);
        vault.__setExchangeRate(1);

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(1e18));
        assertEq(currentTotalAssets(),                      _gemForUsds(1e18)); // The rounding is already lost at this point.

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (1e18 + 100))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(1e18 + 100));
    }

    function test_accrueFees_strategyFeeOneHundredPercent() external {
        strategyHarness.__setLastRecordedTotalAssets(1e6);
        strategyHarness.__setStrategyFeeRate(1e6);
 
        vault.__setBalanceOf(address(strategyHarness), 1.1e18);
        vault.__setExchangeRate(1);

        assertEq(strategyHarness.strategyFeeRate(),         1e6);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e6);
        assertEq(currentTotalAssets(),                      _gemForUsds(1.1e18));

        uint256 feeAmount    = _gemForUsds(1.1e18) - 1e6;
        uint256 assetsAmount = _usdsForGem(feeAmount);

        asset.mint(address(strategyHarness), feeAmount);

        vm.expectEmit();
        emit StrategyFeesCollected(feeAmount);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (assetsAmount, address(strategyHarness), address(strategyHarness)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), feeAmount))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(treasury), feeAmount))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e6);
    }

    function test_accrueFees_totalAssetsIncreased() external {
        strategyHarness.__setLastRecordedTotalAssets(1e6);

        vault.__setBalanceOf(address(strategyHarness), 3e18);
        vault.__setExchangeRate(1);

        assertEq(currentTotalAssets(),                      _gemForUsds(3e18));
        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e6);
        assertEq(strategyHarness.strategyFeeRate(),         1500);

        uint256 strategyFee = ((_gemForUsds(3e18) - 1e6) * 1500) / 1e6;
        uint256 assetsAmount = _usdsForGem(strategyFee);

        asset.mint(address(strategyHarness), strategyFee);

        vm.expectEmit();
        emit StrategyFeesCollected(strategyFee);

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (3e18))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (assetsAmount, address(strategyHarness), address(strategyHarness)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), strategyFee))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(treasury), strategyFee))
        );

        strategyHarness.__accrueFees();

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(3e18) - strategyFee);
    }

}

contract MapleSkyStrategySetStrategyFeeRateTests is SkyStrategyTestBase {

    uint256 public constant HUNDRED_PERCENT = 1e6;  // 100.0000%

    MapleSkyStrategyHarness strategyHarness;

    function setUp() public override {
        super.setUp();
        vm.etch(address(strategy), address(new MapleSkyStrategyHarness()).code);

        strategyHarness = MapleSkyStrategyHarness(address(strategy));
    }

    function test_setStrategyFeeRate_failReentrancy() external {
        strategyHarness.__setLocked(2);

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
        vm.expectRevert("MSS:SSFR:INVALID_STRATEGY_FEE_RATE");
        vm.prank(poolDelegate);
        strategy.setStrategyFeeRate(HUNDRED_PERCENT + 1);
    }

    // Since totalAssets is 0, the Tout doesn't matter.
    function test_setStrategyFeeRate_zeroPriorFeeRateAndTotalAssetsAndZeroTout() external {
        psm.__setTout(0);

        assertEq(strategyHarness.strategyFeeRate(),         0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.prank(poolDelegate);
        strategyHarness.setStrategyFeeRate(1500);

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
    }

    function test_setStrategyFeeRate_zeroPriorFeeRate_totalAssetsIncreasedWithTout() external {
        // Equivalent of a fundStrategy call prior to a fee being set.
        vault.__setBalanceOf(address(strategyHarness), 1e18);
        vault.__setExchangeRate(1);

        assertEq(strategyHarness.strategyFeeRate(),         0);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 0);
        assertEq(currentTotalAssets(),                      _gemForUsds(1e18));

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.prank(poolDelegate);
        strategyHarness.setStrategyFeeRate(1500);

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(1e18));
    }

    function test_setStrategyFeeRate_nonZeroPriorFeeRate_totalAssetsIncreasedWithZeroTout() external {
        psm.__setTout(0);

        strategyHarness.__setStrategyFeeRate(1000);
        strategyHarness.__setLastRecordedTotalAssets(1e6);

        vault.__setBalanceOf(address(strategyHarness), 3e18);
        vault.__setExchangeRate(1);

        assertEq(strategyHarness.strategyFeeRate(),         1000);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e6);
        assertEq(currentTotalAssets(),                      3e6);

        uint256 feeInAssets = (3e18 - 1e18) * 1000 / 1e6;
        uint256 strategyFee = ((3e6 - 1e6) * 1000) / 1e6;

        // Mint enough funds asset to cover the strategy fee
        asset.mint(address(strategyHarness), strategyFee);

        vm.expectEmit();
        emit StrategyFeesCollected(strategyFee);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (3e18))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (feeInAssets, address(strategyHarness), address(strategyHarness)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), strategyFee))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(treasury), strategyFee))
        );

        vm.prank(poolDelegate);
        strategyHarness.setStrategyFeeRate(1500);

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 3e6 - strategyFee);
    }

    function test_setStrategyFeeRate_nonZeroPriorFeeRate_totalAssetsIncreasedWithTout() external {
        strategyHarness.__setStrategyFeeRate(1000);
        strategyHarness.__setLastRecordedTotalAssets(1e6);

        vault.__setBalanceOf(address(strategyHarness), 3e18);
        vault.__setExchangeRate(1);

        assertEq(strategyHarness.strategyFeeRate(),         1000);
        assertEq(strategyHarness.lastRecordedTotalAssets(), 1e6);
        assertEq(currentTotalAssets(),                      _gemForUsds(3e18));

        uint256 strategyFee = ((_gemForUsds(3e18) - 1e6) * 1000) / 1e6;

        asset.mint(address(strategyHarness), strategyFee);

        vm.expectEmit();
        emit StrategyFeesCollected(strategyFee);

        vm.expectEmit();
        emit StrategyFeeRateSet(1500);

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.tout, ())
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.to18ConversionFactor, ())
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.convertToAssets, (3e18))
        );

        vm.expectCall(
            address(vault),
            abi.encodeCall(IERC4626Like.withdraw, (_usdsForGem(strategyFee), address(strategyHarness), address(strategyHarness)))
        );

        vm.expectCall(
            address(psm),
            abi.encodeCall(IPSMLike.buyGem, (address(strategy), strategyFee))
        );

        vm.expectCall(
            address(asset),
            abi.encodeCall(IERC20Like.transfer, (address(treasury), strategyFee))
        );

        vm.prank(poolDelegate);
        strategyHarness.setStrategyFeeRate(1500);

        assertEq(strategyHarness.strategyFeeRate(),         1500);
        assertEq(strategyHarness.lastRecordedTotalAssets(), _gemForUsds(3e18) - strategyFee);
    }

}
