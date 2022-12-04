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
        uint pendingInterest;
        uint totalInterestClaimed;
        uint totalClaimed;
        Location location;
    }

    struct NfvView {
        uint claimable;
        uint interestable;
        uint locked;
        uint unlockable;
        bool onStages;
        Location location;
        Nfv nfv;
    }

    function getInformation(uint tokenId) external view returns(NfvView memory nfv) {
        return NfvView({
            claimable: getClaimable(tokenId),
            locked: getLocked(tokenId),
            unlockable: getUnlockable(tokenId),
            interestable: getInterest(tokenId),
            onStages: nfvInfo[tokenId].onStages,
            location: nfvInfo[tokenId].location,
            nfv: nfvInfo[tokenId]
        });
    }

    bytes32 public EARN_ROLE = keccak256("EARN_ROLE"); 

    uint public genesis;
    uint public unlockStart;
    uint public unlockEnd;
    uint public baseEarn;
    uint public mintCap;
    uint public totalMinted;
    uint public totalReflected;
    uint public totalBurn;
    Stage[] private _stages;
    Fees.Fee public lockRatio;
    Fees.Fee public burnRatio;
    Fees.Fee public interest;
    Token public token;
    IERC721 public nfvs;
    ERC20Payments.Payee[] private _payees;

    mapping(uint => Nfv) public nfvInfo;

    constructor(IERC721 nfvs_, Token token_, Stage[] memory stages, Fees.Fee memory lockRatio_, Fees.Fee memory burnRatio_, Fees.Fee memory interest_, uint unlockStart_, uint unlockEnd_, uint baseEarn_, uint mintCap_) {
        token = token_;
        nfvs = nfvs_;
        for(uint i; i < stages.length; i ++) {
            Stage memory stage = stages[i];
            Stage storage _stage = _stages.push();
            _stage.name = stage.name;
            for(uint j; j < stage.substages.length; j ++) {
                Substage memory substage = stage.substages[j];
                Substage storage _substage = _stage.substages.push();
                _substage.name = substage.name;
                _substage.emission = substage.emission;
                for(uint k; k < substage.payments.length; k ++) {
                    _substage.payments.push(substage.payments[k]);
                }
            }
        }
        lockRatio = lockRatio_;
        burnRatio = burnRatio_;
        interest = interest_;
        genesis = block.timestamp;
        unlockStart = unlockStart_;
        unlockEnd = unlockEnd_;
        baseEarn = baseEarn_;
        mintCap = mintCap_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPayees(ERC20Payments.Payee[] calldata payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _payees;
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
    }

    function setLockRatio(Fees.Fee calldata lockRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockRatio = lockRatio_;
    }

    function setBurnRatio(Fees.Fee calldata burnRatio_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnRatio = burnRatio_;
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function getStages() external view returns(Stage[] memory) {
        return _stages;
    }

    function getClaimable(uint tokenId) public view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.pendingClaim + _getPending(tokenId);
    }

    function getInterest(uint tokenId) public view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.pendingInterest + _getPendingInterest(tokenId);
    }

    function getLocked(uint tokenId) public view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.locked - nfv.unlocked;
    }

    function unlock(uint tokenId) external onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint toUnlock = getUnlockable(tokenId);
        nfv.unlocked += toUnlock;
        _mintTo(msg.sender, toUnlock);
    }

    function getUnlockable(uint tokenId) public view returns(uint){
        Nfv storage nfv = nfvInfo[tokenId];
        uint totalTime = unlockEnd - unlockStart;
        uint timeElapsed; 
        if(block.timestamp >= unlockStart) timeElapsed = block.timestamp - unlockStart;
        uint timeUnlocking = timeElapsed <= totalTime ? timeElapsed : totalTime;
        uint theoreticalLocked = (nfv.locked * timeUnlocking) / totalTime;
        return theoreticalLocked - nfv.unlocked;
    }

    function claimMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingClaim = nfv.pendingClaim;
        nfv.totalClaimed += pendingClaim;
        delete nfv.pendingClaim;
        _mintTo(msg.sender, pendingClaim);
    }

    function claimInterestMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            claimInterest(tokenIds[i]);
        }
    }

    function claimInterest(uint tokenId) public onlyOwnerOf(tokenId) {
        _claim(tokenId);
        Nfv storage nfv = nfvInfo[tokenId];
        uint pendingInterest = nfv.pendingInterest;
        nfv.totalInterestClaimed += pendingInterest;
        delete nfv.pendingInterest;
        _mintTo(msg.sender, pendingInterest);
    }


    function upgradeMultiple(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) {
            upgrade(tokenIds[i]);
        }
    }

    function upgrade(uint tokenId) public onlyOwnerOf(tokenId) {
        Nfv storage nfv = nfvInfo[tokenId];
        Location memory location = nfv.location;
        if(nfv.onStages) {
            Stage storage currentStage = _stages[location.stage];
            if(location.substage == currentStage.substages.length - 1) {
                require(location.stage < _stages.length - 1, "Fully upgraded.");
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

    function editLocked(uint tokenId, int change) external onlyRole(EARN_ROLE) {
        require(block.timestamp < unlockStart, "Unlock already started.");
        Nfv storage nfv = nfvInfo[tokenId];
        uint uintChange = uint(change);
        if(change > int(nfv.locked)) nfv.locked += uintChange;
        else nfv.locked -= uintChange;
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
        Nfv storage nfv = nfvInfo[tokenId];

        uint interested = _getPendingInterest(tokenId);
        uint claimed = _getPending(tokenId);
        uint locked = claimed.feesOf(lockRatio);
        uint pendingClaim = claimed - locked;

        nfv.pendingInterest += interested;
        nfv.pendingClaim += pendingClaim;
        nfv.locked += locked;
        nfv.lastClaim = block.timestamp;
        if(!nfv.claimedOnce) nfv.claimedOnce = true;
    }

    function _getPending(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint earningSince = _claimedOrGenesis(tokenId);
        Location storage location = nfv.location;
        uint emission = nfv.onStages ? _getSubstage(location).emission : baseEarn;
        uint timeEarning = block.timestamp - earningSince;
        return timeEarning * emission;
    }

    function _getPendingInterest(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        uint timeSince = _claimedOrGenesis(tokenId);
        uint until = block.timestamp <= unlockEnd ? block.timestamp : unlockEnd;
        uint timeElapsed = until - timeSince;
        uint iPS = nfv.locked.feesOf(interest);
        return iPS * timeElapsed; 
    }

    function _claimedOrGenesis(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.claimedOnce ? nfv.lastClaim : genesis;
    }

    function _getSubstage(Location memory location) private view returns(Substage storage) {
        require(_isValidLocation(location), "Location is invalid.");
        return _stages[location.stage].substages[location.substage];
    }

    function _isValidLocation(Location memory location) private view returns(bool) {
        return location.stage < _stages.length && location.substage < _stages[location.stage].substages.length;
    }


    function _takePayment(address from, Payment storage payment) private {
        uint total = payment.value;
        payment.token.transferFrom(from, address(this), total);

        uint attemptedBurn = total.feesOf(burnRatio);
        try Token(address(payment.token)).burn(attemptedBurn) {
            total -= attemptedBurn;
            totalBurn += attemptedBurn;
        }
        catch {}

        payment.token.split(total, _payees);
        totalReflected += total;
    }

    //never needs to be used unless there is a bug.
    function withdraw(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, value);
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(OwnerOf.isOwnerOf(nfvs, msg.sender, tokenId), "Does not own NFT.");
        _;
    }

    function _mintTo(address addr, uint value) private {
        require(totalMinted + value <= mintCap, "Mint cap reached.");
        totalMinted += value;
        token.mintTo(addr, value);
    }


}