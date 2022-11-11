// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "./AHILLE.sol";

contract Earn2 is AccessControl {

    struct Substage {
        string name;
        uint price;
        uint emission;
    }

    struct Stage {
        string name;
        Substage[] substages;
    }

    struct StageId {
        uint stage;
        uint substage;
    }

    struct Nfv {
        bool onStages;
        StageId stageId;
        uint unclaimed;
    }

    struct Stats {
        uint earnSpeed;
        uint pendingClaim;
        uint totalClaimed;
        uint locked;
        uint pendingInterest;
        uint totalInterestClaimed;
    }

    Stage[] private _stages;

    function stages() external view returns(Stage[] memory) {
        return _stages;
    }

    uint public genesis;
    uint public defaultEarn;

    

    function statsOf(uint tokenId) public view returns(uint) {
        
    }




}