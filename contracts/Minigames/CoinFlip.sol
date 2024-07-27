//SPDX-License-Idenfifier: Unlicensed
pragma solidity 0.8.19;
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract CoinFlip is Ownable, VRFV2WrapperConsumerBase {

    using ERC20Payments for IERC20;

    enum Result {
        UNDECIDED,
        HEADS,
        TAILS
    }

    enum Guess {
        HEADS,
        TAILS
    }

    struct Game {
        address player;
        uint bet;
        uint toWin;
        Guess guess;
        Result result;
    }

    //VRF
    uint32 public gasLimit;
    uint16 public confirmations;
    address public LINK;
    IUniswapV2Router02 public router;

    Game[] private games;
    IERC20 public token;
    uint public feePercentage;
    uint public maxBetPercentage;
    address public feeRecipient;

    mapping(uint => Game) private _requestToGame;

    constructor(address wrapper, uint32 gasLimit_, uint16 confirmations_, address LINK_, IUniswapV2Router02 router_, IERC20 token_, uint feePercentage_, uint maxBetPercentage_, address feeRecipient_) VRFV2WrapperConsumerBase(LINK_, wrapper_) {
        wrapper = wrapper_;
        gasLimit = gasLimit_;
        confirmations = confirmations_;
        LINK = LINK_;
        router = router_;
        
        token = token_;
        feePercentage = feePercentage_;
        maxBetPercentage = maxBetPercentage_;
        feeRecipient = feeRecipient_;
    }

    function quoteToWin(uint betAmount) public view returns(uint fee, uint toWin) {
        fee = (betAmount * feePercentage) / 100;
        toWin = (betAmount - fee) * 2;
    }

    function flip(uint bet, Guess guess) external {
        require(bet <= (token.balanceOf(address(this)) * maxBetPercentage) / 100, "Bet is too high");
        (uint fee, uint toWin) = quoteToWin(bet);
        token.sendFrom(msg.sender, address(this), bet - fee);
        token.sendFrom(msg.sender, feeRecipient, fee);
        _requestToGame[requestRandomness(gasLimit, confirmations, 1)] = _games.push(Game(msg.sender, bet, toWin, guess, Result.UNDECIDED));
    }

    function fulfillRandomness(bytes32 requestId, uint[] memory randomWords) internal override {
        Game storage _game = _requestToGame[requestId];
        _game.result = randomWords[0] % 2 == 0 ? Result.HEADS : Result.TAILS;
        if(_game.result == Result.HEADS && _game.guess == Guess.HEADS || _game.result == Result.TAILS && _game.guess == Guess.TAILS) {
            token.transfer(_game.player, _game.toWin);
        }
    }

    function withdraw(uint amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    

}