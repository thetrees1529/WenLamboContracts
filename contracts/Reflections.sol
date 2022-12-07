//SPDX-License-Identifier: UNLICENSED
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

pragma solidity 0.8.17;

contract Reflections is Ownable {
    using OwnerOf for IERC721;

    IERC721Enumerable public car;
    uint public constant SPLIT_BETWEEN = 10000;
    mapping(address => uint) public collectedByAddress;

    constructor(IERC721Enumerable car_) {
        car = car_;
    }


    struct Token {
        uint lastBalance;
        uint totalReceived;
        mapping(uint => uint) collected;
    }

    struct CollectInput {
        uint tokenId;
        IERC20 token;
    }

    mapping(IERC20 => Token) private _tokens;

    function owedToWallet(address wallet, IERC20 token) external view returns(uint owedTo) {
        uint[] memory tokens = _getOwnedTokens(wallet);
        for(uint i; i < tokens.length; i ++) owedTo += owed(tokens[i], token);
    }

    function collectFromAllOwned(address wallet, IERC20 token) external {
        uint[] memory tokens = _getOwnedTokens(wallet);
        for(uint i; i < tokens.length; i ++) collect(CollectInput(tokens[i], token));
    }

    function owed(uint tokenId, IERC20 token) public view returns(uint) {
        mapping(uint => uint) storage collected = _tokens[token].collected;
        (uint totalReceived,) = _pendingTotalReceivedAndBalance(token);
        uint lifetimeOwed = totalReceived / SPLIT_BETWEEN;
        return lifetimeOwed - collected[tokenId];
    }

    function collect(CollectInput memory input) public onlyOwnerOf(input.tokenId) update(input.token) {
        uint toPay = owed(input.tokenId, input.token);
        Token storage data = _tokens[input.token];
        data.collected[input.tokenId] += toPay;
        data.lastBalance -= toPay;
        input.token.transfer(msg.sender, toPay);
        collectedByAddress[msg.sender] += toPay;
    }

    function getTotalCollected(uint tokenId, IERC20 token) external view returns(uint) {
        return _tokens[token].collected[tokenId];
    }

    function getTotalReceived(IERC20 token) external view returns(uint totalReceived) {
        (totalReceived,) = _pendingTotalReceivedAndBalance(token);
    }

    function collectMultiple(CollectInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) collect(inputs[i]);
    }

    function getTotalDistributed(IERC20 token) external view returns(uint) {
        (uint totalReceived,) = _pendingTotalReceivedAndBalance(token);
        return totalReceived - token.balanceOf(address(this));
    }

    function _update(IERC20 token) private {
        Token storage data = _tokens[token];
        (uint totalReceived, uint balance) = _pendingTotalReceivedAndBalance(token);
        data.lastBalance = balance;
        data.totalReceived = totalReceived;
    }

    function _pendingTotalReceivedAndBalance(IERC20 token) private view returns(uint totalReceived, uint balance) {
        Token storage data = _tokens[token];
        balance = token.balanceOf(address(this));
        uint toAdd = balance - data.lastBalance;
        totalReceived = data.totalReceived + toAdd;
    }

    function _getOwnedTokens(address addr) private view returns(uint[] memory tokens) {
        tokens = new uint[](car.balanceOf(addr));
        for(uint i; i < tokens.length; i ++) {
            tokens[i] = car.tokenOfOwnerByIndex(addr, i);
        }
    }

    function emergencyWithdraw(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(IERC721(car).isOwnerOf(msg.sender, tokenId), "Incorrect owner.");
        _;
    }

    modifier update(IERC20 token) {
        _update(token);
        _;
    }

}