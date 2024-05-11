// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./extensions/Bridgeable.sol";
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BridgedNft is Bridgeable, ERC721Enumerable, Nft {

    constructor(string memory name, string memory symbol, string memory uri) Nft(uri, name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mintTokenId(address to, uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, tokenId);
    }

    function burnTokenId(uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId);
    }

    function _baseURI() internal virtual override(ERC721, Nft) view returns(string memory) {
        return super._baseURI();
    }

    function supportsInterface(bytes4 interfaceId) public virtual override(Nft, Bridgeable, ERC721Enumerable) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}