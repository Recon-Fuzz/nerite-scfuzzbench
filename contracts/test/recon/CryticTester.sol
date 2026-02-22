// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {TargetFunctions} from "./TargetFunctions.sol";
import {CryticAsserts} from "@chimera/CryticAsserts.sol";
import {ERC1820RegistryCompiled} from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";

// echidna . --contract CryticTester --config echidna.yaml --format text --workers 16 --test-limit 10000000 --test-mode exploration
// medusa fuzz
contract ERC1820RegistryRuntime {
    constructor() {
        bytes memory runtime = ERC1820RegistryCompiled.bin;
        assembly {
            return(add(runtime, 0x20), mload(runtime))
        }
    }
}

contract CryticTester is TargetFunctions, CryticAsserts {
    function _requireERC1820() internal view {
        require(ERC1820RegistryCompiled.at.code.length > 0, "ERC1820 registry missing");
    }

    constructor() payable {
        _requireERC1820();
        setup();
    }
}
