//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "./Token.sol";
contract TokenMerge {
    uint public constant ONE_TOKEN = 1e18; 
    struct Option {
        Token token;
        uint perToken;
    }
    Token public newToken;
    Option[] private _options;
    constructor(Token newToken_, Option[] memory items) {
        newToken = newToken_;
        for(uint i; i < items.length; i ++) {
            _options.push(items[i]);
        }
    }
    function getOptions() external view returns(Option[] memory items) {
        return _options;
    }
    //dont convert to wei the token is assumed to be 18 decimals in the contract and only whole numbers can be input
    function merge(uint numberOfTokens, uint optionId) external {
        Option storage option = _options[optionId];
        uint toMint = _convert(_quote(numberOfTokens, option)); 
        option.token.burnFrom(msg.sender, _convert(numberOfTokens));
        newToken.mintTo(msg.sender, toMint);
    }
    function quote(uint numberOfTokens, uint optionId) external view returns(uint) {
        return _quote(numberOfTokens, _options[optionId]);
    }
    function _quote(uint numberOfTokens, Option storage option) private view returns(uint) {
        return (numberOfTokens / option.perToken);
    }
    function _convert(uint value) private pure returns(uint) {
        return value * ONE_TOKEN;
    }

}