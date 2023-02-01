//SPDX-License-Identifier: UNLICENSED
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

pragma solidity 0.8.17;

contract Reflections2 is Ownable {
    using OwnerOf for IERC721;

    IERC721 public nfvs;
    IERC20 public token;
    uint private _lastBalance;
    uint private _checkpoint;
    struct Nfv {
        bool registered;
        uint debt;
    }
    mapping(uint => Nfv) private _nfvs;

    constructor(IERC721Enumerable nfvs_, IERC20 token_) {
        nfvs = nfvs_;
        token = token_;
    }

    function register(uint tokenId) external {
        update();
        Nfv storage nfv = _nfvs[tokenId];
        nfv.debt = _checkpoint;
        nfv.registered = true;
    }

    function update() public {
        uint pendingCheckpoint = _pendingCheckpoint();
        if(pendingCheckpoint > _checkpoint) _checkpoint = pendingCheckpoint;
    }

    function getOwed(uint tokenId) public view returns(uint) {
        try nfvs.ownerOf(tokenId) returns(address) {
        } catch {
            return 0;
        }
        Nfv storage nfv = _nfvs[tokenId];
        if(!nfv.registered) return 0;
        return _checkpoint - nfv.debt;
    }

    function claim(uint[] calldata tokenIds) external {
        for(uint i; i < tokenIds.length; i ++) claim(tokenIds[i]);
    }

    function claim(uint tokenId) public {
        update();
        require(nfvs.isOwnerOf(msg.sender, tokenId), "You don't own this one.");
        uint owed = getOwed(tokenId);
        token.transfer(msg.sender, owed);
        _lastBalance = token.balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }


    function _pendingCheckpoint() private view returns(uint) {
        uint balance = token.balanceOf(address(this));
        return _lastBalance == balance ? _checkpoint : _checkpoint + ((balance - _lastBalance) / IERC721Enumerable(address(nfvs)).totalSupply());
    }

}