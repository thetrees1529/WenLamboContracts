//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IFarmWatcher.sol";

contract NftHoldersBoost is IFarmWatcher {

    struct Nft {
        uint tokenId;
        address tiedTo;
    }

    struct User {
        bool qualified;
        uint debt;
        uint[] tokenIds;
    }

    IERC721Enumerable public nft;
    uint public qualifiedCount;
    mapping(address => User) users;

    constructor(IERC721Enumerable nft_) {
        nft = nft_;
    }

    function deposited(address addr, uint amount) external override {
    }

    function withdrawn(address addr, uint amount) external override {
    }

    function claimed(address addr, uint amount) external override {
    }
}