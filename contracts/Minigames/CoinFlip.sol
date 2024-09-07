//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "../Utils/Randomness.sol";
import "../Token/Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable, Randomness {

    Token private _token;
    uint private _maxBet = 2;
    uint private _feeOnWin = 3;

    constructor(Token token, address wrapper)
        Randomness(wrapper)
    {
        _token = token;
    }

    enum Result {
        Heads,
        Tails
    }

    struct Game {
        address player;
        uint bet;
        bool flipped;
        uint winnings;
        Result guess;
        Result result;
    }

    mapping(uint => Game) private _requestToGames;
    uint[] private _requests;

    function getInfo() external view returns(Token token, uint maxBet, uint feeOnWin, uint gameCount) {
        return (_token, _maxBet, _feeOnWin, _requests.length);
    }

    function getGames(uint start, uint end) external view returns(Game[] memory games) {
        require(start < _requests.length && end < _requests.length);
        games = new Game[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            games[i - start] = _requestToGames[_requests[i]];
        }
    }

    function flip(Result guess, uint amount) external payable {
        require(amount <= (_maxBet * _token.balanceOf(address(this))) / 100);
        uint id = _requestRandomNumber();
        _requestToGames[id] = Game(msg.sender, amount, false, 0, guess, Result.Heads);
        _requests.push(id);
        _token.transferFrom(msg.sender, address(this), amount);
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _receiveRandomNumber(uint requestId, uint randomNumber) internal override {
        Game storage game = _requestToGames[requestId];
        game.result = Result(randomNumber % 2);
        game.flipped = true;
        if (game.guess == game.result) {
            uint proceeds = game.bet * 2;
            uint fee = (proceeds * _feeOnWin) / 100;
            game.winnings = proceeds - fee;
            _token.transfer(game.player, game.winnings);
            _token.burn(fee);
        }
    }

    function withdraw(uint amount) external onlyOwner {
        _token.transfer(msg.sender, amount);
    }

}