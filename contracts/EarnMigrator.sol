// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Earn.sol";

contract EarnMigrator {
    using Fees for uint;
    Earn public source;
    Earn public dest;

    mapping(uint => bool) public done;

    constructor(Earn source_, Earn dest_) {
        source = source_;
        dest = dest_;
    }

    function migrate(uint tokenId) external {
        require(!done[tokenId], "Already done.");
        done[tokenId] = true;
        uint unlockedClaimable = source.getUnlockedClaimable(tokenId);
        uint locked = source.getLocked(tokenId);
        uint interest = source.getInterest(tokenId);
        if(source.isInLocation(tokenId)) {
            dest.setLocation(tokenId, source.getLocation(tokenId));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}