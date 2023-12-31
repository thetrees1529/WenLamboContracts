// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/payments/Payments.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Nfvs/Nfvs.sol";

contract MintClump is Ownable, Payments { 

    uint public mintPrice;
    //has been manually ended
    bool public ended;
    //number of clumps minted through this contract
    uint public totalMinted;
    //maximum number of clumps minted through this contract
    uint public maxMinted;
    //number of nfvs per clump
    uint public nfvsPerClump;
    Nfvs internal _nfvs;
    constructor(Nfvs nfvs, uint mintPrice_, uint maxMinted_, uint nfvsPerClump_, Payments.Payee[] memory payees) {
        _setPayees(payees);
        _nfvs = nfvs;
        nfvsPerClump = nfvsPerClump_;
        mintPrice = mintPrice_;
        maxMinted = maxMinted_;
    }
    function mint(uint numberOf) external payable {
        uint payment = numberOf * mintPrice;
        require(!ended, "Ended.");
        require(msg.value == payment, "Incorrect funds.");
        require(totalMinted + numberOf <= maxMinted, "Too many.");
        _beforeMint(msg.sender, numberOf);
        totalMinted += numberOf;
        _nfvs.mint(msg.sender, numberOf * nfvsPerClump);
        _makePayment(payment);
    }
    function _beforeMint(address to, uint numberOf) internal virtual {}
    function end() external onlyOwner {
        ended = true;
    }
}