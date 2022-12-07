// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Token.sol";

contract Migrator is AccessControl {
    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(address => bool) public migrated;

    Token public token;

    constructor(Token token_) {token = token_;_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);}

    struct MigrateInput {
        address addr;
        uint amount;
    }

    function migrate(MigrateInput memory input) public onlyRole(MIGRATOR_ROLE) {
        if(migrated[input.addr] || token.balanceOf(input.addr) > 0) return;
        migrated[input.addr] = true;
        token.mintTo(input.addr, input.amount);
    }

    function migrateMultiple(MigrateInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) migrate(inputs[i]);
    }

}


