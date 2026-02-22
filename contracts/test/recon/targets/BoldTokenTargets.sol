
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";

abstract contract BoldTokenTargets is BaseTargetFunctions, Properties  {

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === Clamped Handlers === ///

    function boldToken_approve_clamped(address spender, uint256 amount) public {
        amount = amount % (boldToken.balanceOf(_getActor()) + 1);
        
        boldToken_approve(spender, amount);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function boldToken_approve(address spender, uint256 amount) public updateGhosts asActor {
        boldToken.approve(spender, amount);
    }

    function boldToken_balanceOf(address account) public view returns (uint256) {
        return boldToken.balanceOf(account);
    }
}
