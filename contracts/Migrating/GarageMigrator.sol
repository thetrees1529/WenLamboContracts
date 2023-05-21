// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Game/Earn.sol";

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
            uint tokenId = i;

            Earn.NfvView memory nfv = source.getInformation(tokenId);
            if(nfv.onStages) {
                target.setLocation(tokenId, nfv.location);
            }
            
            target.addToClaimable(tokenId, nfv.claimable);
            target.addToLocked(tokenId, nfv.locked);
            target.addToInterest(tokenId, nfv.interestable);
            
        }
        checkPoint += numberOf;
    }
}