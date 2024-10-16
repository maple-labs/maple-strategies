// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IERC20Like {

    function approve(address spender, uint256 amount) external returns (bool success);

    function balanceOf(address account_) external view returns (uint256 balance_);

}

interface IERC4626Like {

    function asset() external view returns (address asset_);

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);
}

interface IGlobalsLike {

    function canDeploy(address caller_) external view returns (bool canDeploy_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function governor() external view returns (address governor_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isValidScheduledCall(
        address caller_,
        address contract_,
        bytes32 functionId_,
        bytes calldata callData_
    ) external view returns (bool isValid_);

    function operationalAdmin() external view returns (address operationalAdmin_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external returns (address globals_);

}

interface IPoolLike {

    function asset() external view returns (address asset_);

    function manager() external view returns (address poolManager_);

}

interface IPoolManagerLike {

    function factory() external view returns (address factory_);

    function poolDelegate() external view returns (address poolDelegate_);

    function requestFunds(address destination_, uint256 principal_) external;

}
