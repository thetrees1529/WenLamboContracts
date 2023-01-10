// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Earn.sol";

contract GarageMigrator is AccessControl {

    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    uint public checkPoint = 0;

    Earn public source;
    Earn public target;
    constructor(Earn source_, Earn target_) {
        source = source_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MIGRATOR_ROLE, msg.sender);
    }
    function migrate(uint numberOf) external onlyRole(MIGRATOR_ROLE) {
        uint end = checkPoint + numberOf;
        for(uint i = checkPoint; i < end; i ++) {
            uint tokenId = i + checkPoint - 1;

            Earn.Location memory location = source.getLocation(tokenId);
            uint claimable = source.getClaimable(tokenId);
            uint locked = source.getLocked(tokenId);
            uint interest = source.getInterest(tokenId);

            target.setLocation(tokenId, location);
            target.addToClaimable(tokenId, claimable);
            target.addToLocked(tokenId, locked);
            target.addToInterest(tokenId, interest);
            
        }
        checkpoint += numberOf;
    }
}