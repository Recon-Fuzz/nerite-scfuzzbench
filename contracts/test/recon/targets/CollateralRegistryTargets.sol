
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";
import {ITroveManager} from "../../../src/Interfaces/ITroveManager.sol";

abstract contract CollateralRegistryTargets is BaseTargetFunctions, Properties  {
    
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === Clamped Handlers === ///

    function collateralRegistry_redeemCollateral_clamped(uint256 _boldAmount, uint256 _maxIterationsPerCollateral, uint256 _maxFeePercentage) public {
        _boldAmount = _boldAmount % (boldToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        boldToken.approve(address(collateralRegistry), _boldAmount);
        
        collateralRegistry_redeemCollateral(_boldAmount, _maxIterationsPerCollateral, _maxFeePercentage);
    }

    // Handler to test the redeemCollateral fallback path (lines 140-142)
    // This path is taken when totals.unbacked == 0, which happens when:
    // - All redeemable branches have unbackedPortion = 0 
    // - This occurs when SP size >= total system debt for all collaterals
    // In this rare case, the code uses getEntireSystemDebt() instead as fallback
    // 
    // Strategy: First ensure SP has large deposits, then attempt redemption
    function collateralRegistry_redeem_with_large_sp(uint256 _depositAmount, uint256 _boldAmount, uint256 _maxIterationsPerCollateral, uint256 _maxFeePercentage) public {
        // Step 1: Ensure actor has Bold to deposit
        uint256 actorBalance = boldToken.balanceOf(_getActor());
        if (actorBalance == 0) return;
        
        // Step 2: Deposit a large amount to SP to increase its size
        // This makes it more likely that SP size >= system debt
        _depositAmount = _depositAmount % (actorBalance / 2 + 1); // Use up to half of balance
        if (_depositAmount > 0) {
            vm.prank(_getActor());
            boldToken.approve(address(stabilityPool), _depositAmount);
            vm.prank(_getActor());
            stabilityPool.provideToSP(_depositAmount, false);
        }
        
        // Step 3: Now attempt redemption with remaining balance
        uint256 remainingBalance = boldToken.balanceOf(_getActor());
        if (remainingBalance == 0) return;
        
        _boldAmount = _boldAmount % (remainingBalance + 1);
        _maxFeePercentage = _maxFeePercentage % 1e18;
        
        vm.prank(_getActor());
        boldToken.approve(address(collateralRegistry), _boldAmount);
        
        collateralRegistry_redeemCollateral(_boldAmount, _maxIterationsPerCollateral, _maxFeePercentage);
    }

    // Handler to test getTroveManager with different indices (lines 285-293)
    // This ensures we cover all branches for collateral indices 1-9
    function collateralRegistry_getTroveManager_all_indices(uint256 _index) public {
        // Get total number of collaterals
        uint256 totalCollaterals = collateralRegistry.totalCollaterals();
        if (totalCollaterals == 0) return;
        
        // Clamp index to valid range
        _index = _index % totalCollaterals;
        
        // Call getTroveManager with the clamped index
        // This will cover different branches based on the index value
        try collateralRegistry.getTroveManager(_index) returns (ITroveManager) {
            // Successfully retrieved trove manager for this index
        } catch {
            // Invalid index or other error
        }
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
    
    function collateralRegistry_redeemCollateral(uint256 _boldAmount, uint256 _maxIterationsPerCollateral, uint256 _maxFeePercentage) public updateGhosts asActor {
        collateralRegistry.redeemCollateral(_boldAmount, _maxIterationsPerCollateral, _maxFeePercentage);
        hasDoneRedemption = true;
    }
}