// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Nfts/BridgedNft.sol";
import "./NfvBase.sol";

contract NfvsBridged is BridgedNft, NfvBase {

    constructor(string memory name, string memory symbol, string memory uri) BridgedNft(uri,name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _burn(uint tokenId) internal override(ERC721, NfvBase) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(NfvBase, BridgedNft) returns(string memory) {
        return super._baseURI();
    }

    function _transfer(address from, address to, uint tokenId) internal override(ERC721, NfvBase) {
        super._transfer(from, to, tokenId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint firstTokenId, uint batchSize) internal override(ERC721Enumerable, NfvBase) {
        super._beforeTokenTransfer(from,to,firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public override(BridgedNft, NfvBase) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}