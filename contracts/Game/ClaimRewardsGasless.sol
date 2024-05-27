//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Token/Token.sol";

contract ClaimRewardsGasless is Ownable {

    using ECDSA for bytes32;

    struct ClaimInput {
        address to;
        uint amount;
        bytes32 salt;
        bytes signature;
    }

    struct CheckClaimedInput {
        address to;
        bytes32 salt;
    }

    address private _signer;
    Token private _token;
    mapping(address => mapping(bytes32 => bool)) private _claimed;

    constructor(address signer, Token token) {
        _setSigner(signer);
        _token = token;
    }

    function getInfo() external view returns(address signer, Token token, uint chainId) {
        return (_signer, _token, block.chainid);
    }

    function checkClaimed(CheckClaimedInput[] calldata inputs) external view returns(bool[] memory) {
        bool[] memory result = new bool[](inputs.length);
        for(uint i; i < inputs.length; i++) {
            CheckClaimedInput calldata input = inputs[i];
            result[i] = _claimed[input.to][input.salt];
        }
        return result;
    }

    function redeem(ClaimInput[] calldata inputs) external {
        for(uint i; i < inputs.length; i++) {
            ClaimInput calldata input = inputs[i];
            require(!_claimed[input.to][input.salt], "ClaimRewardsGasless: Already claimed");
            require(keccak256(abi.encodePacked(address(this), block.chainid, input.to, input.amount, input.salt)).toEthSignedMessageHash().recover(input.signature) == _signer, "ClaimRewardsGasless: Invalid signature");
            _claimed[input.to][input.salt] = true;
            _token.mintTo(input.to, input.amount);
        }
    }

    function setSigner(address newSigner) external onlyOwner {
        _setSigner(newSigner);
    }

    function _setSigner(address newSigner) internal {
        _signer = newSigner;
    }

}