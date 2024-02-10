// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./NfvBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Nfvs is NfvBase {

    using Counters for Counters.Counter;

    uint256 constant public MAX_LAMBOS = 10000;

    constructor(string memory uri, string memory name, string memory symbol) Nft(uri, name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function _mint(address to, uint tokenId) internal override {
        super._mint(to, tokenId);
        require(totalSupply() <= MAX_LAMBOS, "Max supply reached.");
    }

}