// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Earn.sol";

contract EarnMigrator {
    using Fees for uint;
    Earn public source;
    Earn public dest;
    uint public divisor;

    mapping(uint => bool) public done;

    constructor(Earn source_, Earn dest_, uint divisor_) {
        divisor = divisor_;
        source = source_;
        dest = dest_;
        (uint parts,uint outOf) = source.lockRatio();
        _lock = Fees.Fee(parts,outOf);
    }

    function migrate(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            migrate(tokenIds[i]);
        }
    }

    function migrateRange(uint start, uint end) external {
        for(uint i; i < end-start; i ++) {
            migrate(i + start);
        }
    }

    Fees.Fee private _lock;

    function migrate(uint tokenId) public {
        require(!done[tokenId], "Already done.");
        done[tokenId] = true;
        Earn.NfvView memory data = source.getInformation(tokenId);

        uint pendingClaim = data.claimable;
        uint pendingLocked = pendingClaim.feesOf(_lock);


        uint unlockedClaimable = (pendingClaim - pendingLocked) / divisor;
        uint locked = (data.locked + pendingLocked) / divisor;
        uint interest = data.interestable / divisor;
        if(source.isInLocation(tokenId)) {
            dest.setLocation(tokenId, source.getLocation(tokenId));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}