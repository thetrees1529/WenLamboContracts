// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Game/Earn.sol";

contract LockedBoost is AccessControl {

    bytes32 public SLASH_ROLE = keccak256("SLASH_ROLE");

    uint public checkPoint = 0;

    Earn public target;

    uint public numerator;
    uint public denominator;
    constructor(Earn target_, uint numerator_, uint denominator_) {
        numerator = numerator_;
        denominator = denominator_;
        target = target_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SLASH_ROLE, msg.sender);
    }
    function slash(uint numberOf) external onlyRole(SLASH_ROLE) {
        uint end = checkPoint + numberOf;
        for(uint i = checkPoint; i < end; i ++) {
            uint tokenId = i;
            (,,,uint pendingClaim,,,,,,) = target.nfvInfo(tokenId);
                uint toAdd = (pendingClaim * denominator) / numerator;
                target.addToLocked(tokenId, toAdd);    
            

        }
        checkPoint += numberOf;
    }
}