// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "./AHILLE.sol";

contract Earn is Ownable, OwnerOf, ERC20Payments, ReentrancyGuard {

    using Fees for uint;

    struct Stage {
        string name;
        uint price;
        uint priceHville;
        uint emission;
    }

    struct Lambo {
        bool onLadder;
        uint stage;
        uint lastClaimed; //timestamp
        uint totalClaimed;
        uint lockedTotal;
        uint lockedClaimed;
    }

    Stage[] private _ladder;
    uint public defaultEmission;
    Fees.Fee public lockRatio;
    uint public unlockStart;
    uint public unlockEnd;
    AHILLE public ahille;
    IERC20 public hville;
    uint public deployedAt;

    constructor(IERC721 lambos, IERC20 hville_, address ahille_, ERC20Payments.Payee[] memory payees, Stage[] memory ladder_, uint defaultEmission_, Fees.Fee memory lockRatio_, uint unlockStart_, uint unlockEnd_) OwnerOf(lambos) ERC20Payments(IERC20(ahille_)) {
        _setPayees(payees);
        ahille = AHILLE(ahille_);
        hville = hville_;
        lockRatio = lockRatio_;
        for(uint i; i < ladder_.length; i++) {
            _ladder.push(ladder_[i]);
        }
        defaultEmission = defaultEmission_;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        deployedAt = block.timestamp;
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyOwner {
        _setPayees(payees);
    }

    function ladder() external view returns(Stage[] memory) {return _ladder;}

    function upgrade(uint tokenId) public nonReentrant onlyOwnerOf(tokenId) {
        claim(tokenId);

        Lambo storage lambo = _lambos[tokenId]; 
        
        uint stageIndex;

        if(lambo.onLadder) {
            lambo.stage ++;
            stageIndex = lambo.stage;
        } else lambo.onLadder = true;

        Stage storage stage = _ladder[stageIndex];
        
        ahille.transferFrom(msg.sender, address(this), stage.price);
        hville.transferFrom(msg.sender, address(this), stage.priceHville);
        _makePayment(stage.price);
    }

    function getClaimable(uint tokenId) public view returns(uint) {
        Lambo storage lambo = _lambos[tokenId];
        (uint earningSince, uint emission) = lambo.onLadder ? (lambo.lastClaimed, _ladder[lambo.stage].emission) : (deployedAt, defaultEmission);
        return _calcEarnedSince(earningSince, emission);
    }

    function _calcEarnedDuring(uint start, uint end, uint emission) private pure returns(uint) {
        return (end - start) * emission;
    }

    function _calcEarnedSince(uint timestamp, uint emission) private view returns(uint) {
        return _calcEarnedDuring(timestamp, block.timestamp, emission);
    } 

    function getUnlockable(uint tokenId) public view returns(uint) {
        if(_isBeforeUnlock()) return 0;
        Lambo storage lambo = _lambos[tokenId]; 
        return ((lambo.lockedTotal * (block.timestamp - unlockStart)) / (unlockEnd - unlockStart)) - lambo.lockedClaimed;
    }

    function getLambo(uint tokenId) external view returns(Lambo memory) {
        return _lambos[tokenId];
    }

    function claim(uint[] calldata tokenIds) public {
        for(uint i; i < tokenIds.length; i ++) claim(tokenIds[i]);
    }

    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        Lambo storage lambo = _lambos[tokenId];
        uint claimable = getClaimable(tokenId);
        uint locked = claimable.feesOf(lockRatio);
        uint toOwner = claimable - locked;
        lambo.lockedTotal += locked;
        lambo.lastClaimed = block.timestamp;
        lambo.totalClaimed += claimable;
        ahille.mint(msg.sender, toOwner);
    }

    function claimLocked(uint tokenId) public onlyOwnerOf(tokenId) {
        Lambo storage lambo = _lambos[tokenId];
        uint claimable = getUnlockable(tokenId);
        lambo.lockedClaimed += claimable;
        ahille.mint(msg.sender, claimable);
    }

    function withdrawHville() external onlyOwner {
        hville.transfer(msg.sender, hville.balanceOf(address(this)));
    }

    function _isBeforeUnlock() private view returns(bool) {
        return block.timestamp < unlockStart;
    }

    mapping(uint => Lambo) private _lambos;
    
}