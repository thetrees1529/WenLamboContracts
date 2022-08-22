// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@thetrees1529/solutils/contracts/payments/Payments.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Lambos.sol";

contract Mint is Ownable, Payments {
    uint public mintPrice;
    //has been manually ended
    bool public ended;
    //number of lambos minted through this contract
    uint public totalMinted;
    //maximum number of lambos minted through this contract
    uint public maxMinted;
    Lambos private _lambos;
    constructor(Lambos lambos, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees) {
        _setPayees(payees);
        _lambos = lambos;
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
        _lambos.mint(msg.sender, numberOf);
        _makePayment(payment);
    }
    function _beforeMint(address to, uint numberOf) internal virtual {}
    function end() external onlyOwner {
        ended = true;
    }
}