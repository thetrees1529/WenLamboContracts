//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

contract Plates is Nft {
    constructor(string memory uri) Nft(uri, "MCVerse Plates", "MCVERSEPLATES") {}
}