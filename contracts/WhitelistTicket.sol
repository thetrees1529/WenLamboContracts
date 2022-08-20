//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import { ERC721, ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

contract WhitelistTicket is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _URI = baseURI;
    }
    function supportsInterface(bytes4 interfaceId) public override(ERC721Enumerable, AccessControl) view returns(bool) {
        return super.supportsInterface(interfaceId);
    }
    Counters.Counter private _nextTokenId;
    string private _URI;

    function mint(address account, uint numberOf) external {
        for(uint i; i < numberOf; i ++) mintOne(account);
    }
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
    function _baseURI() internal override view returns(string memory) {
        return _URI;
    }
}