// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IMapleStrategy } from "../IMapleStrategy.sol";

import { IMapleSkyStrategyStorage } from "./IMapleSkyStrategyStorage.sol";

interface IMapleSkyStrategy is IMapleStrategy, IMapleSkyStrategyStorage { }
