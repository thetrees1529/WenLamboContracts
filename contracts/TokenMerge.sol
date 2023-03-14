//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "./Token.sol";
contract TokenMerge {
    uint public constant ONE_TOKEN = 1e18; 
    struct Item {
        Token token;
        uint perToken;
    }
    Token public newToken;
    Item[] private _items;
    constructor(Item[] memory items) {
        for(uint i; i < items.length; i ++) {
            _items.push(items[i]);
        }
    }
    function getItems() external view returns(Item[] memory items) {
        return _items;
    }
    function merge(uint into) external {
        for(uint i; i < _items.length; i ++) {
            Item storage item = _items[i];
            uint toBurn = (item.perToken * into) / ONE_TOKEN;
            item.token.burnFrom(msg.sender, toBurn);
        }
        newToken.mintTo(msg.sender, into);
    }

}