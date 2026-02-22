// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {TargetFunctions} from "./TargetFunctions.sol";
import {CryticAsserts} from "@chimera/CryticAsserts.sol";
import {vm} from "@chimera/Hevm.sol";
import {ERC1820RegistryCompiled} from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";

// echidna . --contract CryticTester --config echidna.yaml --format text --workers 16 --test-limit 10000000 --test-mode exploration
// medusa fuzz
contract CryticTester is TargetFunctions, CryticAsserts {
    function _ensureERC1820() internal {
        if (ERC1820RegistryCompiled.at.code.length == 0) {
            try vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin) {}
            catch {}
        }

        require(
            ERC1820RegistryCompiled.at.code.length > 0,
            "ERC1820 registry missing"
        );
    }

    constructor() payable {
        _ensureERC1820();
        setup();
    }
}
