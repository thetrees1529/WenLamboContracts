// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Token.sol";

contract Migrator is AccessControl {
    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(address => bool) public migrated;

    Token public token;

    constructor(Token token_) {token = token_;}

    function migrate(address addr, uint amount) external onlyRole(MIGRATOR_ROLE) {
        require(!migrated[addr], "Already migrated");
        migrated[addr] = true;
        token.mintTo(addr, amount);
    }
}


