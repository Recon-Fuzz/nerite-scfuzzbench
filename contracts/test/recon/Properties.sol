// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

import {MIN_DEBT} from "../../src/Dependencies/Constants.sol";
import {LatestBatchData} from "../../src/Types/LatestBatchData.sol";
import {BatchId} from "../../src/Types/BatchId.sol";
import {SortedTroves} from "../../src/SortedTroves.sol";
import {LatestTroveData} from "../../src/Types/LatestTroveData.sol";


abstract contract Properties is BeforeAfter, Asserts {
    string internal constant ASSERTION_CANARY = "!!! canary assertion";

    function invariant_canary() public pure returns (bool) {
        revert("Canary invariant");
    }

    function assert_canary(uint256 entropy) public {
        t(entropy > 0, ASSERTION_CANARY);
    }
}
