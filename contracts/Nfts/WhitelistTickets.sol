//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

contract WhitelistTickets is Nft {
    using Counters for Counters.Counter;
    constructor(string memory name, string memory symbol, string memory baseURI) Nft( baseURI, name, symbol){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }
    // function supportsInterface(bytes4 interfaceId) public override(ERC721Enumerable, AccessControl) view returns(bool) {
    //     return super.supportsInterface(interfaceId);
    // }
    Counters.Counter private _nextTokenId;

    function burn(address from, uint numberOf) external {
        for(uint i; i < numberOf; i ++) burnOne(from);
    }

    function mintOne(address account) public onlyRole(MINTER_ROLE) {
        _mintOne(account);
    }
    function burnOne(address from) public onlyRole(BURNER_ROLE) {
        _burnOne(from);
    }

    function _mintOne(address to) private {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
    }
    function _burnOne(address from) private {
        uint tokenId = tokenOfOwnerByIndex(from, balanceOf(from) - 1);
        _burn(tokenId);
    }
    function _getNextTokenId() private returns(uint tokenId) {
        tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        return tokenId;
    }
}