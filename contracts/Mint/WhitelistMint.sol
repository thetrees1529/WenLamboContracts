// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/payments/Payments.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Nfts/WhitelistTickets.sol";
import "./Mint.sol";


contract WhitelistMint is Mint {

    WhitelistTickets private _whitelistTickets;

    constructor(Nft nfvs, WhitelistTickets whitelistTickets, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees) Mint(nfvs, mintPrice_, maxMinted_, payees) {
        _whitelistTickets = whitelistTickets;
    }

    function _beforeMint(address to, uint numberOf) internal override {
        _whitelistTickets.burn(to, numberOf);
    }
 
}