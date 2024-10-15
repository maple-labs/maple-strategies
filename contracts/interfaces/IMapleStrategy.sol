// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";


interface IMapleStrategy is IMapleProxied  {

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Returns the address of the globals contract.
     *  @param globals Address of the globals contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev   Return the address of the governor.
     *  @param governor Address of the governor contract.
     */
    function governor() external view returns (address governor);

    /**
     *  @dev   Returns the address of the implementation.
     *  @param implementation Address of the implementation.
     */
    function implementation() external view returns (address implementation);

    /**
     *  @dev   Returns the address of the pool delegate.
     *  @param poolDelegate Address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate);

    /**
     *  @dev   Returns the address of the security admin.
     *  @param securityAdmin Address of the security admin.
     */
    function securityAdmin() external view returns (address securityAdmin);

}
