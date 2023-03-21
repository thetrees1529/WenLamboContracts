// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Earn.sol";

contract EarnMigrator {
    Earn public source;
    Earn public dest;
    uint public divisor;

    mapping(uint => bool) public done;

    constructor(Earn source_, Earn dest_, uint divisor_) {
        divisor = divisor_;
        source = source_;
        dest = dest_;
    }

    function migrate(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            migrate(tokenIds[i]);
        }
    }

    function migrateRange(uint start, uint end) external {
        uint[] memory tokenIds = new uint[](end - start);
        for(uint i; i < tokenIds.length; i ++) {
            migrate(tokenIds[i] + start);
        }
    }

    function migrate(uint tokenId) public {
        require(!done[tokenId], "Already done.");
        done[tokenId] = true;
        uint unlockedClaimable = source.getUnlockedClaimable(tokenId) / divisor;
        uint locked = source.getLocked(tokenId) / divisor;
        uint interest = source.getInterest(tokenId) / divisor;
        if(source.isInLocation(tokenId)) {
            dest.setLocation(tokenId, source.getLocation(tokenId));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}