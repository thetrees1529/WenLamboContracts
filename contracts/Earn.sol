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
    Fees.Fee public lockRatio;
    uint public unlockStart;
    uint public unlockEnd;
    AHILLE public ahille;

    constructor(IERC721 lambos, address ahille_, ERC20Payments.Payee[] memory payees, Stage[] memory ladder_, Fees.Fee memory lockRatio_, uint unlockStart_, uint unlockEnd_) OwnerOf(lambos) ERC20Payments(IERC20(ahille_)) {
        _setPayees(payees);
        ahille = AHILLE(ahille_);
        lockRatio = lockRatio_;
        for(uint i; i < ladder_.length; i++) {
            _ladder.push(ladder_[i]);
        }
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyOwner {
        _setPayees(payees);
    }

    function ladder() external view returns(Stage[] memory) {return _ladder;}

    function upgrade(uint tokenId) public nonReentrant onlyOwnerOf(tokenId) {
        claim(tokenId);
        Lambo storage lambo = _lambos[tokenId]; 
        if(lambo.onLadder) lambo.stage ++;
        else lambo.onLadder = true;
        uint price = _ladder[lambo.stage].price;
        ahille.transferFrom(msg.sender, address(this), price);
        _makePayment(price);
    }

    function getClaimable(uint tokenId) public view returns(uint) {
        Lambo storage lambo = _lambos[tokenId];
        if(!lambo.onLadder) return 0;
        return (block.timestamp - lambo.lastClaimed) * _ladder[lambo.stage].emission;
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

    function claimLocked(uint tokenId) public nonReentrant onlyOwnerOf(tokenId) {
        Lambo storage lambo = _lambos[tokenId];
        uint claimable = getUnlockable(tokenId);
        ahille.mint(msg.sender, claimable);
        lambo.lockedClaimed += claimable;
    }

    function _isBeforeUnlock() private view returns(bool) {
        return block.timestamp < unlockStart;
    }

    mapping(uint => Lambo) private _lambos;
    
}