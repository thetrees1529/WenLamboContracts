// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "./Token.sol";

contract Earn is AccessControl {

    using Fees for uint;
    using ERC20Payments for IERC20;

    struct Payment {
        IERC20 token;
        uint value;
    }

    struct Substage {
        string name;
        Payment[] payments;
        uint emission;
    }

    struct Stage {
        string name;
        Substage[] substages;
    }

    struct Location {
        uint stage;
        uint substage;
    }

    struct Nfv {
        bool onStages;
        bool claimedOnce;
        uint lastClaim;
        uint pendingClaim;
        uint locked;
        uint unlocked;
        Location location;
    }

    bytes32 public EARN_ROLE = keccak256("EARN_ROLE"); 

    uint public genesis;
    uint public unlockStart;
    uint public unlockEnd;
    uint public baseEarn;
    uint public mintCap;
    Stage[] private _stages;
    Fees.Fee public lockRatio;
    Fees.Fee public interest;
    Token public token;
    IERC721 public nfvs;
    ERC20Payments.Payee[] private _payees;

    mapping(uint => Nfv) public nfvInfo;

    constructor(IERC721 nfvs_, Token token_, Stage[] memory stages, Fees.Fee memory lockRatio_, Fees.Fee memory interest_, uint unlockStart_, uint unlockEnd_, uint baseEarn_, uint mintCap_) {
        token = token_;
        nfvs = nfvs_;
        _stages = stages;
        lockRatio = lockRatio_;
        interest = interest_;
        genesis = block.timestamp;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        baseEarn = baseEarn_;
        mintCap = mintCap_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPayees(ERC20Payments.Payee[] calldata payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _payees = payees;
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function getStages() external view returns(Stage[] memory) {
        return _stages;
    }

    function getClaimable(uint tokenId) external view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.pendingClaim + _getPending(tokenId);
    }

    function getLocked(uint tokenId) external view returns(uint){
        Nfv storage nfv = nfvInfo[tokenId];
        uint totalTime = unlockEnd - unlockStart;
        uint timeElapsed; 
        if(block.timestamp >= unlockStart) timeElapsed = block.timestamp - unlockStart;
        uint timeUnlocking = timeElapsed <= totalTime ? timeElapsed : totalTime;
        uint theoreticalLocked = (nfv.locked * timeUnlocking) / totalTime;
        return theoreticalLocked - nfv.unlocked;
    }



    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint locked = nfv.pendingClaim.feesOf(lockRatio);
        uint toOwner = nfv.pendingClaim - locked;
        delete nfv.pendingClaim;
        nfv.locked += locked;
        token.mintTo(msg.sender, toOwner);
    }

    function upgrade(uint tokenId) public onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        Location memory location = nfv.location;
        if(nfv.onStages) {
            Stage storage currentStage = _stages[location.stage];
            if(location.substage >= currentStage.substages.length - 1) {
                location.stage ++;
                location.substage = 0;
            } else {
                location.substage ++;
            }
        }
        _setLocation(tokenId, location);
        Substage storage substage = _getSubstage(location);
        for(uint i; i < substage.payments.length; i ++) {
            _takePayment(msg.sender, substage.payments[i]);
        }
    }

    function isInLocation(uint tokenId) external view returns(bool) {
        return nfvInfo[tokenId].onStages;
    }

    function getLocation(uint tokenId) external view returns(Location memory) {
        Nfv storage nfv = nfvInfo[tokenId];
        require(nfv.onStages, "Not in a location.");
        return nfv.location;
    } 

    function setLocation(uint tokenId, Location calldata location) external onlyRole(EARN_ROLE) {
        _setLocation(tokenId, location);
    }

    function _setLocation(uint tokenId, Location memory location) private {
        require(_isValidLocation(location), "Setting invalid location.");
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(!nfv.onStages) nfv.onStages = true;
        nfv.location = location;
    }

    function exitLocation(uint tokenId) external onlyRole(EARN_ROLE) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        if(nfv.onStages) {
            nfv.onStages = false;
            delete nfv.location;
        }
    }

    function _claim(uint tokenId) private {
        uint claimed = _getPending(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        nfv.lastClaim = block.timestamp;
        nfv.pendingClaim += claimed;
        if(!nfv.claimedOnce) nfv.claimedOnce = true;
    }

    function _getPending(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint earningSince = nfv.claimedOnce ? nfv.lastClaim : genesis;
        Location storage location = nfv.location;
        uint emission = nfv.onStages ? _getSubstage(location).emission : baseEarn;
        uint timeEarning = block.timestamp - earningSince;
        return timeEarning * emission;
    }

    function _getSubstage(Location memory location) private view returns(Substage storage) {
        require(_isValidLocation(location), "Location is invalid.");
        return _stages[location.stage].substages[location.substage];
    }

    function _isValidLocation(Location memory location) private view returns(bool) {
        return location.stage < _stages.length && location.substage < _stages[location.stage].substages.length;
    }


    function _takePayment(address from, Payment storage payment) private {
        payment.token.transferFrom(from, address(this), payment.value);
        payment.token.split(payment.value, _payees);
    }

    //never needs to be used unless there is a bug.
    function withdraw(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, value);
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(OwnerOf.isOwnerOf(nfvs, msg.sender, tokenId), "Does not own NFT.");
        _;
    }


}