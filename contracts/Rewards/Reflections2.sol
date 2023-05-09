//SPDX-License-Identifier: UNLICENSED
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

pragma solidity 0.8.19;

contract Reflections2 is Ownable {
    using OwnerOf for address;

    IERC721 public nfvs;
    IERC20 public token;
    uint private _lastBalance;
    uint private _checkpoint;
    uint private _registered;
    struct Nfv {
        bool registered;
        uint debt;
    }
    mapping(uint => Nfv) private _nfvs;

    constructor(IERC721Enumerable nfvs_, IERC20 token_) {
        nfvs = nfvs_;
        token = token_;
    }

    function register(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) register(tokenIds[i]);
    }

    function register(uint tokenId) public {
        require(msg.sender.isOwnerOf(nfvs, tokenId), "You don't own this one.");
        update();
        Nfv storage nfv = _nfvs[tokenId];
        nfv.debt = _checkpoint;
        nfv.registered = true;
        _registered ++;
    }

    function update() public {
        uint balance = token.balanceOf(address(this));
        if(balance > _lastBalance) {
            uint toSplit = balance - _lastBalance;
            uint eachGets = toSplit / _registered;
            _checkpoint += eachGets;
        }
    }

    function owed(uint tokenId) public view returns(uint) {
        Nfv storage nfv = _nfvs[tokenId];
        if(!nfv.registered) return 0;
        return _checkpoint - nfv.debt;
    }

    function claim(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) claim(tokenIds[i]);
    }

    function claim(uint tokenId) public {
        update();
        require(msg.sender.isOwnerOf(nfvs, tokenId), "You don't own this one.");
        uint owed_ = owed(tokenId);
        token.transfer(msg.sender, owed_);
        _lastBalance -= owed_;
    }

    function emergencyWithdraw() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}