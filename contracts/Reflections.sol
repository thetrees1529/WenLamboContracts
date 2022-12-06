//SPDX-License-Identifier: UNLICENSED
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.17;

contract Reflections is Ownable {
    using OwnerOf for IERC721;

    IERC721 public car;
    uint public constant SPLIT_BETWEEN = 10000;

    constructor(IERC721 car_) {
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

    function owed(uint tokenId, IERC20 token) public view returns(uint) {
        mapping(uint => uint) storage collected = _tokens[token].collected;
        (uint totalReceived,) = _pendingTotalReceivedAndBalance(token);
        uint lifetimeOwed = totalReceived / SPLIT_BETWEEN;
        return lifetimeOwed - collected[tokenId];
    }

    function collect(CollectInput calldata input) public onlyOwnerOf(input.tokenId) update(input.token) {
        uint toPay = owed(input.tokenId, input.token);
        Token storage data = _tokens[input.token];
        data.collected[input.tokenId] += toPay;
        data.lastBalance -= toPay;
        input.token.transfer(msg.sender, toPay);
    }

    function getTotalCollected(uint tokenId, IERC20 token) external view returns(uint) {
        return _tokens[token].collected[tokenId];
    }

    function collectMultiple(CollectInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i ++) collect(inputs[i]);
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

    function emergencyWithdraw(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwnerOf(uint tokenId) {
        require(car.isOwnerOf(msg.sender, tokenId), "Incorrect owner.");
        _;
    }

    modifier update(IERC20 token) {
        _update(token);
        _;
    }

}