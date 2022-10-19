// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "./AHILLE.sol";

contract Earn is Ownable, OwnerOf, ERC20Payments {

    using Fees for uint;

    struct Stage {
        string name;
        uint price;
        uint priceHville;
        uint emission;
    }

    struct Nfv {
        bool onLadder;
        bool claimedBefore;
        uint stage;

        uint lastClaimed; //timestamp
        uint firstClaimedAt;
        uint totalClaimed;

        uint lockedTotal;
        uint lockedClaimed;

        bool claimedInterestBefore;
        uint lastClaimedInterest;
        uint totalInterestClaimed;
    }

    Stage[] private _ladder;
    uint public defaultEmission;
    Fees.Fee public lockRatio;
    Fees.Fee public interest;
    uint public unlockStart;
    uint public unlockEnd;
    AHILLE public ahille;
    IERC20 public hville;
    uint public deployedAt;
    uint private _totalYield;
    uint public globalMaxYield;

    constructor(IERC721 nfvs, IERC20 hville_, address ahille_, ERC20Payments.Payee[] memory payees, Stage[] memory ladder_, uint defaultEmission_, Fees.Fee memory lockRatio_, Fees.Fee memory interest_, uint unlockStart_, uint unlockEnd_, uint globalMaxYield_) OwnerOf(nfvs) ERC20Payments(IERC20(ahille_)) {
        _setPayees(payees);
        ahille = AHILLE(ahille_);
        hville = hville_;
        lockRatio = lockRatio_;
        interest = interest_;
        for(uint i; i < ladder_.length; i++) {
            _ladder.push(ladder_[i]);
        }
        defaultEmission = defaultEmission_;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        deployedAt = block.timestamp;
        globalMaxYield = globalMaxYield_;
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyOwner {
        _setPayees(payees);
    }

    function ladder() external view returns(Stage[] memory) {return _ladder;}

    function getNfv(uint tokenId) external view returns(Nfv memory) {
        return _nfvs[tokenId];
    }

    function getLocked(uint tokenId) public view returns(uint) {
        Nfv storage nfv = _nfvs[tokenId]; 
        return nfv.lockedTotal - nfv.lockedClaimed;
    }

    function getUnlockable(uint tokenId) public view returns(uint) {
        if(_isBeforeUnlock()) return 0;
        Nfv storage nfv = _nfvs[tokenId]; 
        return ((nfv.lockedTotal * (block.timestamp - unlockStart)) / (unlockEnd - unlockStart)) - nfv.lockedClaimed;
    }

    function getClaimable(uint tokenId) public view returns(uint) {
        Nfv storage nfv = _nfvs[tokenId];
        uint earningSince = _earningSinceOf(nfv);
        uint emission = nfv.onLadder ? _ladder[nfv.stage].emission : defaultEmission;
        uint attemptedClaim = _calcEarnedSince(earningSince, emission);
        return _getMaxClaim(attemptedClaim);
    }

    function getInterestOf(uint tokenId) public view returns(uint) {
        Nfv storage nfv = _nfvs[tokenId];
        if(!nfv.claimedBefore) return 0;
        uint locked = getLocked(tokenId);
        uint emission = locked.feesOf(interest);
        uint attemptedClaim = _calcEarnedSince(nfv.claimedInterestBefore ? nfv.lastClaimedInterest : nfv.firstClaimedAt, emission);
        return _getMaxClaim(attemptedClaim);
    }

    function upgradeMultiple(uint[] calldata tokenIds) public {
        for(uint i; i < tokenIds.length; i ++) upgrade(tokenIds[i]);
    }

    function upgrade(uint tokenId) public onlyOwnerOf(tokenId) {
        claim(tokenId);

        Nfv storage nfv = _nfvs[tokenId]; 
        
        uint stageIndex;

        if(nfv.onLadder) {
            nfv.stage ++;
            stageIndex = nfv.stage;
        } else nfv.onLadder = true;

        Stage storage stage = _ladder[stageIndex];
        
        ahille.transferFrom(msg.sender, address(this), stage.price);
        hville.transferFrom(msg.sender, address(this), stage.priceHville);
        _makePayment(stage.price);
    }

    function claimMultiple(uint[] calldata tokenIds) public {
        for(uint i; i < tokenIds.length; i ++) claim(tokenIds[i]);
    }

    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        claimInterest(tokenId);
        Nfv storage nfv = _nfvs[tokenId];
        uint claimable = getClaimable(tokenId);
        uint locked = claimable.feesOf(lockRatio);
        uint toOwner = claimable - locked;
        nfv.lockedTotal += locked;
        nfv.lastClaimed = block.timestamp;
        nfv.totalClaimed += claimable;
        if(!nfv.claimedBefore) {nfv.claimedBefore = true; nfv.firstClaimedAt = block.timestamp;}
        _totalYield += claimable;
        ahille.mint(msg.sender, toOwner);
    }

    function claimInterestMultiple(uint[] calldata tokenIds) public {
        for(uint i; i < tokenIds.length; i ++) claimInterest(tokenIds[i]);
    }

    function claimInterest(uint tokenId) public onlyOwnerOf(tokenId) {
        Nfv storage nfv = _nfvs[tokenId];
        uint claimable = getInterestOf(tokenId);
        nfv.lastClaimedInterest = block.timestamp;
        nfv.totalInterestClaimed += claimable;
        if(!nfv.claimedInterestBefore) nfv.claimedInterestBefore = true;
        _totalYield += claimable;
        ahille.mint(msg.sender, claimable);
    }

    function claimLockedMultiple(uint[] calldata tokenIds) public {
        for(uint i; i < tokenIds.length; i ++) claimLocked(tokenIds[i]);
    }

    function claimLocked(uint tokenId) public onlyOwnerOf(tokenId) {
        claimInterest(tokenId);
        Nfv storage nfv = _nfvs[tokenId];
        uint claimable = getUnlockable(tokenId);
        nfv.lockedClaimed += claimable;
        ahille.mint(msg.sender, claimable);
    }

    function _getMaxClaim(uint attemptedClaim) private view returns(uint) {
        uint maxClaim = globalMaxYield - _totalYield;
        return attemptedClaim <= maxClaim ? attemptedClaim : maxClaim;
    }

    function _earningSinceOf(Nfv storage nfv) private view returns(uint) {
        return nfv.claimedBefore ? nfv.lastClaimed : deployedAt;
    }

    function _calcEarnedDuring(uint start, uint end, uint emission) private pure returns(uint) {
        return (end - start) * emission;
    }

    function _calcEarnedSince(uint timestamp, uint emission) private view returns(uint) {
        return _calcEarnedDuring(timestamp, block.timestamp, emission);
    } 


    function withdrawHville() external onlyOwner {
        hville.transfer(msg.sender, hville.balanceOf(address(this)));
    }

    function _isBeforeUnlock() private view returns(bool) {
        return block.timestamp < unlockStart;
    }

    mapping(uint => Nfv) private _nfvs;
    
}