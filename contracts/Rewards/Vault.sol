//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is AccessControl {
    bytes32 public VAULT_ROLE = keccak256("VAULT_ROLE");
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function withdraw(IERC20 token, address to, uint amount) external onlyRole(VAULT_ROLE) {
        token.transfer(to, amount);
    }
}