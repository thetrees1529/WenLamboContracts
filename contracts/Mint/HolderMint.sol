//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "./Mint.sol";

contract HolderMint is Mint {
    IERC721Enumerable public whitelistedNft;
    mapping(uint => bool) public claimed;

    constructor(Nft nfvs, uint mintPrice_, uint maxMinted_, Payments.Payee[] memory payees) Mint(nfvs, mintPrice_, maxMinted_, payees) {
        whitelistedNft = IERC721Enumerable(nfvs);
    }

    function _beforeMint(address to, uint numberOf) internal override {
        uint balance = whitelistedNft.balanceOf(to);
        uint found;
        for(uint i; found < numberOf; i++) {
            uint tokenId = whitelistedNft.tokenOfOwnerByIndex(to, i);
            if(!claimed[tokenId]) {
                claimed[tokenId] = true;
                found++;
            }
        }
    }
}