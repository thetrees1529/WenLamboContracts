// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Items is AccessControl, ERC1155 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _URI;

    constructor(string memory URI) ERC1155(URI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setURI(string memory URI) external onlyRole(DEFAULT_ADMIN_ROLE) {_setURI(URI);}

    function mint(address to, uint tokenId, uint numberOf) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId, numberOf,"");
    }

    function supportsInterface(bytes4 interfaceId) public override(AccessControl, ERC1155) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}

