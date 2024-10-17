// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IERC20Like,
    IERC4626Like,
    IPoolManagerLike,
    IPSMLike
} from "../../contracts/interfaces/Interfaces.sol";

import { SkyStrategyTestBase }     from "../utils/TestBase.sol";
import { MapleSkyStrategyHarness } from "../utils/Harnesses.sol";

contract MapleSkyStrategyViewFunctionTests is SkyStrategyTestBase {

    function setUp() public override {
        super.setUp();
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

    function test_savingsUsds() external view {
        assertEq(strategy.savingsUsds(), address(vault));
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

        MapleSkyStrategyHarness(address(strategy)).setLocked(2);

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

        uint256 sUsdsAmount = amount;
        uint256 usdsAmount  = sUsdsAmount;  // Assume 1:1 exchange rate

        // Expect StrategyFunded event
        vm.expectEmit();
        emit StrategyFunded(amount, sUsdsAmount, usdsAmount);

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
        uint256 sUsdsAmount = amount;
        uint256 usdsAmount  = sUsdsAmount;  // Assume 1:1 exchange rate

        // Expect StrategyFunded event
        vm.expectEmit();
        emit StrategyFunded(amount, sUsdsAmount, usdsAmount);

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
