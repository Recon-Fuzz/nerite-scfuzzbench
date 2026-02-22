// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {Asserts} from "@chimera/Asserts.sol";
import "forge-std/console2.sol";

import {ERC1820RegistryCompiled} from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    mapping(string => bool) private assertionFailures;

    function setUp() public {
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin); // TODO: Deploy at a new address

        setup();

        targetContract(address(this));
        targetSender(address(0x10000));
        targetSender(address(0x20000));
        targetSender(address(0x30000));
    }

    function _isAssertion(string memory reason) internal pure returns (bool) {
        bytes memory reasonBytes = bytes(reason);
        return
            reasonBytes.length >= 3
            && reasonBytes[0] == '!'
            && reasonBytes[1] == '!'
            && reasonBytes[2] == '!';
    }

    function gt(uint256 a, uint256 b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(a > b, reason);
        } else {
            super.gt(a, b, reason);
        }
    }

    function gte(uint256 a, uint256 b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(a >= b, reason);
        } else {
            super.gte(a, b, reason);
        }
    }

    function lt(uint256 a, uint256 b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(a < b, reason);
        } else {
            super.lt(a, b, reason);
        }
    }

    function lte(uint256 a, uint256 b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(a <= b, reason);
        } else {
            super.lte(a, b, reason);
        }
    }

    function eq(uint256 a, uint256 b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(a == b, reason);
        } else {
            super.eq(a, b, reason);
        }
    }

    function t(bool b, string memory reason)
        internal
        virtual
        override(FoundryAsserts, Asserts)
    {
        if (_isAssertion(reason)) {
            _recordAssertion(b, reason);
        } else {
            super.t(b, reason);
        }
    }

    function _recordAssertion(bool ok, string memory reason) internal {
        if (ok) {
            return;
        }

        assertionFailures[reason] = true;
    }

    function invariant_assertion_failure_CANARY() public override returns (bool) {
        t(false, ASSERTION_CANARY);
        assertTrue(!assertionFailures[ASSERTION_CANARY], ASSERTION_CANARY);
        return true;
    }
}
