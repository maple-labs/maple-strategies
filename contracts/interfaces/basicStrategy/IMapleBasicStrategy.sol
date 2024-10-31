// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleStrategy } from "../IMapleStrategy.sol";

import { IMapleBasicStrategyStorage } from "./IMapleBasicStrategyStorage.sol";

interface IMapleBasicStrategy is IMapleStrategy, IMapleBasicStrategyStorage { }
