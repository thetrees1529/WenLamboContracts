// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintWithTokens is Ownable { 
    using ERC20Payments for IERC20;
    IERC20 public token;
    uint public mintPrice;
    //has been manually ended
    bool public ended;
    //number of nfvs minted through this contract
    uint public totalMinted;
    //maximum number of nfvs minted through this contract
    uint public maxMinted;
    Nft internal _nfvs;
    ERC20Payments.Payee[] private _payees;
    constructor(Nft nfvs, uint mintPrice_, uint maxMinted_, IERC20 token_, ERC20Payments.Payee[] memory payees) {
        for(uint i; i < payees.length; i ++) {
            _payees.push(payees[i]);
        }
        _nfvs = nfvs;
        mintPrice = mintPrice_;
        maxMinted = maxMinted_;
        token = token_;
    }
    function mint(uint numberOf) external payable {
        uint payment = numberOf * mintPrice;
        require(!ended, "Ended.");
        require(totalMinted + numberOf <= maxMinted, "Too many.");
        _beforeMint(msg.sender, numberOf);
        totalMinted += numberOf;
        _nfvs.mint(msg.sender, numberOf);
        token.splitFrom(msg.sender, payment, _payees);
    }
    function _beforeMint(address to, uint numberOf) internal virtual {}
    function end() external onlyOwner {
        ended = true;
    }
}