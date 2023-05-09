// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Token/Token.sol";

contract Migrator is AccessControl {
    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(address => bool) public migrated;

    Token public token;

    Migrator[] links;

    constructor(Token token_, Migrator[] memory links_) {
        token = token_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        links = links_;
    }

    struct MigrateInput {
        address addr;
        uint amount;
    }

    function migrate(MigrateInput memory input) public onlyRole(MIGRATOR_ROLE) {
        if(migrated[input.addr] || _check(input.addr)) return;
        migrated[input.addr] = true;
        token.mintTo(input.addr, input.amount);
    }

    function _check(address addr) private view returns(bool) {
        for(uint i; i < links.length; i ++) {
            if(links[i].migrated(addr)) return true;
        }
        return false;
    }

    function migrateMultiple(MigrateInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) migrate(inputs[i]);
    }

}


