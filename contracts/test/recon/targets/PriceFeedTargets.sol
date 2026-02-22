
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";

abstract contract PriceFeedTargets is BaseTargetFunctions, Properties  {
    
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    // Handler to trigger shutdownFromOracleFailure (line 1188 in BorrowerOperations)
    // This requires calling the function from the priceFeed address
    function priceFeed_trigger_shutdown_from_oracle_failure() public {
        // Check if already shut down
        if (borrowerOperations.hasBeenShutDown()) {
            return; // Already shut down, line 1188 would execute
        }
        
        // Impersonate the priceFeed to call shutdownFromOracleFailure
        vm.prank(address(priceFeed));
        borrowerOperations.shutdownFromOracleFailure();
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
    
    function priceFeed_fetchPrice() public {
        priceFeed.fetchPrice();
    }

    function priceFeed_fetchRedemptionPrice() public {
        priceFeed.fetchRedemptionPrice();
    }

    function priceFeed_setPrice(uint88 price) public {
        priceFeed.setPrice(price);
    }

    function priceFeed_triggerShutdown() public {
        priceFeed.triggerShutdown();
    }
}