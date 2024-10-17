// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { IMapleBasicStrategy } from "./interfaces/basicStrategy/IMapleBasicStrategy.sol";

import {
    IERC20Like,
    IERC4626Like,
    IGlobalsLike,
    IPoolLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { MapleBasicStrategyStorage } from "./proxy/basicStrategy/MapleBasicStrategyStorage.sol";

import { MapleAbstractStrategy } from "./MapleAbstractStrategy.sol";

/*
    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

    ███████╗████████╗██████╗  █████╗ ████████╗███████╗ ██████╗██╗   ██╗
    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝╚██╗ ██╔╝
    ███████╗   ██║   ██████╔╝███████║   ██║   █████╗  ██║  ███╗╚████╔╝
    ╚════██║   ██║   ██╔══██╗██╔══██║   ██║   ██╔══╝  ██║   ██║ ╚██╔╝
    ███████║   ██║   ██║  ██║██║  ██║   ██║   ███████╗╚██████╔╝  ██║
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝   ╚═╝

*/

contract MapleBasicStrategy is IMapleBasicStrategy, MapleBasicStrategyStorage , MapleAbstractStrategy {

    /**************************************************************************************************************************************/
    /*** Strategy External Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Validation before and after funding
    // TODO: Should we pass a min amount of shares we expect and validate
    // TODO: Add Fees
    function fundStrategy(uint256 assets_) external override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        address strategyVault_ = strategyVault;

        require(IGlobalsLike(globals()).isInstanceOf("STRATEGY_VAULT", strategyVault_), "MBS:FS:INVALID_STRATEGY_VAULT");

        // Prepare funds for the strategy
        _prepareFundsForStrategy(strategyVault_, assets_);

        // Fund Strategy
        uint256 shares_ = IERC4626Like(strategyVault_).deposit(assets_, address(this));

        emit StrategyFunded(assets_, shares_);
    }

    // TODO: Validation before and after funding
    // TODO: Should we pass in the min amount of assets we expect and validate
    // TODO: Add Fees
    function withdrawFromStrategy(uint256 assets_, bool maxAssets_) public override nonReentrant whenProtocolNotPaused onlyStrategyManager {
        assets_ = maxAssets_ ? assetsUnderManagement() : assets_;

        uint256 sharesWithdrawn_ = IERC4626Like(strategyVault).withdraw(assets_, address(pool), address(this));

        emit StrategyWithdrawal(assets_, sharesWithdrawn_);
    }

    /**************************************************************************************************************************************/
    /*** Strategy View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    // TODO: Must net out fees from AUM
    function assetsUnderManagement() public view override returns (uint256 assetsUnderManagement_) {
        address strategyVault_ = strategyVault;

        return IERC4626Like(strategyVault_).convertToAssets(IERC20Like(strategyVault_).balanceOf(address(this)));
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _prepareFundsForStrategy(address destination_, uint256 amount_) internal {
        // Request funds from Pool Manager.
        IPoolManagerLike(poolManager).requestFunds(address(this), amount_);

        // Approve the strategy to use these funds.
        require(ERC20Helper.approve(fundsAsset, destination_, amount_), "MBS:PFFS:APPROVE_FAILED");
    }

    function _setLock(uint256 lock_) internal override {
        locked = lock_;
    }

    function _locked() internal view override returns (uint256) {
        return locked;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function asset() public view override returns (address asset_) {
        asset_ = fundsAsset;
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view override returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function securityAdmin() public view override returns (address securityAdmin_) {
        securityAdmin_ = IGlobalsLike(globals()).securityAdmin();
    }

}
