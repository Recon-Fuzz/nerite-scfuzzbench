
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";

abstract contract StabilityPoolTargets is BaseTargetFunctions, Properties  {

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === Clamped Handlers === ///

    function stabilityPool_provideToSP_clamped(uint256 _topUp, bool _doClaim) public {
        _topUp = _topUp % (boldToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _topUp);
        
        stabilityPool_provideToSP(_topUp, _doClaim);
    }

    function stabilityPool_withdrawFromSP_clamped(uint256 _amount, bool _doClaim) public {
        _amount = _amount % (stabilityPool.getCompoundedBoldDeposit(_getActor()) + 1);
        
        stabilityPool_withdrawFromSP(_amount, _doClaim);
    }

    function stabilityPool_offset_clamped(uint256 _debtToOffset, uint256 _collToAdd) public {
        _debtToOffset = _debtToOffset % (stabilityPool.getTotalBoldDeposits() + 1);
        _collToAdd = _collToAdd % (collToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), _collToAdd);
        
        stabilityPool_offset(_debtToOffset, _collToAdd);
    }

    function stabilityPool_triggerBoldRewards_clamped(uint256 _boldYield) public {
        _boldYield = _boldYield % (boldToken.balanceOf(_getActor()) + 1);
        
        stabilityPool_triggerBoldRewards(_boldYield);
    }

    // Handler to do partial offset (not depleting the entire pool)
    // This helps cover the else branch in _computeCollRewardsPerUnitStaked (lines 454-461)
    function stabilityPool_offset_partial(uint256 _debtToOffset, uint256 _collToAdd) public {
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits == 0) return;
        
        // Clamp debt to offset to be at most 50% of total deposits
        // This ensures we don't deplete the entire pool
        _debtToOffset = _debtToOffset % (totalDeposits / 2 + 1);
        _collToAdd = _collToAdd % (collToken.balanceOf(_getActor()) + 1);
        
        // Approve
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), _collToAdd);
        
        // Call unclamped handler
        stabilityPool_offset(_debtToOffset, _collToAdd);
    }

    // Handler to create scenario for claimAllCollGains
    // User withdraws entire deposit but should have stashed collateral
    function stabilityPool_withdrawAll_and_claimLater(bool _doClaim) public {
        uint256 deposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (deposit == 0) return;
        
        // Withdraw entire deposit WITHOUT claiming gains (_doClaim = false)
        // This should leave stashed collateral for the user
        stabilityPool_withdrawFromSP(deposit, false);
        
        // Now try to claim all collateral gains (should hit lines 360, 362-363)
        stabilityPool_claimAllCollGains();
    }

    // Enhanced handler to ensure stashed collateral exists before claimAllCollGains
    // This creates the exact scenario needed to cover lines 360, 362-363
    function stabilityPool_setup_stashed_coll_and_claim(uint256 _depositAmount, uint256 _debtToOffset, uint256 _collToAdd) public {
        // Step 1: User deposits to SP
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Create an offset event so user gains collateral
        _debtToOffset = _debtToOffset % (stabilityPool.getTotalBoldDeposits() / 2 + 1); // Don't deplete pool
        _collToAdd = _collToAdd % (collToken.balanceOf(_getActor()) + 1);
        if (_collToAdd > 0 && _debtToOffset > 0) {
            vm.prank(_getActor());
            collToken.approve(address(stabilityPool), _collToAdd);
            stabilityPool_offset(_debtToOffset, _collToAdd);
        }
        
        // Step 3: Withdraw entire deposit WITHOUT claiming (_doClaim = false)
        // This creates stashed collateral
        uint256 deposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (deposit > 0) {
            stabilityPool_withdrawFromSP(deposit, false);
            
            // Step 4: Now claim all collateral gains
            // This should execute lines 360, 362-363 in claimAllCollGains
            uint256 stashedColl = stabilityPool.stashedColl(_getActor());
            if (stashedColl > 0) {
                stabilityPool_claimAllCollGains();
            }
        }
    }

    // Handler to do very large offset to trigger scale changes
    // This helps cover scale-related branches in _updateCollRewardSumAndProduct and _getCompoundedStakeFromSnapshots
    function stabilityPool_offset_large(uint256 _debtToOffset, uint256 _collToAdd) public {
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits == 0) return;
        
        // Clamp debt to offset to be between 80-100% of total deposits
        // This increases likelihood of triggering scale changes
        uint256 minOffset = (totalDeposits * 80) / 100;
        _debtToOffset = minOffset + (_debtToOffset % (totalDeposits - minOffset + 1));
        _collToAdd = _collToAdd % (collToken.balanceOf(_getActor()) + 1);
        
        // Approve
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), _collToAdd);
        
        // Call unclamped handler
        stabilityPool_offset(_debtToOffset, _collToAdd);
    }

    // Handler to trigger multiple consecutive large offsets to force scale changes
    // Scale changes occur when P < SCALE_FACTOR (1e9)
    // This requires multiple large offsets in succession
    function stabilityPool_offset_massive_sequential(uint256 _debtToOffset1, uint256 _collToAdd1, uint256 _debtToOffset2, uint256 _collToAdd2) public {
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits == 0) return;
        
        // First offset: 90-99% of total deposits
        uint256 minOffset1 = (totalDeposits * 90) / 100;
        _debtToOffset1 = minOffset1 + (_debtToOffset1 % (totalDeposits - minOffset1 + 1));
        _collToAdd1 = _collToAdd1 % (collToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), _collToAdd1);
        stabilityPool_offset(_debtToOffset1, _collToAdd1);
        
        // Second offset: another large offset on remaining deposits
        totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 minOffset2 = (totalDeposits * 90) / 100;
            _debtToOffset2 = minOffset2 + (_debtToOffset2 % (totalDeposits - minOffset2 + 1));
            _collToAdd2 = _collToAdd2 % (collToken.balanceOf(_getActor()) + 1);
            
            vm.prank(_getActor());
            collToken.approve(address(stabilityPool), _collToAdd2);
            stabilityPool_offset(_debtToOffset2, _collToAdd2);
        }
    }

    // Handler specifically designed to trigger scaleDiff == 1 in _getCompoundedStakeFromSnapshots
    // This requires:
    // 1. User makes a deposit (creates snapshot with current scale)
    // 2. Large offset occurs that changes the scale
    // 3. User withdraws (computes compounded stake with scaleDiff == 1)
    function stabilityPool_deposit_offset_withdraw_sequence(uint256 _depositAmount, uint256 _debtToOffset, uint256 _collToAdd) public {
        // Step 1: User makes a deposit
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Perform massive offset to trigger scale change
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            // Offset 95-99% of deposits to maximize chance of scale change
            uint256 minOffset = (totalDeposits * 95) / 100;
            _debtToOffset = minOffset + (_debtToOffset % (totalDeposits - minOffset + 1));
            _collToAdd = _collToAdd % (collToken.balanceOf(_getActor()) + 1);
            
            vm.prank(_getActor());
            collToken.approve(address(stabilityPool), _collToAdd);
            stabilityPool_offset(_debtToOffset, _collToAdd);
        }
        
        // Step 3: Withdraw (this triggers _getCompoundedStakeFromSnapshots with potentially different scale)
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Enhanced handler to more aggressively trigger scale changes
    // Scale changes occur when P < SCALE_FACTOR (1e9)
    // P is reduced by factor (1 - debtToOffset/totalDeposits) in each offset
    // To drop P below 1e9 (from 1e18), we need product of factors < 1e-9
    // This requires multiple very large offsets, or near-complete pool depletion
    function stabilityPool_trigger_scale_change_aggressive(uint256 _depositAmount, uint256 _numOffsets) public {
        // Step 1: User makes a deposit
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Perform multiple consecutive near-complete offsets
        // Each offset should consume ~99.9% of remaining deposits
        _numOffsets = (_numOffsets % 5) + 1; // 1-5 offsets
        
        for (uint256 i = 0; i < _numOffsets; i++) {
            uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
            if (totalDeposits == 0) break;
            
            // Offset 99.9% of deposits
            uint256 debtToOffset = (totalDeposits * 999) / 1000;
            if (debtToOffset == 0) break;
            
            // Use minimal collateral to avoid running out
            uint256 collToAdd = 1 ether;
            if (collToken.balanceOf(_getActor()) < collToAdd) break;
            
            vm.prank(_getActor());
            collToken.approve(address(stabilityPool), collToAdd);
            stabilityPool_offset(debtToOffset, collToAdd);
        }
        
        // Step 3: Withdraw to trigger _getCompoundedStakeFromSnapshots
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Handler to trigger double scale change (scaleDiff >= 2)
    // This requires even more aggressive depletion
    // The code should return 0 for compoundedStake when scaleDiff >= 2
    function stabilityPool_trigger_double_scale_change(uint256 _depositAmount) public {
        // Step 1: User makes a deposit
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Perform extreme offsets to trigger multiple scale changes
        // We need P to drop by factor of 1e-18 or more
        // This requires offsetting essentially 100% multiple times
        for (uint256 i = 0; i < 10; i++) {
            uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
            if (totalDeposits == 0) break;
            
            // Offset 99.99% of deposits
            uint256 debtToOffset = (totalDeposits * 9999) / 10000;
            if (debtToOffset == 0) break;
            
            uint256 collToAdd = 1 ether;
            if (collToken.balanceOf(_getActor()) < collToAdd) break;
            
            vm.prank(_getActor());
            collToken.approve(address(stabilityPool), collToAdd);
            stabilityPool_offset(debtToOffset, collToAdd);
        }
        
        // Step 3: Withdraw to trigger _getCompoundedStakeFromSnapshots
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Ultra-aggressive handler to trigger single scale change (scaleDiff == 1)
    // To cross scale boundary: P must drop from 1e18 to below 1e9
    // This requires offsetting > 99.9999999% (1 - 1e-9) of the pool
    function stabilityPool_trigger_single_scale_ultra(uint256 _depositAmount, uint256 _offsetPercentage) public {
        // Step 1: Make a deposit
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Offset extremely close to 100% in a SINGLE offset
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits == 0) return;
        
        // Clamp percentage to be between 99.999999% and 99.9999999%
        // This is the range most likely to trigger exactly one scale change
        uint256 minPercentage = 999999990; // 99.999999%
        uint256 maxPercentage = 999999999; // 99.9999999%
        _offsetPercentage = minPercentage + (_offsetPercentage % (maxPercentage - minPercentage + 1));
        
        uint256 debtToOffset = (totalDeposits * _offsetPercentage) / 1000000000;
        if (debtToOffset == 0) return;
        
        uint256 collToAdd = _depositAmount / 10; // Use 10% of deposit as collateral
        if (collToken.balanceOf(_getActor()) < collToAdd) collToAdd = collToken.balanceOf(_getActor());
        if (collToAdd == 0) return;
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), collToAdd);
        stabilityPool_offset(debtToOffset, collToAdd);
        
        // Step 3: Withdraw to trigger _getCompoundedStakeFromSnapshots with scaleDiff == 1
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Handler specifically designed to trigger the errorFactor calculation (line 566)
    // and the scale change branches (lines 523-527, 530, 535-540, 542)
    function stabilityPool_trigger_scale_with_error_tracking(uint256 _depositAmount1, uint256 _depositAmount2, uint256 _offsetPercentage) public {
        // Step 1: First actor makes a deposit
        _depositAmount1 = _depositAmount1 % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount1 == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount1);
        stabilityPool_provideToSP(_depositAmount1, false);
        
        // Step 2: Do a partial offset to build up error tracking
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 debtToOffset1 = totalDeposits / 3; // Offset 33%
            uint256 collToAdd1 = _depositAmount1 / 10;
            if (collToken.balanceOf(_getActor()) >= collToAdd1 && debtToOffset1 > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd1);
                stabilityPool_offset(debtToOffset1, collToAdd1);
            }
        }
        
        // Step 3: Another actor makes a large deposit
        _depositAmount2 = _depositAmount2 % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount2 > 0) {
            vm.prank(_getActor());
            boldToken.approve(address(stabilityPool), _depositAmount2);
            stabilityPool_provideToSP(_depositAmount2, false);
        }
        
        // Step 4: Now do an ultra-aggressive offset to trigger scale change
        // with error tracking in place (lastBoldLossErrorByP_Offset > 0)
        totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            // Clamp to 99.9999999% range
            uint256 minPercentage = 999999000; // 99.9999%
            uint256 maxPercentage = 999999999; // 99.9999999%
            _offsetPercentage = minPercentage + (_offsetPercentage % (maxPercentage - minPercentage + 1));
            
            uint256 debtToOffset = (totalDeposits * _offsetPercentage) / 1000000000;
            if (debtToOffset > 0) {
                uint256 collToAdd = totalDeposits / 100; // 1% as collateral
                if (collToken.balanceOf(_getActor()) < collToAdd) collToAdd = collToken.balanceOf(_getActor());
                if (collToAdd > 0) {
                    vm.prank(_getActor());
                    collToken.approve(address(stabilityPool), collToAdd);
                    stabilityPool_offset(debtToOffset, collToAdd);
                }
            }
        }
        
        // Step 5: Withdraw to trigger _getCompoundedStakeFromSnapshots
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Simplified ultra-aggressive handler for double scale change
    // To trigger scaleDiff >= 2, we need P to drop below SCALE_FACTOR twice
    function stabilityPool_trigger_double_scale_ultra(uint256 _depositAmount) public {
        // Step 1: Make a deposit
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount == 0) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 2: Single ultra-massive offset to cross TWO scale boundaries
        // To cross 2 boundaries: P must drop from 1e18 to below 1e0 (essentially to 0)
        // This requires offsetting > 99.99999999999999999% of the pool
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits == 0) return;
        
        // Offset 99.99999999999999% (leave only 1 wei essentially)
        uint256 debtToOffset = totalDeposits - 1;
        if (debtToOffset == 0) return;
        
        uint256 collToAdd = _depositAmount / 10;
        if (collToken.balanceOf(_getActor()) < collToAdd) collToAdd = collToken.balanceOf(_getActor());
        if (collToAdd == 0) return;
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), collToAdd);
        stabilityPool_offset(debtToOffset, collToAdd);
        
        // Step 3: Withdraw to trigger _getCompoundedStakeFromSnapshots with scaleDiff >= 2
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Mathematical approach to trigger single scale change (line 732)
    // P starts at 1e18 (DECIMAL_PRECISION)
    // SCALE_FACTOR = 1e9
    // To trigger: newP < SCALE_FACTOR means we need P to drop below 1e9
    // P_new = P_old * (1 - debtToOffset/totalDeposits)
    // So: 1e18 * (1 - x) < 1e9 => (1 - x) < 1e-9 => x > 0.999999999
    function stabilityPool_precise_single_scale(uint256 _depositAmount) public {
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount < 1e20) return; // Need large enough deposit for precision
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits < 1e20) return;
        
        // Calculate precise offset: leave exactly (totalDeposits / 1e10) remaining
        // This ensures P drops to approximately 1e8 (just below SCALE_FACTOR)
        uint256 remaining = totalDeposits / 1e10;
        if (remaining == 0) remaining = 1;
        uint256 debtToOffset = totalDeposits - remaining;
        
        uint256 collToAdd = totalDeposits / 100;
        if (collToken.balanceOf(_getActor()) < collToAdd) return;
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), collToAdd);
        stabilityPool_offset(debtToOffset, collToAdd);
        
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Multi-step approach for double scale change (line 735, scaleDiff >= 2)
    // Need P to drop by factor of 1e18 total (two scale boundaries)
    // Do this in multiple controlled steps
    function stabilityPool_multi_step_double_scale(uint256 _depositAmount) public {
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount < 1e21) return; // Need very large deposit
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // First scale change: reduce P from 1e18 to ~1e8
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 remaining1 = totalDeposits / 1e10;
            if (remaining1 == 0) remaining1 = 1;
            uint256 debtToOffset1 = totalDeposits - remaining1;
            
            uint256 collToAdd1 = totalDeposits / 100;
            if (collToken.balanceOf(_getActor()) >= collToAdd1 && debtToOffset1 > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd1);
                stabilityPool_offset(debtToOffset1, collToAdd1);
            }
        }
        
        // Second scale change: reduce P from ~1e8 to below 1e-1
        totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 remaining2 = totalDeposits / 1e10;
            if (remaining2 == 0) remaining2 = 1;
            uint256 debtToOffset2 = totalDeposits - remaining2;
            
            uint256 collToAdd2 = totalDeposits / 10;
            if (collToken.balanceOf(_getActor()) >= collToAdd2 && debtToOffset2 > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd2);
                stabilityPool_offset(debtToOffset2, collToAdd2);
            }
        }
        
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Handler to ensure error tracking is active before scale changes (line 566)
    // lastBoldLossErrorByP_Offset is set in _updateCollRewardSumAndProduct (line 548)
    // It becomes > 0 when there's rounding error from previous offsets
    function stabilityPool_build_error_then_scale(uint256 _depositAmount) public {
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount < 1e20) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        // Step 1: Small offset to create error accumulation
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 smallOffset = totalDeposits / 7; // ~14% offset creates error
            uint256 collToAdd1 = smallOffset / 10;
            if (collToken.balanceOf(_getActor()) >= collToAdd1 && smallOffset > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd1);
                stabilityPool_offset(smallOffset, collToAdd1);
            }
        }
        
        // Step 2: Another small offset to further build error
        totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 smallOffset2 = totalDeposits / 5;
            uint256 collToAdd2 = smallOffset2 / 10;
            if (collToken.balanceOf(_getActor()) >= collToAdd2 && smallOffset2 > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd2);
                stabilityPool_offset(smallOffset2, collToAdd2);
            }
        }
        
        // Step 3: Now trigger scale change with error tracking active
        totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits > 0) {
            uint256 remaining = totalDeposits / 1e10;
            if (remaining == 0) remaining = 1;
            uint256 largeOffset = totalDeposits - remaining;
            
            uint256 collToAdd3 = totalDeposits / 50;
            if (collToken.balanceOf(_getActor()) >= collToAdd3 && largeOffset > 0) {
                vm.prank(_getActor());
                collToken.approve(address(stabilityPool), collToAdd3);
                stabilityPool_offset(largeOffset, collToAdd3);
            }
        }
        
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    // Handler to trigger the second scale increment check (lines 534-542)
    // This happens when newP is still < SCALE_FACTOR after first scale increment
    // Need a very specific offset amount that lands P between 1e0 and 1e9 after scaling
    function stabilityPool_trigger_second_scale_increment(uint256 _depositAmount) public {
        _depositAmount = _depositAmount % (boldToken.balanceOf(_getActor()) + 1);
        if (_depositAmount < 1e21) return;
        
        vm.prank(_getActor());
        boldToken.approve(address(stabilityPool), _depositAmount);
        stabilityPool_provideToSP(_depositAmount, false);
        
        uint256 totalDeposits = stabilityPool.getTotalBoldDeposits();
        if (totalDeposits < 1e21) return;
        
        // Calculate offset to make P drop to ~1e4 (well below SCALE_FACTOR but not zero)
        // This should trigger line 522 (newP < SCALE_FACTOR) 
        // Then potentially line 534 (still < SCALE_FACTOR after first increment)
        uint256 remaining = totalDeposits / 1e14; // Leave very little
        if (remaining == 0) remaining = 1;
        uint256 debtToOffset = totalDeposits - remaining;
        
        uint256 collToAdd = totalDeposits / 50;
        if (collToken.balanceOf(_getActor()) < collToAdd) return;
        
        vm.prank(_getActor());
        collToken.approve(address(stabilityPool), collToAdd);
        stabilityPool_offset(debtToOffset, collToAdd);
        
        uint256 compoundedDeposit = stabilityPool.getCompoundedBoldDeposit(_getActor());
        if (compoundedDeposit > 0) {
            stabilityPool_withdrawFromSP(compoundedDeposit, true);
        }
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function stabilityPool_claimAllCollGains() public updateGhosts asActor {
        stabilityPool.claimAllCollGains();
    }


    function stabilityPool_provideToSP(uint256 _topUp, bool _doClaim) public updateGhosts asActor {
        stabilityPool.provideToSP(_topUp, _doClaim);
    }

    function stabilityPool_withdrawFromSP(uint256 _amount, bool _doClaim) public updateGhosts asActor {
        stabilityPool.withdrawFromSP(_amount, _doClaim);
    }

    function stabilityPool_offset(uint256 _debtToOffset, uint256 _collToAdd) public updateGhosts asActor {
        stabilityPool.offset(_debtToOffset, _collToAdd);
    }

    function stabilityPool_triggerBoldRewards(uint256 _boldYield) public updateGhosts asActor {
        stabilityPool.triggerBoldRewards(_boldYield);
    }

}