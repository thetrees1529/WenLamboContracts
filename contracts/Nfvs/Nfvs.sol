// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./NfvBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Nfvs is NfvBase {

    using Counters for Counters.Counter;

    uint256 constant public MAX_LAMBOS = 10000;
    Counters.Counter private tokenIdCounter;

    constructor(string memory uri, string memory name, string memory symbol) Nft(uri, name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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