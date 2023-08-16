//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

contract FreeMint {
    Nft public nft;

    constructor(address _nft) {
        nft = Nft(_nft);
    }

    function mint() external {
        nft.mint(msg.sender, 1);
    }
}