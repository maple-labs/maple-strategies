// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleStrategy } from "../IMapleStrategy.sol";

import { IMapleAaveStrategyStorage } from "./IMapleAaveStrategyStorage.sol";

interface IMapleAaveStrategy is IMapleStrategy, IMapleAaveStrategyStorage { }
