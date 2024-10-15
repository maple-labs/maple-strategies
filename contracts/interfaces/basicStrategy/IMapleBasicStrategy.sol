// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleBasicStrategyStorage {

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Returns the address of the underlying pool asset.
     *  @param asset Address of the underlying pool asset.
     */
    function asset() external view returns (address asset);

}
