// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Earn.sol";
import "./Dependencies/EarnOld.sol";

contract EarnMigratorForLegacy {
    using Fees for uint;
    EarnOld public source;
    Earn public dest;
    uint public divisor;
    uint public constant CUTOFF = 3999;

    mapping(uint => bool) public done;

    constructor(EarnOld source_, Earn dest_, uint divisor_) {
        divisor = divisor_;
        source = source_;
        dest = dest_;
        (uint parts,uint outOf) = source.lockRatio();
        _lock = Fees.Fee(parts,outOf);
    }

    function doneMultiple(uint[] calldata tokenIds) external view returns(bool[] memory res) {
        res = new bool[](tokenIds.length);
        for(uint i; i < tokenIds.length; i ++) {
            res[i] = done[tokenIds[i]];
        }
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
        require(!done[tokenId], "Cannot migrate twice.");;
        require(tokenId <= CUTOFF, "Cannot migrate mints after cutoff.");
        done[tokenId] = true;
        EarnOld.NfvView memory data = source.getInformation(tokenId);

        uint pendingClaim = data.claimable;
        uint pendingLocked = pendingClaim.feesOf(_lock);


        uint unlockedClaimable = (pendingClaim - pendingLocked) / divisor;
        uint locked = (data.locked + pendingLocked) / divisor;
        uint interest = data.interestable / divisor;
        if(source.isInLocation(tokenId)) {
            EarnOld.Location memory location = source.getLocation(tokenId);
            dest.setLocation(tokenId, Earn.Location(location.stage, location.substage));
        }
        dest.addToClaimable(tokenId, unlockedClaimable);
        dest.addToLocked(tokenId, locked);
        dest.addToInterest(tokenId, interest);
    }
}