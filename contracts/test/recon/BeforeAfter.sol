// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

import {LatestTroveData} from "../../src/Types/LatestTroveData.sol";
import {LiquityMath} from "../../src/Dependencies/LiquityMath.sol";
import {TroveManager} from "../../src/TroveManager.sol";
import {MIN_DEBT} from "../../src/Dependencies/Constants.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
   struct Vars {
        mapping(uint256 => LatestTroveData troveData) dataForTroves; //maps troveId to its given data
        mapping(address => TroveManager.Batch) batches;
        uint256 collSurplusBalance;
        uint256 ghostDebtAccumulator;
        uint256 entireSystemDebt;
        uint256 ghostWeightedRecordedDebtAccumulator;
        uint256 weightedRecordedDebtAccumulator;
        uint256 price;
    }

    Vars internal _before;
    Vars internal _after;

    modifier updateGhosts {
        __before();
        _;
        __after();
    }

    function __before() internal {
        _before.collSurplusBalance = collSurplusPool.getCollateral(_getActor());
        // always zero accumulators at start for clean summation
        _before.ghostDebtAccumulator = 0; 
        _before.ghostWeightedRecordedDebtAccumulator = 0;
        _before.weightedRecordedDebtAccumulator = 0;
        _before.price = priceFeed.getPrice();

    }

    function __after() internal {
        _after.collSurplusBalance = collSurplusPool.getCollateral(_getActor());
        // always zero accumulators at start for clean summation
        _after.ghostDebtAccumulator = 0; 
        _after.ghostWeightedRecordedDebtAccumulator = 0;
        _after.weightedRecordedDebtAccumulator = 0;
        _after.price = priceFeed.getPrice();
    }
}
