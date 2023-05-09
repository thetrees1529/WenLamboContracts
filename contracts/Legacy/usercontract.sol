// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract NFT {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract LamboAvatars {
    using Counters for Counters.Counter;
    using Strings for uint256;

    NFT lamboContract;

    struct AvatarStruct {
        address user;
        string userName;
        uint256 lamboId;
        bool lamboSet;
        bool userExists;
    }

    Counters.Counter public userCounter;
    mapping(address => AvatarStruct) private avatar;
    mapping(uint256 => address) private avatarMap;

    error BadName(string userName);

    constructor(address _lamboAddress) {
        lamboContract = NFT(_lamboAddress);
    }

    function selectAvatar(uint256 _id) external {
        require(avatar[msg.sender].userExists == true, 'This user does not exist yet.');
        require(lamboContract.ownerOf(_id) == msg.sender, 'This is not your Lambo.');
        require(avatar[msg.sender].lamboId != _id, 'You already use this Lambo as avatar.');

        avatar[msg.sender].lamboId = _id;
        avatar[msg.sender].lamboSet = true;
        avatar[msg.sender].user = msg.sender;
    }

    function setUser(string memory _userName) external {
        require(!avatar[msg.sender].userExists, 'This user already exists.');
        if (!_isStringValid(_userName)) revert BadName(_userName);

        avatar[msg.sender].userName = _userName;
        avatar[msg.sender].user = msg.sender;
        avatar[msg.sender].userExists = true;

        userCounter.increment();
    }

    function removeUser() public {
        delete avatar[msg.sender];
        userCounter.decrement();
    }

    // util
    function _isStringValid(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3 || b.length > 10) 
            return false;

        for(uint256 i; i < b.length; i++){
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) // (space)
            )
                return false;
        }

        return true;
    }

    function getAvatar(address _address) public view returns (uint256 lamboId, bool lamboSet) {
        if (lamboContract.ownerOf(avatar[_address].lamboId) == _address && avatar[_address].user == _address) {
            return (avatar[_address].lamboId, avatar[_address].lamboSet);
        } else {
            return (99999, avatar[_address].lamboSet);
        }
    }

    function getName(address _address) public view returns (string memory userName) {
        if (avatar[_address].user == _address) {
            return (avatar[_address].userName);
        } else {
            return ('');
        }
    }
}