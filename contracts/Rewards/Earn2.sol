// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Nfvs/Nfvs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "../Token/Token.sol";

interface IEarn {
    struct ERC20Token {
        uint burned;
        uint reflected;
    }


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
    struct NfvView {
        uint claimable;
        uint unlockedClaimable;
        uint lockedClaimable;
        uint interestable;
        uint locked;
        uint unlockable;
        bool onStages;
        Location location;
        Nfv nfv;
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

    function getStages() external view returns(Stage[] memory);
    function getPayees() external view returns(ERC20Payments.Payee[] memory);
    function lockRatio() external view returns(Fees.Fee memory);
    function burnRatio() external view returns(Fees.Fee memory);
    function interest() external view returns(Fees.Fee memory);
    function token() external view returns(Token);
    function nfvs() external view returns(Nfvs);
    function mintCap() external view returns(uint);
    function baseEarn() external view returns(uint);
    function totalMinted() external view returns(uint);
    function unlockStart() external view returns(uint);
    function unlockEnd() external view returns(uint);
    function tokens(IERC20 token) external view returns(ERC20Token memory);
    function genesis() external view returns(uint);


    function getInformation(uint tokenId) external view returns(NfvView memory nfv); /**{
        return NfvView({
            claimable: getClaimable(tokenId),
            unlockedClaimable: getUnlockedClaimable(tokenId),
            lockedClaimable: getPendingLocked(tokenId),
            locked: getLocked(tokenId),
            unlockable: getUnlockable(tokenId),
            interestable: getInterest(tokenId),
            onStages: nfvInfo[tokenId].onStages,
            location: nfvInfo[tokenId].location,
            nfv: nfvInfo[tokenId]
        });
    } **/
}

contract Earn2 is AccessControl {
    uint constant public EARN_SPEED_CONVERSION = 11574074074074;

    using Fees for uint;
    using ERC20Payments for IERC20;
    using OwnerOf for address;

    struct Payment {
        IERC20 token;
        uint value;
    }

    struct Substage {
        string name;
        uint price;
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
        uint locked;
        uint unlocked;
        uint totalInterestClaimed;
        uint totalClaimed;
        Location location;
    }

    struct NfvView {
        uint claimable;
        uint unlockedClaimable;
        uint lockedClaimable;
        uint claimableInterest;
        uint unlockable;
        uint locked;
        bool onStages;
        Location location;
        uint totalInterestClaimed;
        uint totalClaimed;
    }

    bool private _initialised;
    uint public genesis;
    uint public unlockStart;
    uint public unlockEnd;
    uint public baseEarn;
    uint public mintCap;
    uint public totalMinted;
    uint public burned;
    uint public collected;
    Stage[] private _stages;
    Fees.Fee public lockRatio;
    Fees.Fee public burnRatio;
    Fees.Fee public interest;
    Token public token;
    Nfvs public nfvs;
    ERC20Payments.Payee[] private _payees;
    IEarn public earnOld;

    mapping(uint => Nfv) public nfvInfo;

    constructor(IEarn earnOld_) {
        earnOld = earnOld_;
        genesis = earnOld_.genesis();
        token = earnOld_.token();
        nfvs = earnOld_.nfvs();
        lockRatio = earnOld_.lockRatio();
        burnRatio = earnOld_.burnRatio();
        interest = earnOld_.interest();
        baseEarn = earnOld_.baseEarn();
        mintCap = earnOld_.mintCap();
        unlockStart = earnOld_.unlockStart();
        unlockEnd = earnOld_.unlockEnd();
        _payees = earnOld_.getPayees();
        IEarn.Stage[] memory stages = earnOld_.getStages();
        IEarn.ERC20Token memory stats = earnOld_.tokens(IERC20(address(token)));
        burned = stats.burned;
        collected = stats.reflected;

        ERC20Payments.Payee[] memory payees = earnOld_.getPayees();
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
        for(uint i; i < stages.length; i ++) {
            IEarn.Stage memory stage = stages[i];
            Stage storage _stage = _stages.push();
            _stage.name = stage.name;
            for(uint j; j < stage.substages.length; j ++) {
                IEarn.Substage memory substage = stage.substages[j];
                Substage storage _substage = _stage.substages.push();
                _substage.name = substage.name;
                _substage.emission = substage.emission * EARN_SPEED_CONVERSION;
                _substage.price = substage.payments[0].value;
                
            }
        }
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function getStages() external view returns(Stage[] memory) {
        return _stages;
    }

    function getInformation(uint tokenId) public view returns(NfvView memory nfv) {
        (uint earnedNotLocked, uint earnedLocked, uint unlocked, uint interestEarned, uint newTotalLocked, uint newUnlocked, uint newTotalInterestClaimed, uint newTotalClaimed) = _claimCalculation(tokenId);
        
        if(nfvInfo[tokenId].claimedOnce) return NfvView({
            claimable: earnedNotLocked + earnedLocked,
            unlockedClaimable: earnedNotLocked,
            lockedClaimable: earnedLocked,
            locked: newTotalLocked - newUnlocked,
            claimableInterest: interestEarned,
            unlockable: unlocked,
            onStages: nfvInfo[tokenId].onStages,
            location: nfvInfo[tokenId].location,
            totalInterestClaimed: newTotalInterestClaimed,
            totalClaimed: newTotalClaimed
        }); else {
            IEarn.NfvView memory nfvOld = earnOld.getInformation(tokenId);
            return NfvView({
                claimable: nfvOld.claimable,
                unlockedClaimable: nfvOld.unlockedClaimable,
                lockedClaimable: nfvOld.lockedClaimable,
                locked: nfvOld.locked + nfvOld.lockedClaimable - nfvOld.unlockable,
                claimableInterest: nfvOld.interestable,
                onStages: nfvOld.onStages,
                location: Location(nfvOld.nfv.location.stage, nfvOld.nfv.location.substage),
                totalInterestClaimed: nfvOld.nfv.totalInterestClaimed,
                totalClaimed: nfvOld.nfv.totalClaimed,
                unlockable: nfvOld.unlockable
            });
        }
    }

    function getInformationMultiple(uint[] calldata tokenIds) external view returns(NfvView[] memory nfvs) {
        nfvs = new NfvView[](tokenIds.length);
        for(uint i; i < tokenIds.length; i ++) {
            nfvs[i] = getInformation(tokenIds[i]);
        }
    }

    function addToLocked(uint tokenId, uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nfvInfo[tokenId].locked += value;
    }

    function setLocation(uint tokenId, Location memory location) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nfvInfo[tokenId].location = location;
    }

    function claim(uint tokenId) public {
        _mintTo(msg.sender, _doClaim(tokenId));
    }

    function claimMultiple(uint[] calldata tokenIds) external {
        uint total;
        for(uint i; i < tokenIds.length; i ++) {
            total += _doClaim(tokenIds[i]);
        }
        _mintTo(msg.sender, total);
    }

    function upgrade(uint tokenId) public {
        (uint inflow, uint outflow) = _doUpgrade(tokenId);
        (bool netInflow, uint payment) = _inflowOutflow(inflow, outflow);
        if(netInflow) {
            _takePayment(msg.sender, payment);
        } else {
            _mintTo(msg.sender, payment);
        }
    }

    function upgradeMultiple(uint[] calldata tokenIds) external {
        uint totalInflow;
        uint totalOutflow;
        for(uint i; i < tokenIds.length; i ++) {
            (uint inflow, uint outflow) = _doUpgrade(tokenIds[i]);
            totalInflow += inflow;
            totalOutflow += outflow;
        }
        (bool netInflow, uint payment) = _inflowOutflow(totalInflow, totalOutflow);
        if(netInflow) {
            _takePayment(msg.sender, payment);
        } else {
            _mintTo(msg.sender, payment);
        }
    }

    function _claimCalculation(uint tokenId) private view returns(uint earnedNotLocked, uint earnedLocked, uint unlocked, uint interestEarned, uint newLocked, uint newUnlocked, uint newTotalInterestClaimed, uint newTotalClaimed) {
        Nfv storage nfv = nfvInfo[tokenId];

        if(nfv.claimedOnce) {
            uint claimedOrGenesis = _claimedOrGenesis(tokenId);
            uint time = block.timestamp - claimedOrGenesis;

            uint earnSpeed = nfv.onStages ? _getSubstage(nfv.location).emission : baseEarn;
            uint earned = time * earnSpeed * EARN_SPEED_CONVERSION;

            earnedLocked = earned.feesOf(lockRatio);
            earnedNotLocked = earned - earnedLocked;
            uint totalLocked = nfv.locked + earnedLocked;
            unlocked = _unlockCalc(totalLocked, nfv.unlocked);
            interestEarned = (nfv.locked * time).feesOf(interest);

            newLocked = totalLocked;
            newUnlocked = nfv.unlocked + unlocked;
            newTotalInterestClaimed = nfv.totalInterestClaimed + interestEarned;
            newTotalClaimed = nfv.totalClaimed + earned;
        } else {
            IEarn.NfvView memory nfvOld = earnOld.getInformation(tokenId);
            earnedNotLocked = nfvOld.unlockedClaimable;
            earnedLocked = nfvOld.lockedClaimable;
            unlocked = _unlockCalc(nfvOld.locked + nfvOld.lockedClaimable, nfvOld.nfv.unlocked);
            interestEarned = nfvOld.interestable;
            newLocked = nfvOld.locked + earnedLocked;
            newUnlocked = nfvOld.nfv.unlocked + unlocked;
            newTotalInterestClaimed = nfvOld.nfv.totalInterestClaimed + interestEarned;
            newTotalClaimed = nfvOld.nfv.totalClaimed + nfvOld.claimable;
        }
    }

    function _unlockCalc(uint locked, uint unlocked) private view returns(uint) {
        if(block.timestamp < unlockStart) return 0;
        if(block.timestamp > unlockEnd) return locked - unlocked;
        uint timeSinceUnlockStart = block.timestamp - unlockStart;
        uint totalTime = unlockEnd - unlockStart;
        uint timeUnlocking = timeSinceUnlockStart > totalTime ? totalTime : timeSinceUnlockStart;
        return ((locked * timeUnlocking) / totalTime) - unlocked;
    }

    function _doClaim(uint tokenId) private onlyOwnerOf(tokenId) returns(uint outflow) {
        Nfv storage nfv = nfvInfo[tokenId];

        (uint earnedNotLocked,, uint unlocked, uint interestEarned, uint newLocked, uint newUnlocked, uint newTotalInterestClaimed, uint newTotalClaimed) = _claimCalculation(tokenId);
        nfv.locked = newLocked;
        nfv.unlocked = newUnlocked;
        nfv.totalInterestClaimed = newTotalInterestClaimed;
        nfv.totalClaimed = newTotalClaimed;
        nfv.lastClaim = block.timestamp;

        outflow = earnedNotLocked + interestEarned + unlocked;

        if(!nfv.claimedOnce) nfv.claimedOnce = true;
    }

    function _doUpgrade(uint tokenId) private onlyOwnerOf(tokenId) returns(uint inflow, uint outflow) {
        Nfv storage nfv = nfvInfo[tokenId];
        outflow = _doClaim(tokenId);
        Location memory location = nfv.location;

        if(nfv.onStages) {
            Stage storage currentStage = _stages[location.stage];
            if(location.substage == currentStage.substages.length - 1) {
                require(location.stage < _stages.length - 1/*, "Fully upgraded."*/);
                location.stage ++;
                location.substage = 0;
            } else {
                location.substage ++;
            }
            nfv.location = location;
        } else nfv.onStages = true;

        inflow = _getSubstage(location).price;
    }

    function _inflowOutflow(uint inflow, uint outflow) private pure returns(bool netInflow, uint payment) {
        netInflow = inflow > outflow;
        payment = netInflow ? inflow - outflow : outflow - inflow;
    }

    function isInLocation(uint tokenId) external view returns(bool) {
        return nfvInfo[tokenId].onStages;
    }

    function getLocation(uint tokenId) external view returns(Location memory) {
        Nfv storage nfv = nfvInfo[tokenId];
        require(nfv.onStages /*,"Not in a location."*/);
        return nfv.location;
    } 

    function _claimedOrGenesis(uint tokenId) private view returns(uint) {
        Nfv storage nfv = nfvInfo[tokenId];
        return nfv.claimedOnce ? nfv.lastClaim : genesis;
    }

    function _getSubstage(Location memory location) private view returns(Substage storage) {
        require(_isValidLocation(location)/*, "Location is invalid."*/);
        return _stages[location.stage].substages[location.substage];
    }

    function _isValidLocation(Location memory location) private view returns(bool) {
        return location.stage < _stages.length && location.substage < _stages[location.stage].substages.length;
    }

    function _takePayment(address from, uint total) private {

        uint toBurn = total.feesOf(burnRatio);
        token.burnFrom(from, toBurn);

        burned += toBurn;
        collected += total;

        IERC20(address(token)).splitFrom(from, total - toBurn, _payees);

    }

    //never needs to be used unless there is a bug.
    function withdraw(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, value);
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(msg.sender.isOwnerOf(nfvs, tokenId)/*, "Does not own NFT."*/);
        _;
    }
    
    function _mintTo(address addr, uint value) private {
        require(totalMinted + value <= mintCap/*, "Mint cap reached."*/);
        totalMinted += value;
        token.mintTo(addr, value);
    }


}