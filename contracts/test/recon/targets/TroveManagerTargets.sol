
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console2.sol";

import {Properties} from "../Properties.sol";

abstract contract TroveManagerTargets is BaseTargetFunctions, Properties  {

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// === Clamped Handlers === ///

    function troveManager_batchLiquidateTroves_clamped() public {
        // Use the troveIds array from Setup
        troveManager_batchLiquidateTroves(troveIds);
    }

    function troveManager_liquidate_clamped(uint256 entropy) public {
        uint256 _troveId = setNewClampedTroveId(entropy);
        
        troveManager_liquidate(_troveId);
    }

    function troveManager_urgentRedemption_clamped(uint256 _boldAmount, uint256 _minCollateral) public {
        _boldAmount = _boldAmount % (boldToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        boldToken.approve(address(troveManager), _boldAmount);
        
        // Use the troveIds array from Setup
        troveManager_urgentRedemption(_boldAmount, troveIds, _minCollateral);
    }

    // Handler to trigger batch liquidations that generate collateral surplus (line 440)
    // This requires liquidating troves in recovery mode that have high collateralization
    function troveManager_batchLiquidateTroves_with_surplus() public {
        if (troveIds.length == 0) return;
        
        // Check if system is in recovery mode (TCR < CCR)
        uint256 price = priceFeed.getPrice();
        uint256 TCR = troveManager.getTCR(price);
        uint256 CCR = 150e16; // Assuming 150% CCR
        
        if (TCR >= CCR) {
            // Not in recovery mode, can't generate surplus from liquidations
            return;
        }
        
        // In recovery mode, liquidate troves
        // Troves with CR >= CCR will generate surplus collateral
        troveManager_batchLiquidateTroves(troveIds);
    }

    // Handler to trigger system shutdown and enable urgent redemptions
    // This covers lines 850-903 in urgentRedemption function
    function troveManager_trigger_shutdown_and_urgent_redeem(uint256 _boldAmount) public {
        // First, trigger shutdown (can be called by BorrowerOperations)
        // We need to impersonate the BorrowerOperations contract
        vm.prank(address(borrowerOperations));
        troveManager.shutdown();
        
        // Now that system is shut down, urgent redemptions should work
        _boldAmount = _boldAmount % (boldToken.balanceOf(_getActor()) + 1);
        
        vm.prank(_getActor());
        boldToken.approve(address(troveManager), _boldAmount);
        
        troveManager_urgentRedemption(_boldAmount, troveIds, 0);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function troveManager_batchLiquidateTroves(uint256[] memory _troveArray) public updateGhosts asActor {
        troveManager.batchLiquidateTroves(_troveArray);
    }


    function troveManager_liquidate(uint256 _troveId) public updateGhosts asActor {
        troveManager.liquidate(_troveId);
        hasDoneLiquidation = true;
    }


    function troveManager_urgentRedemption(uint256 _boldAmount, uint256[] memory _troveIds, uint256 _minCollateral) public updateGhosts asActor {
        troveManager.urgentRedemption(_boldAmount, _troveIds, _minCollateral);
    }
    

    // function troveManager_callInternalRemoveTroveId(uint256 _troveId) public updateGhosts asActor {
    //     troveManager.callInternalRemoveTroveId(_troveId);
    // }

    // function troveManager_getUnbackedPortionPriceAndRedeemability() public updateGhosts asActor {
    //     troveManager.getUnbackedPortionPriceAndRedeemability();
    // }


    // function troveManager_onAdjustTrove(uint256 _troveId, uint256 _newColl, uint256 _newDebt, TroveChange memory _troveChange) public updateGhosts asActor {
    //     troveManager.onAdjustTrove(_troveId, _newColl, _newDebt, _troveChange);
    // }

    // function troveManager_onAdjustTroveInsideBatch(uint256 _troveId, uint256 _newTroveColl, uint256 _newTroveDebt, TroveChange memory _troveChange, address _batchAddress, uint256 _newBatchColl, uint256 _newBatchDebt) public updateGhosts asActor {
    //     troveManager.onAdjustTroveInsideBatch(_troveId, _newTroveColl, _newTroveDebt, _troveChange, _batchAddress, _newBatchColl, _newBatchDebt);
    // }

    // function troveManager_onAdjustTroveInterestRate(uint256 _troveId, uint256 _newColl, uint256 _newDebt, uint256 _newAnnualInterestRate, TroveChange memory _troveChange) public updateGhosts asActor {
    //     troveManager.onAdjustTroveInterestRate(_troveId, _newColl, _newDebt, _newAnnualInterestRate, _troveChange);
    // }

    // function troveManager_onApplyTroveInterest(uint256 _troveId, uint256 _newTroveColl, uint256 _newTroveDebt, address _batchAddress, uint256 _newBatchColl, uint256 _newBatchDebt, TroveChange memory _troveChange) public updateGhosts asActor {
    //     troveManager.onApplyTroveInterest(_troveId, _newTroveColl, _newTroveDebt, _batchAddress, _newBatchColl, _newBatchDebt, _troveChange);
    // }

    // function troveManager_onCloseTrove(uint256 _troveId, TroveChange memory _troveChange, address _batchAddress, uint256 _newBatchColl, uint256 _newBatchDebt) public updateGhosts asActor {
    //     troveManager.onCloseTrove(_troveId, _troveChange, _batchAddress, _newBatchColl, _newBatchDebt);
    // }

    // function troveManager_onLowerBatchManagerAnnualFee(address _batchAddress, uint256 _newColl, uint256 _newDebt, uint256 _newAnnualManagementFee) public updateGhosts asActor {
    //     troveManager.onLowerBatchManagerAnnualFee(_batchAddress, _newColl, _newDebt, _newAnnualManagementFee);
    // }

    // function troveManager_onOpenTrove(address _owner, uint256 _troveId, TroveChange memory _troveChange, uint256 _annualInterestRate) public updateGhosts asActor {
    //     troveManager.onOpenTrove(_owner, _troveId, _troveChange, _annualInterestRate);
    // }

    // function troveManager_onOpenTroveAndJoinBatch(address _owner, uint256 _troveId, TroveChange memory _troveChange, address _batchAddress, uint256 _batchColl, uint256 _batchDebt) public updateGhosts asActor {
    //     troveManager.onOpenTroveAndJoinBatch(_owner, _troveId, _troveChange, _batchAddress, _batchColl, _batchDebt);
    // }

    // function troveManager_onRegisterBatchManager(address _account, uint256 _annualInterestRate, uint256 _annualManagementFee) public updateGhosts asActor {
    //     troveManager.onRegisterBatchManager(_account, _annualInterestRate, _annualManagementFee);
    // }

    // function troveManager_onRemoveFromBatch(uint256 _troveId, uint256 _newTroveColl, uint256 _newTroveDebt, TroveChange memory _troveChange, address _batchAddress, uint256 _newBatchColl, uint256 _newBatchDebt, uint256 _newAnnualInterestRate) public updateGhosts asActor {
    //     troveManager.onRemoveFromBatch(_troveId, _newTroveColl, _newTroveDebt, _troveChange, _batchAddress, _newBatchColl, _newBatchDebt, _newAnnualInterestRate);
    // }

    // function troveManager_onSetBatchManagerAnnualInterestRate(address _batchAddress, uint256 _newColl, uint256 _newDebt, uint256 _newAnnualInterestRate, uint256 _upfrontFee) public updateGhosts asActor {
    //     troveManager.onSetBatchManagerAnnualInterestRate(_batchAddress, _newColl, _newDebt, _newAnnualInterestRate, _upfrontFee);
    // }

    // function troveManager_onSetInterestBatchManager(ITroveManager.OnSetInterestBatchManagerParams memory _params) public updateGhosts asActor {
    //     troveManager.onSetInterestBatchManager(_params);
    // }

    // function troveManager_redeemCollateral(address _redeemer, uint256 _boldamount, uint256 _price, uint256 _redemptionRate, uint256 _maxIterations) public updateGhosts asActor {
    //     troveManager.redeemCollateral(_redeemer, _boldamount, _price, _redemptionRate, _maxIterations);
    // }

    // function troveManager_setTroveStatusToActive(uint256 _troveId) public updateGhosts asActor {
    //     troveManager.setTroveStatusToActive(_troveId);
    // }

    // function troveManager_shutdown() public updateGhosts asActor {
    //     troveManager.shutdown();
    // }


}