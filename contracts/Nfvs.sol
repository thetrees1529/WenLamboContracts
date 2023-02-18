// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./NfvBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Nfvs is NfvBase {

    using Counters for Counters.Counter;

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant public MAX_LAMBOS = 10000;
    Counters.Counter private tokenIdCounter;

    constructor(string memory name, string memory symbol, string memory uri) ERC721(name,symbol) Nft( uri) {}

    //mintTo preferred but oh well
    function mint(address to, uint numberOf) external onlyRole(MINTER_ROLE) {
        for(uint i; i < numberOf; i++) _mintOne(to);
    }

    function _mintOne(address to) private {
        uint tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _mint(to, tokenId);
    }

    function _mint(address to, uint tokenId) internal override {
        super._mint(to, tokenId);
        require(totalSupply() <= MAX_LAMBOS, "Max supply reached.");
    }

}