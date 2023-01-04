// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Earn.sol";

contract GarageMigrator is AccessControl {

    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(uint => bool) public migrated;

    Earn public source;
    Earn public target;

    constructor(Earn source_, Earn target_) {
        source = source_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MIGRATOR_ROLE, msg.sender);
    }

    function migrate(uint start, uint end) external onlyRole(MIGRATOR_ROLE) {
    }

    

}