//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "./MintWithTokens.sol";

contract HolderMintWithTokens is MintWithTokens {
    IERC721Enumerable public whitelistedNft;
    mapping(uint => bool) public claimed;

    constructor(IERC721Enumerable whitelistedNft_,Nft nfvs, uint mintPrice_, uint maxMinted_, IERC20 token_, ERC20Payments.Payee[] memory payees) MintWithTokens(nfvs, mintPrice_, maxMinted_, token_, payees) {
        whitelistedNft = whitelistedNft_;
    }

    function checkClaimed(uint[] calldata tokenIds) external view returns(bool[] memory) {
        bool[] memory result = new bool[](tokenIds.length);
        for(uint i; i < tokenIds.length; i++) {
            result[i] = claimed[tokenIds[i]];
        }
        return result;
    }

    function _beforeMint(address to, uint numberOf) internal override {
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