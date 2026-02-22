
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {ActivePoolTargets} from "./targets/ActivePoolTargets.sol";
import {BoldTokenTargets} from "./targets/BoldTokenTargets.sol";
import {BorrowerOperationsTargets} from "./targets/BorrowerOperationsTargets.sol";
import {CollateralRegistryTargets} from "./targets/CollateralRegistryTargets.sol";
import {CollTokenTargets} from "./targets/CollTokenTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";
import {PriceFeedTargets} from "./targets/PriceFeedTargets.sol";
import {StabilityPoolTargets} from "./targets/StabilityPoolTargets.sol";
import {TroveManagerTargets} from "./targets/TroveManagerTargets.sol";

abstract contract TargetFunctions is 
    ActivePoolTargets,
    BoldTokenTargets,
    BorrowerOperationsTargets,
    CollateralRegistryTargets,
    CollTokenTargets,
    ManagersTargets,
    PriceFeedTargets,
    StabilityPoolTargets,
    TroveManagerTargets

 {

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    // SHORTCUT HANDLERS - Phase 2
    
    // collToken_transfer shortcuts
    // PATH 0: _balanceOf[msg.sender] >= amount
    function shortcut_collToken_transfer_withBalance(
        uint256 amount,
        address to
    ) public {
        // Transfer requires sufficient balance
        // Clamp amount to actor's balance
        amount = amount % (collToken.balanceOf(_getActor()) + 1);
        
        collToken_transfer(to, amount);
    }

    // collToken_transferFrom shortcuts
    // PATH 0: allowed != ~0 (allowance is not unlimited)
    function shortcut_collToken_transferFrom_withLimitedAllowance(
        address from,
        address to,
        uint256 amount,
        uint256 allowanceAmount
    ) public {
        // Set limited allowance
        vm.prank(from);
        collToken.approve(_getActor(), allowanceAmount);
        
        // Clamp amount to allowance
        amount = amount % (allowanceAmount + 1);
        
        collToken_transferFrom(from, to, amount);
    }

    // PATH 1: allowed == ~0 (unlimited allowance)
    function shortcut_collToken_transferFrom_withUnlimitedAllowance(
        address from,
        address to,
        uint256 amount
    ) public {
        // Set unlimited allowance
        vm.prank(from);
        collToken.approve(_getActor(), type(uint256).max);
        
        collToken_transferFrom(from, to, amount);
    }

    // stabilityPool_triggerBoldRewards shortcuts
    // PATH 0: accumulatedYieldGains != 0 && totalBoldDepositsCached < DECIMAL_PRECISION
    function shortcut_triggerBoldRewards_withYieldGains_lowDeposits(
        uint256 depositAmount
    ) public {
        // Provide to SP with small amount to ensure totalBoldDepositsCached < DECIMAL_PRECISION
        depositAmount = depositAmount % (1e18 + 1); // Keep below DECIMAL_PRECISION
        
        stabilityPool_provideToSP_clamped(depositAmount, true);
        
        // Trigger rewards (must be called from activePool)
        vm.prank(address(activePool));
        stabilityPool_triggerBoldRewards(0);
    }

    // PATH 1: accumulatedYieldGains == 0
    function shortcut_triggerBoldRewards_noYieldGains() public {
        // Just trigger rewards with no accumulated gains
        vm.prank(address(activePool));
        stabilityPool_triggerBoldRewards(0);
    }

    // PATH 2: accumulatedYieldGains != 0 && totalBoldDepositsCached >= DECIMAL_PRECISION
    function shortcut_triggerBoldRewards_withYieldGains_highDeposits(
        uint256 depositAmount
    ) public {
        // Provide to SP with large amount
        depositAmount = 1e18 + (depositAmount % (collToken.balanceOf(_getActor()) + 1));
        
        stabilityPool_provideToSP_clamped(depositAmount, true);
        
        // Trigger rewards
        vm.prank(address(activePool));
        stabilityPool_triggerBoldRewards(0);
    }

    // stabilityPool_claimAllCollGains shortcuts
    // PATH 0: collToSend == 0
    function shortcut_claimAllCollGains_noGains() public {
        // Claim when there are no gains
        stabilityPool_claimAllCollGains();
    }

    // PATH 1: collToSend != 0
    function shortcut_claimAllCollGains_withGains(
        uint256 depositAmount,
        uint256 debtToOffset,
        uint256 collToAdd
    ) public {
        // 1. Provide to SP
        stabilityPool_provideToSP_clamped(depositAmount, true);
        
        // 2. Offset to generate collateral gains
        vm.prank(address(troveManager));
        stabilityPool_offset(debtToOffset, collToAdd);
        
        // 3. Claim gains
        stabilityPool_claimAllCollGains();
    }

    // borrowerOperations_setRemoveManagerWithReceiver shortcuts
    // PATH 0: msg.sender == troveNFT.ownerOf(_troveId) && (_manager != 0) && (_receiver != 0)
    function shortcut_setRemoveManagerWithReceiver_asOwner(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 interestRate,
        address manager,
        address receiver
    ) public {
        // 1. Open trove to become owner
        borrowerOperations_openTrove_clamped(
            _getActor(), 
            0, 
            collAmount, 
            boldAmount, 
            0, 
            0, 
            interestRate, 
            type(uint256).max, 
            address(0), 
            address(0), 
            address(0)
        );
        
        // 2. Set manager with receiver (ensuring non-zero addresses)
        address actualManager = manager != address(0) ? manager : address(0x1);
        address actualReceiver = receiver != address(0) ? receiver : address(0x2);
        
        // Use the entropy from troveIds array to select the trove we just created
        borrowerOperations_setRemoveManagerWithReceiver_clamped(actualManager, actualReceiver, troveIds.length - 1);
    }

    // borrowerOperations_setRemoveManager shortcuts
    // PATH 0: msg.sender == troveNFT.ownerOf(_troveId) && (_manager != 0)
    function shortcut_setRemoveManager_asOwner(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 interestRate,
        address manager
    ) public {
        // 1. Open trove to become owner
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            collAmount,
            boldAmount,
            0,
            0,
            interestRate,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // 2. Set manager (ensuring non-zero address)
        address actualManager = manager != address(0) ? manager : address(0x1);
        
        // Use the entropy from troveIds array
        borrowerOperations_setRemoveManager_clamped(actualManager, troveIds.length - 1);
    }

    // borrowerOperations_setAddManager shortcuts
    // PATH 0: msg.sender == troveNFT.ownerOf(_troveId)
    function shortcut_setAddManager_asOwner(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 interestRate,
        address manager
    ) public {
        // 1. Open trove to become owner
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            collAmount,
            boldAmount,
            0,
            0,
            interestRate,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // 2. Set add manager
        borrowerOperations_setAddManager_clamped(manager, troveIds.length - 1);
    }

    // borrowerOperations_removeInterestIndividualDelegate shortcuts
    // PATH 0: msg.sender == troveNFT.ownerOf(_troveId)
    function shortcut_removeInterestIndividualDelegate_asOwner(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 interestRate
    ) public {
        // 1. Open trove
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            collAmount,
            boldAmount,
            0,
            0,
            interestRate,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // 2. Set individual delegate first
        borrowerOperations_setInterestIndividualDelegate_clamped(
            address(0x123),
            0,
            type(uint128).max,
            interestRate,
            0,
            0,
            type(uint256).max,
            0,
            troveIds.length - 1
        );
        
        // 3. Remove delegate
        borrowerOperations_removeInterestIndividualDelegate_clamped(troveIds.length - 1);
    }

    // borrowerOperations_onLiquidateTrove shortcuts
    // PATH 0: msg.sender == troveManager
    function shortcut_onLiquidateTrove_fromTroveManager(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 interestRate
    ) public {
        // 1. Open trove
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            collAmount,
            boldAmount,
            0,
            0,
            interestRate,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // 2. Call from troveManager
        uint256 troveId = troveIds[troveIds.length - 1];
        vm.prank(address(troveManager));
        borrowerOperations_onLiquidateTrove(troveId);
    }

    // borrowerOperations_registerBatchManager shortcuts
    // PATH 0: Basic registration
    function shortcut_registerBatchManager_basic(
        uint128 minInterestRate,
        uint128 maxInterestRate,
        uint128 currentInterestRate,
        uint128 annualManagementFee,
        uint128 minInterestRateChangePeriod
    ) public {
        borrowerOperations_registerBatchManager_clamped(
            minInterestRate,
            maxInterestRate,
            currentInterestRate,
            annualManagementFee,
            minInterestRateChangePeriod
        );
    }

    // borrowerOperations_lowerBatchManagementFee shortcuts
    // PATH 0: Lower fee after registering
    function shortcut_lowerBatchManagementFee_afterRegister(
        uint128 initialFee,
        uint128 newFee
    ) public {
        // 1. Register batch manager
        borrowerOperations_registerBatchManager_clamped(
            0,
            type(uint128).max,
            1e17,
            initialFee,
            0
        );
        
        // 2. Lower the fee (ensure newFee < initialFee by clamping)
        newFee = newFee % (initialFee + 1);
        
        borrowerOperations_lowerBatchManagementFee_clamped(newFee);
    }

    // COVERAGE PHASE 4 - CLAMPED HANDLERS FOR MISSING COVERAGE

    // Handler 1: CollateralRegistry.redeemCollateral - reaching line 140-142
    // This targets the edge case where totals.unbacked == 0 but branches are still redeemable
    // SHORTCUT: Create scenario where SP fully covers system debt (unbacked = 0) but TCR > SCR (redeemable)
    function coverage_redeemCollateral_edgeCase(
        uint256 depositAmount,
        uint256 troveCollAmount,
        uint256 troveDebtAmount,
        uint256 redeemAmount
    ) public {
        // This edge case occurs when:
        // 1. Stability Pool size >= total system debt (makes unbackedPortion = 0)
        // 2. BUT TCR > SCR (branch is still redeemable)
        // Then the code uses getEntireSystemDebt() as fallback
        
        // Step 1: Open a trove to create some system debt
        troveCollAmount = (troveCollAmount % (collToken.balanceOf(_getActor()) / 2 + 1)) + 2e18;
        troveDebtAmount = (troveDebtAmount % 10000e18) + 2000e18; // At least MIN_DEBT
        
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            troveCollAmount,
            troveDebtAmount,
            0,
            0,
            1e17,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // Step 2: Deposit large amount to SP to ensure SP size >= system debt
        // This makes unbackedPortion = 0 in first loop
        uint256 actorBoldBalance = boldToken.balanceOf(_getActor());
        if (actorBoldBalance > 0) {
            depositAmount = (depositAmount % (actorBoldBalance / 2 + 1)) + (actorBoldBalance / 2);
            stabilityPool_provideToSP_clamped(depositAmount, true);
        }
        
        // Step 3: Now attempt redemption
        // At this point, SP covers debt (unbacked=0) but system is healthy (TCR > SCR)
        // This triggers the fallback path using getEntireSystemDebt()
        uint256 remainingBold = boldToken.balanceOf(_getActor());
        if (remainingBold > 100e18) { // Need some Bold to redeem
            redeemAmount = (redeemAmount % (remainingBold / 2 + 1)) + 100e18;
            collateralRegistry_redeemCollateral_clamped(redeemAmount, 10, type(uint256).max);
        }
    }

    // Handler 2: TroveManager.batchLiquidateTroves - generating collSurplus
    // To reach line 440, we need liquidations that generate surplus collateral
    // This happens in recovery mode when well-collateralized troves are liquidated
    function coverage_batchLiquidateTroves_withSurplus(
        uint256 highCollAmount,
        uint256 lowCollAmount,
        uint256 debtAmount,
        uint256 priceDropPercent
    ) public {
        // SHORTCUT FUNCTION: Create recovery mode scenario with collateral surplus
        
        // Step 1: Open a well-collateralized trove (high CR)
        // This trove will generate surplus when liquidated
        uint256 safeCollAmount = (highCollAmount % (collToken.balanceOf(_getActor()) / 2 + 1)) + 1e18; // At least 1 ETH
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            safeCollAmount,
            debtAmount,
            0,
            0,
            1e17, // 10% interest rate
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // Step 2: Open another trove with low collateralization (will help trigger recovery mode)
        switchActor(1);
        uint256 riskyCollAmount = (lowCollAmount % (collToken.balanceOf(_getActor()) / 2 + 1)) + 1e17; // At least 0.1 ETH
        borrowerOperations_openTrove_clamped(
            _getActor(),
            1,
            riskyCollAmount,
            debtAmount,
            0,
            0,
            1e17,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // Step 3: Drop the price to trigger recovery mode and make troves liquidatable
        // Get current price and reduce it
        uint256 currentPrice = priceFeed.getPrice();
        uint256 priceDropFactor = (priceDropPercent % 50) + 50; // Drop 50-99%
        uint256 newPrice = (currentPrice * priceDropFactor) / 100;
        priceFeed_setPrice(uint88(newPrice));
        
        // Step 4: Now batch liquidate - should generate collateral surplus
        if (troveIds.length >= 2) {
            uint256[] memory trovesToLiquidate = new uint256[](2);
            trovesToLiquidate[0] = troveIds[troveIds.length - 2]; // First trove we opened
            trovesToLiquidate[1] = troveIds[troveIds.length - 1]; // Second trove we opened
            
            switchActor(0);
            troveManager_batchLiquidateTroves(trovesToLiquidate);
        }
    }

    // Handler 3: BorrowerOperations.applyPendingDebt - zombie recovery
    // To reach lines 787-789, we need a zombie trove with enough pending debt to exceed MIN_DEBT
    // SHORTCUT: Create zombie trove, trigger redistributions, then apply pending debt
    function coverage_applyPendingDebt_zombieRecovery(
        uint256 zombieCollAmount,
        uint256 zombieDebtAmount,
        uint256 victimCollAmount,
        uint256 victimDebtAmount
    ) public {
        // This shortcut creates the exact scenario:
        // 1. Creates a trove that will become zombie (near MIN_DEBT)
        // 2. Creates victim troves that will be liquidated
        // 3. Liquidates victims to create redistribution gains
        // 4. Applies pending debt to zombie trove to recover it
        
        uint256 MIN_DEBT = 2000e18; // Typical MIN_DEBT value
        
        // Step 1: Open a trove with debt just below MIN_DEBT (will become zombie after small redemption)
        // Clamp debt to be slightly above MIN_DEBT initially
        zombieDebtAmount = MIN_DEBT + (zombieDebtAmount % MIN_DEBT);
        zombieCollAmount = (zombieCollAmount % (collToken.balanceOf(_getActor()) / 3 + 1)) + 2e18;
        
        borrowerOperations_openTrove_clamped(
            _getActor(),
            0,
            zombieCollAmount,
            zombieDebtAmount,
            0,
            0,
            1e17,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        uint256 targetTroveId = troveIds[troveIds.length - 1];
        
        // Step 2: Open victim troves with low CR (will be liquidated to create redistributions)
        switchActor(1);
        victimCollAmount = (victimCollAmount % (collToken.balanceOf(_getActor()) / 3 + 1)) + 1e18;
        borrowerOperations_openTrove_clamped(
            _getActor(),
            1,
            victimCollAmount,
            victimDebtAmount,
            0,
            0,
            1e17,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // Step 3: Make first trove zombie via small redemption (if possible)
        // Use collateralRegistry to redeem and reduce the first trove below MIN_DEBT
        switchActor(0);
        uint256 redeemAmount = MIN_DEBT / 2; // Redeem enough to zombify it
        if (boldToken.balanceOf(_getActor()) >= redeemAmount) {
            collateralRegistry_redeemCollateral_clamped(redeemAmount, 1, type(uint256).max);
        }
        
        // Step 4: Drop price to liquidate victim trove (creates redistribution)
        uint256 currentPrice = priceFeed.getPrice();
        priceFeed_setPrice(uint88(currentPrice / 2)); // 50% price drop
        
        // Step 5: Liquidate victim to trigger redistribution
        if (troveIds.length >= 2) {
            troveManager_liquidate_clamped(troveIds.length - 1);
        }
        
        // Step 6: Apply pending debt to the zombie trove
        // It should now have enough redistribution gains to exceed MIN_DEBT
        borrowerOperations_applyPendingDebt(targetTroveId, 0, 0);
    }

    // Handler 4: CollateralRegistry.getTroveManager - test all indices
    // To cover lines 285-293, we need to call getTroveManager with indices 1-9
    function coverage_getTroveManager_allIndices(uint256 indexEntropy) public {
        // Get total number of collaterals
        uint256 totalColls = collateralRegistry.totalCollaterals();
        if (totalColls == 0) return;
        
        // Clamp index to valid range [0, totalColls-1]
        uint256 index = indexEntropy % totalColls;
        
        // Call getTroveManager with this index
        collateralRegistry.getTroveManager(index);
    }

    // Handler 5: StabilityPool.claimAllCollGains - with stashed collateral
    // To reach lines 360-363, we need users with nonzero stashedColl
    // SHORTCUT: Deposit -> Generate gains via liquidation -> Withdraw -> Claim stashed
    function coverage_claimAllCollGains_withStashedColl(
        uint256 depositAmount,
        uint256 troveCollAmount,
        uint256 troveDebtAmount
    ) public {
        // Scenario to create stashed collateral:
        // 1. Deposit Bold to SP
        // 2. Create and liquidate a trove to generate collateral gains
        // 3. Withdraw all deposit (which stashes the unclaimed collateral)
        // 4. Call claimAllCollGains to claim the stashed collateral
        
        // Step 1: Provide Bold to SP
        uint256 actorBoldBalance = boldToken.balanceOf(_getActor());
        if (actorBoldBalance < 1000e18) return; // Need sufficient Bold
        
        depositAmount = (depositAmount % (actorBoldBalance / 2 + 1)) + 1000e18;
        stabilityPool_provideToSP_clamped(depositAmount, true);
        
        // Step 2: Create a trove to liquidate (switch to different actor)
        switchActor(1);
        troveCollAmount = (troveCollAmount % (collToken.balanceOf(_getActor()) + 1)) + 1e18;
        troveDebtAmount = (troveDebtAmount % 5000e18) + 2000e18; // At least MIN_DEBT
        
        borrowerOperations_openTrove_clamped(
            _getActor(),
            1,
            troveCollAmount,
            troveDebtAmount,
            0,
            0,
            1e17,
            type(uint256).max,
            address(0),
            address(0),
            address(0)
        );
        
        // Step 3: Drop price to make trove liquidatable
        uint256 currentPrice = priceFeed.getPrice();
        priceFeed_setPrice(uint88(currentPrice / 2)); // 50% drop
        
        // Step 4: Liquidate the trove (generates collateral gains for SP depositors)
        if (troveIds.length > 0) {
            switchActor(0);
            troveManager_liquidate_clamped(troveIds.length - 1);
        }
        
        // Step 5: Withdraw all deposit to stash the collateral gains
        // When withdrawing with gains pending, they get stashed
        uint256 currentDeposit = stabilityPool.deposits(_getActor());
        if (currentDeposit > 0) {
            stabilityPool_withdrawFromSP_clamped(currentDeposit, true);
        }
        
        // Step 6: Now claim the stashed collateral gains
        // User should have no deposit but have stashedColl > 0
        stabilityPool_claimAllCollGains();
    }

    // Handler 6 & 7: System Shutdown handlers
    // The shutdown functions require special authorization
    
    // Handler to trigger shutdown (needs to be called as priceFeed)
    function coverage_triggerShutdown() public {
        // This function attempts to trigger a shutdown
        // shutdownFromOracleFailure requires caller to be priceFeed
        vm.prank(address(priceFeed));
        borrowerOperations_shutdownFromOracleFailure();
    }

    // Handler for urgentRedemption (requires system to be shut down)
    function coverage_urgentRedemption_afterShutdown(
        uint256 boldAmount,
        uint256 minCollateral,
        uint256 troveEntropy
    ) public {
        // First check if system is shut down
        if (!borrowerOperations.hasBeenShutDown()) {
            // Try to trigger shutdown first
            coverage_triggerShutdown();
        }
        
        // Now attempt urgent redemption
        if (troveIds.length == 0) return;
        
        uint256[] memory troveIdsToRedeem = new uint256[](1);
        troveIdsToRedeem[0] = troveIds[troveEntropy % troveIds.length];
        
        // Clamp boldAmount to actor's balance
        boldAmount = boldAmount % (boldToken.balanceOf(_getActor()) + 1);
        
        troveManager_urgentRedemption(boldAmount, troveIdsToRedeem, minCollateral);
    }

    // Handler 8: BorrowerOperations.closeTrove - for batched troves
    // To reach lines 699-706 and 727, we need to close troves that are in batches
    function coverage_closeTrove_batched(
        uint256 entropy
    ) public {
        // Only close troves that have a batch manager
        if (troveIds.length == 0) return;
        
        uint256 troveId = troveIds[entropy % troveIds.length];
        
        // Check if this trove has a batch manager
        address batchManager = borrowerOperations.interestBatchManagerOf(troveId);
        if (batchManager != address(0)) {
            // This trove is batched, try to close it
            borrowerOperations_closeTrove_clamped(entropy);
        }
    }

    // Handler 9: BorrowerOperations.setBatchManagerAnnualInterestRate - premature adjustment
    // To reach lines 928-944, we need to adjust rate within the cooldown period
    function coverage_setBatchManagerAnnualInterestRate_premature(
        uint128 initialRate,
        uint128 newRate,
        uint256 maxUpfrontFee
    ) public {
        // First register as a batch manager
        borrowerOperations_registerBatchManager_clamped(
            0,
            type(uint128).max,
            initialRate,
            1e16, // 1% management fee
            0
        );
        
        // Immediately try to change the rate (within cooldown period)
        // Ensure newRate is different from initialRate
        if (newRate == initialRate) {
            newRate = initialRate + 1;
        }
        
        borrowerOperations_setBatchManagerAnnualInterestRate_clamped(
            newRate,
            0,
            0,
            maxUpfrontFee
        );
    }

    // Handler 10: BorrowerOperations.openTroveAndJoinInterestBatchManager - fixed version
    // The existing handler needs better parameter clamping
    function coverage_openTroveAndJoinBatch_fixed(
        uint256 collAmount,
        uint256 boldAmount,
        uint256 batchEntropy
    ) public {
        // First ensure we have at least one registered batch manager
        // Register as batch manager
        borrowerOperations_registerBatchManager_clamped(
            0,
            type(uint128).max,
            1e17, // 10% interest rate
            1e16, // 1% management fee
            0
        );
        
        // Now call the existing clamped handler
        borrowerOperations_openTroveAndJoinBatch_clamped(collAmount, boldAmount, batchEntropy);
    }

    // Handler 11: BorrowerOperations.adjustZombieTrove
    // To reach lines 480-498, we need zombie troves
    function coverage_adjustZombieTrove_clamped(
        uint256 entropy,
        uint256 collChange,
        bool isCollIncrease,
        uint256 boldChange,
        bool isDebtIncrease
    ) public {
        // This requires finding a zombie trove
        if (troveIds.length == 0) return;
        
        // Simply call adjustZombieTrove - the fuzzer will find zombie troves
        // through redemptions and other operations
        borrowerOperations_adjustZombieTrove_clamped(
            collChange,
            isCollIncrease,
            boldChange,
            isDebtIncrease,
            0, // upperHint
            0, // lowerHint
            type(uint256).max, // maxUpfrontFee
            entropy
        );
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

}
