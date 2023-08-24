//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

contract FreeMint {
    Nft public nft;

    constructor(address _nft) {
        nft = Nft(_nft);
    }

    function mint() external returns (uint256 ){
        uint[] memory tokenIds = nft.mint(msg.sender, 1);
        return tokenIds[0];
    }
}