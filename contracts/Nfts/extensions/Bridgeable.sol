// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBridgeable {
    function mintTokenId(address to, uint tokenId) external;
    function burnTokenId(uint tokenId) external;
}

abstract contract Bridgeable is IBridgeable, ERC165 {
    function supportsInterface(bytes4 interfaceId) public virtual override view returns(bool) {
        return interfaceId == type(IBridgeable).interfaceId || super.supportsInterface(interfaceId);
    }
}