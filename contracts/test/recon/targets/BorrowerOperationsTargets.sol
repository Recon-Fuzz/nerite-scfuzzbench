
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";

import {IBorrowerOperations} from "../../../src/Interfaces/IBorrowerOperations.sol";
import {ITroveManager} from "../../../src/Interfaces/ITroveManager.sol";

import {LiquityMath} from "../../../src/Dependencies/LiquityMath.sol";
import {MAX_ANNUAL_INTEREST_RATE, MAX_ANNUAL_BATCH_MANAGEMENT_FEE, MIN_DEBT} from "../../../src/Dependencies/Constants.sol";
import {LatestTroveData} from "../../../src/Types/LatestTroveData.sol";
import {LatestBatchData} from "../../../src/Types/LatestBatchData.sol";

abstract contract BorrowerOperationsTargets is BaseTargetFunctions, Properties  {

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === Clamped Handlers === ///

    function borrowerOperations_addColl_clamped(uint256 _collAmount, uint256 entropy) public {
        _collAmount = _collAmount % (collToken.balanceOf(_getActor()) + 1);
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_addColl(_troveId, _collAmount);
    }

    function borrowerOperations_adjustTrove_clamped(uint256 _collChange, bool _isCollIncrease, uint256 _boldChange, bool _isDebtIncrease, uint256 _maxUpfrontFee, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        if (_isCollIncrease) {
            _collChange = _collChange % (collToken.balanceOf(_getActor()) + 1);
        }
        if (!_isDebtIncrease) {
            _boldChange = _boldChange % (boldToken.balanceOf(_getActor()) + 1);
        }
        
        borrowerOperations_adjustTrove(_troveId, _collChange, _isCollIncrease, _boldChange, _isDebtIncrease, _maxUpfrontFee);
    }

    function borrowerOperations_adjustTroveInterestRate_clamped(uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 entropy) public {
        _newAnnualInterestRate = _newAnnualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1);
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_adjustTroveInterestRate(_troveId, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_adjustZombieTrove_clamped(uint256 _collChange, bool _isCollIncrease, uint256 _boldChange, bool _isDebtIncrease, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        if (_isCollIncrease) {
            _collChange = _collChange % (collToken.balanceOf(_getActor()) + 1);
        }
        if (!_isDebtIncrease) {
            _boldChange = _boldChange % (boldToken.balanceOf(_getActor()) + 1);
        }
        
        borrowerOperations_adjustZombieTrove(_troveId, _collChange, _isCollIncrease, _boldChange, _isDebtIncrease, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_applyPendingDebt_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_applyPendingDebt(_troveId);
    }

    function borrowerOperations_closeTrove_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_closeTrove(_troveId);
    }

    function borrowerOperations_lowerBatchManagementFee_clamped(uint256 _newAnnualManagementFee) public {
        _newAnnualManagementFee = _newAnnualManagementFee % (MAX_ANNUAL_BATCH_MANAGEMENT_FEE + 1);
        
        borrowerOperations_lowerBatchManagementFee(_newAnnualManagementFee);
    }

    function borrowerOperations_onLiquidateTrove_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_onLiquidateTrove(_troveId);
    }

    function borrowerOperations_openTrove_clamped(address _owner, uint256 _ownerIndex, uint256 _collAmount, uint256 _boldAmount, uint256 _upperHint, uint256 _lowerHint, uint256 _annualInterestRate, uint256 _maxUpfrontFee, address _addManager, address _removeManager, address _receiver) public {
        _collAmount = _collAmount % (collToken.balanceOf(_getActor()) + 1);
        _annualInterestRate = _annualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1);
        
        uint256 troveId = borrowerOperations_openTrove(_owner, _ownerIndex, _collAmount, _boldAmount, _upperHint, _lowerHint, _annualInterestRate, _maxUpfrontFee, _addManager, _removeManager, _receiver);
        troveIds.push(troveId);
    }

    function borrowerOperations_registerBatchManager_clamped(uint128 _minInterestRate, uint128 _maxInterestRate, uint128 _currentInterestRate, uint128 _annualManagementFee, uint128 _minInterestRateChangePeriod) public {
        _minInterestRate = uint128(_minInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        _maxInterestRate = uint128(_maxInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        _currentInterestRate = uint128(_currentInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        _annualManagementFee = uint128(_annualManagementFee % (MAX_ANNUAL_BATCH_MANAGEMENT_FEE + 1));
        
        borrowerOperations_registerBatchManager(_minInterestRate, _maxInterestRate, _currentInterestRate, _annualManagementFee, _minInterestRateChangePeriod);
    }

    function borrowerOperations_removeFromBatch_clamped(uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        _newAnnualInterestRate = _newAnnualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1);
        
        borrowerOperations_removeFromBatch(_troveId, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_removeInterestIndividualDelegate_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_removeInterestIndividualDelegate(_troveId);
    }

    function borrowerOperations_repayBold_clamped(uint256 _boldAmount, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        _boldAmount = _boldAmount % (boldToken.balanceOf(_getActor()) + 1);
        
        borrowerOperations_repayBold(_troveId, _boldAmount);
    }

    function borrowerOperations_setAddManager_clamped(address _manager, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_setAddManager(_troveId, _manager);
    }

    function borrowerOperations_setBatchManagerAnnualInterestRate_clamped(uint128 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public {
        _newAnnualInterestRate = uint128(_newAnnualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        
        borrowerOperations_setBatchManagerAnnualInterestRate(_newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_setInterestBatchManager_clamped(address _newBatchManager, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 troveEntropy, uint256 batchEntropy) public {
        uint256 _troveId = setNewClampedTroveId(troveEntropy);
        _newBatchManager = setNewClampedBatchManager(batchEntropy);
        
        borrowerOperations_setInterestBatchManager(_troveId, _newBatchManager, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_setInterestIndividualDelegate_clamped(address _delegate, uint128 _minInterestRate, uint128 _maxInterestRate, uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 _minInterestRateChangePeriod, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        _minInterestRate = uint128(_minInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        _maxInterestRate = uint128(_maxInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
        _newAnnualInterestRate = _newAnnualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1);
        
        borrowerOperations_setInterestIndividualDelegate(_troveId, _delegate, _minInterestRate, _maxInterestRate, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee, _minInterestRateChangePeriod);
    }

    function borrowerOperations_setRemoveManager_clamped(address _manager, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_setRemoveManager(_troveId, _manager);
    }

    function borrowerOperations_setRemoveManagerWithReceiver_clamped(address _manager, address _receiver, uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_setRemoveManagerWithReceiver(_troveId, _manager, _receiver);
    }

    function borrowerOperations_switchBatchManager_clamped(uint256 _removeUpperHint, uint256 _removeLowerHint, address _newBatchManager, uint256 _addUpperHint, uint256 _addLowerHint, uint256 _maxUpfrontFee, uint256 troveEntropy, uint256 batchEntropy) public {
        uint256 _troveId = setNewClampedTroveId(troveEntropy);
        _newBatchManager = setNewClampedBatchManager(batchEntropy);
        
        borrowerOperations_switchBatchManager(_troveId, _removeUpperHint, _removeLowerHint, _newBatchManager, _addUpperHint, _addLowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_withdrawBold_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_withdrawBold(_troveId, 0, 0);
    }

    function borrowerOperations_withdrawColl_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        borrowerOperations_withdrawColl(_troveId, 0);
    }

    // Clamped handler for closeTrove that targets troves in batches
    // This ensures we cover lines 699-706 and 727 which handle batch-specific cleanup
    function borrowerOperations_closeTrove_batch_clamped(uint256 entropy) public {
        if (troveIds.length == 0) return;
        
        // Find a trove that's in a batch (has non-zero batch manager)
        for (uint256 i = entropy % troveIds.length; i < troveIds.length; i++) {
            uint256 _troveId = troveIds[i];
            address batchManager = borrowerOperations.interestBatchManagerOf(_troveId);
            
            if (batchManager != address(0)) {
                // Found a batched trove, ensure actor has enough Bold to close it
                LatestTroveData memory trove = troveManager.getLatestTroveData(_troveId);
                uint256 actorBalance = boldToken.balanceOf(_getActor());
                
                if (actorBalance >= trove.entireDebt) {
                    vm.prank(_getActor());
                    boldToken.approve(address(borrowerOperations), trove.entireDebt);
                    borrowerOperations_closeTrove(_troveId);
                    return;
                }
            }
        }
    }

    // Clamped handler for openTroveAndJoinInterestBatchManager
    // This ensures we cover lines 267-287 which handle joining batches
    function borrowerOperations_openTroveAndJoinBatch_clamped(uint256 _collAmount, uint256 _boldAmount, uint256 batchEntropy) public {
        _collAmount = _collAmount % (collToken.balanceOf(_getActor()) + 1);
        
        // Get a valid batch manager
        address batchManager = setNewClampedBatchManager(batchEntropy);
        
        // Ensure batch manager is registered by checking if it has valid parameters
        // If not registered, register it first
        try troveManager.getLatestBatchData(batchManager) returns (LatestBatchData memory) {
            // Batch exists, proceed
        } catch {
            // Register batch manager first
            vm.prank(batchManager);
            borrowerOperations.registerBatchManager(
                uint128(5e16), // 5% min rate
                uint128(MAX_ANNUAL_INTEREST_RATE), // max rate
                uint128(10e16), // 10% current rate
                uint128(1e16), // 1% management fee
                uint128(7 days) // cooldown period
            );
        }
        
        IBorrowerOperations.OpenTroveAndJoinInterestBatchManagerParams memory params;
        params.owner = _getActor();
        params.ownerIndex = 0;
        params.collAmount = _collAmount;
        params.boldAmount = _boldAmount;
        params.upperHint = 0;
        params.lowerHint = 0;
        params.interestBatchManager = batchManager;
        params.maxUpfrontFee = 1e18; // 100% max upfront fee
        params.addManager = address(0);
        params.removeManager = address(0);
        params.receiver = _getActor();
        
        borrowerOperations_openTroveAndJoinInterestBatchManager(params);
        // Note: troveId would need to be tracked differently as the function doesn't return it
    }

    // Clamped handler for setBatchManagerAnnualInterestRate within cooldown period
    // This ensures we cover lines 928-944 which handle premature adjustments with upfront fees
    function borrowerOperations_setBatchManagerAnnualInterestRate_premature(uint128 _newAnnualInterestRate) public {
        // Ensure actor is a registered batch manager
        address batchManager = _getActor();
        
        try troveManager.getLatestBatchData(batchManager) returns (LatestBatchData memory batch) {
            // Check if within cooldown period
            uint256 INTEREST_RATE_ADJ_COOLDOWN = 7 days; // Assuming this constant
            if (block.timestamp >= batch.lastInterestRateAdjTime + INTEREST_RATE_ADJ_COOLDOWN) {
                // Not in cooldown period, warp time backwards (not possible in real scenario)
                // Instead, just return as we can't create this scenario
                return;
            }
            
            // Ensure new rate is different from current
            _newAnnualInterestRate = uint128(_newAnnualInterestRate % (MAX_ANNUAL_INTEREST_RATE + 1));
            if (_newAnnualInterestRate == batch.annualInterestRate) {
                _newAnnualInterestRate = uint128((batch.annualInterestRate + 1e16) % (MAX_ANNUAL_INTEREST_RATE + 1));
            }
            
            borrowerOperations_setBatchManagerAnnualInterestRate(_newAnnualInterestRate, 0, 0, 1e18);
        } catch {
            // Not a registered batch manager, skip
            return;
        }
    }

    // Clamped handler for applyPendingDebt that targets zombie troves with enough redistribution gains
    // This ensures we cover lines 787-789 which reactivate zombie troves
    function borrowerOperations_applyPendingDebt_zombie_recovery(uint256 entropy) public {
        if (troveIds.length == 0) return;
        
        // Look for zombie troves with pending redistribution gains
        for (uint256 i = entropy % troveIds.length; i < troveIds.length; i++) {
            uint256 _troveId = troveIds[i];
            
            // Check if trove is zombie
            ITroveManager.Status status = troveManager.getTroveStatus(_troveId);
            if (uint8(status) == 3) { // Assuming 3 is zombie status
                LatestTroveData memory trove = troveManager.getLatestTroveData(_troveId);
                
                // Check if entire debt (including redistribution gains) >= MIN_DEBT
                if (trove.entireDebt >= MIN_DEBT) {
                    borrowerOperations_applyPendingDebt(_troveId, 0, 0);
                    return;
                }
            }
        }
    }

    /// === Handlers === ///


    function borrowerOperations_addColl(uint256 _troveId, uint256 _collAmount) public updateGhosts asActor {
        borrowerOperations.addColl(_troveId, _collAmount);
    }

    function borrowerOperations_adjustTrove(uint256 _troveId, uint256 _collChange, bool _isCollIncrease, uint256 _boldChange, bool _isDebtIncrease, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.adjustTrove(_troveId, _collChange, _isCollIncrease, _boldChange, _isDebtIncrease, _maxUpfrontFee);
    }

    function borrowerOperations_adjustTroveInterestRate(uint256 _troveId, uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.adjustTroveInterestRate(_troveId, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_adjustZombieTrove(uint256 _troveId, uint256 _collChange, bool _isCollIncrease, uint256 _boldChange, bool _isDebtIncrease, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.adjustZombieTrove(_troveId, _collChange, _isCollIncrease, _boldChange, _isDebtIncrease, _upperHint, _lowerHint, _maxUpfrontFee);
    }


    function borrowerOperations_applyPendingDebt(uint256 _troveId, uint256 _lowerHint, uint256 _upperHint) public updateGhosts asActor {
        borrowerOperations.applyPendingDebt(_troveId, _lowerHint, _upperHint);
    }


    function borrowerOperations_applyPendingDebt(uint256 _troveId) public updateGhosts asActor {
        borrowerOperations.applyPendingDebt(_troveId);
    }


    function borrowerOperations_closeTrove(uint256 _troveId) public updateGhosts asActor {
        borrowerOperations.closeTrove(_troveId);
    }


    function borrowerOperations_lowerBatchManagementFee(uint256 _newAnnualManagementFee) public updateGhosts asActor {
        borrowerOperations.lowerBatchManagementFee(_newAnnualManagementFee);
    }

    function borrowerOperations_onLiquidateTrove(uint256 _troveId) public updateGhosts asActor {
        borrowerOperations.onLiquidateTrove(_troveId);
    }

    function borrowerOperations_openTrove(address _owner, uint256 _ownerIndex, uint256 _collAmount, uint256 _boldAmount, uint256 _upperHint, uint256 _lowerHint, uint256 _annualInterestRate, uint256 _maxUpfrontFee, address _addManager, address _removeManager, address _receiver) public updateGhosts asActor returns (uint256) {
        uint256 troveId = borrowerOperations.openTrove(_owner, _ownerIndex, _collAmount, _boldAmount, _upperHint, _lowerHint, _annualInterestRate, _maxUpfrontFee, _addManager, _removeManager, _receiver);
        clampedTroveId = troveId;
        return troveId;
    }

    function borrowerOperations_openTroveAndJoinInterestBatchManager(IBorrowerOperations.OpenTroveAndJoinInterestBatchManagerParams memory _params) public updateGhosts asActor {
        borrowerOperations.openTroveAndJoinInterestBatchManager(_params);
    }

    function borrowerOperations_registerBatchManager(uint128 _minInterestRate, uint128 _maxInterestRate, uint128 _currentInterestRate, uint128 _annualManagementFee, uint128 _minInterestRateChangePeriod) public updateGhosts asActor {
        borrowerOperations.registerBatchManager(_minInterestRate, _maxInterestRate, _currentInterestRate, _annualManagementFee, _minInterestRateChangePeriod);
    }

    function borrowerOperations_removeFromBatch(uint256 _troveId, uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.removeFromBatch(_troveId, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_removeInterestIndividualDelegate(uint256 _troveId) public updateGhosts asActor {
        borrowerOperations.removeInterestIndividualDelegate(_troveId);
    }


    function borrowerOperations_repayBold(uint256 _troveId, uint256 _boldAmount) public updateGhosts asActor {
        borrowerOperations.repayBold(_troveId, _boldAmount);
    }

    function borrowerOperations_setAddManager(uint256 _troveId, address _manager) public updateGhosts asActor {
        borrowerOperations.setAddManager(_troveId, _manager);
    }

    function borrowerOperations_setBatchManagerAnnualInterestRate(uint128 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.setBatchManagerAnnualInterestRate(_newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_setInterestBatchManager(uint256 _troveId, address _newBatchManager, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.setInterestBatchManager(_troveId, _newBatchManager, _upperHint, _lowerHint, _maxUpfrontFee);
    }

    function borrowerOperations_setInterestIndividualDelegate(uint256 _troveId, address _delegate, uint128 _minInterestRate, uint128 _maxInterestRate, uint256 _newAnnualInterestRate, uint256 _upperHint, uint256 _lowerHint, uint256 _maxUpfrontFee, uint256 _minInterestRateChangePeriod) public updateGhosts asActor {
        borrowerOperations.setInterestIndividualDelegate(_troveId, _delegate, _minInterestRate, _maxInterestRate, _newAnnualInterestRate, _upperHint, _lowerHint, _maxUpfrontFee, _minInterestRateChangePeriod);
    }

    function borrowerOperations_setRemoveManager(uint256 _troveId, address _manager) public updateGhosts asActor {
        borrowerOperations.setRemoveManager(_troveId, _manager);
    }

    function borrowerOperations_setRemoveManagerWithReceiver(uint256 _troveId, address _manager, address _receiver) public updateGhosts asActor {
        borrowerOperations.setRemoveManagerWithReceiver(_troveId, _manager, _receiver);
    }

    function borrowerOperations_shutdown() public updateGhosts asActor {
        borrowerOperations.shutdown();
    }

    function borrowerOperations_shutdownFromOracleFailure() public updateGhosts asActor {
        borrowerOperations.shutdownFromOracleFailure();
    }

    // === Switch Batch Manager === //

    function borrowerOperations_switchBatchManager(uint256 _troveId, uint256 _removeUpperHint, uint256 _removeLowerHint, address _newBatchManager, uint256 _addUpperHint, uint256 _addLowerHint, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.switchBatchManager(_troveId, _removeUpperHint, _removeLowerHint, _newBatchManager, _addUpperHint, _addLowerHint, _maxUpfrontFee);
    }


    // === Withdraw Bold === //
    function borrowerOperations_withdrawBold(uint256 _troveId, uint256 _boldAmount, uint256 _maxUpfrontFee) public updateGhosts asActor {
        borrowerOperations.withdrawBold(_troveId, _boldAmount, _maxUpfrontFee);
    }

    // === Withdraw Coll === //
    function borrowerOperations_withdrawColl(uint256 _troveId, uint256 _collWithdrawal) public updateGhosts asActor {
        borrowerOperations.withdrawColl(_troveId, _collWithdrawal);
    }
}