// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Bridgeable.sol";
import "./NfvBase.sol";

contract NfvsBridged is NfvBase, Bridgeable {

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name, string memory symbol) NfvBase(name, symbol) {}

    function mintTokenId(address to, uint tokenId) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function burnTokenId(uint tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public override(Bridgeable, NfvBase) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }

}