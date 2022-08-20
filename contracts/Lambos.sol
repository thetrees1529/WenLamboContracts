// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import "hardhat/console.sol";

contract Lambos is ERC721, ERC721Enumerable, Pausable, AccessControl {

    struct Rent {
        bool inProgress;
        address owner;
        uint endsAt;
    }

    using Counters for Counters.Counter;

    bytes32 public constant RENTER_ROLE = keccak256("RENTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private tokenIdCounter;
    string private baseUri;

    uint256 constant public MAX_LAMBOS = 10000;
    string[] private attributeKeys;
    mapping(uint => Rent) private _rents;

    error LamboDoesNotExist();

    constructor() ERC721("WenLambo", "LAMBO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(RENTER_ROLE, msg.sender);
        _setBaseURI("https://todo.wen.lambo/");
    }

    function mintOne(address to) public onlyRole(MINTER_ROLE) {
        _mintOne(to);
    }

    function mint(address to, uint numberOf) external {
        for(uint i; i < numberOf; i ++) mintOne(to);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    //renting
    function rentTo(uint tokenId, address to, uint endsAt) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(!rent.inProgress, "Currently rented.");
        address owner = ownerOf(tokenId);
        rent.owner = owner;
        rent.endsAt = endsAt;
        rent.inProgress = true;
        _transfer(owner, to, tokenId);
    }

    function cancelRent(uint tokenId) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not under rent.");
        rent.endsAt = block.timestamp;
    }

    function isUnderRent(uint tokenId) external view returns(bool) {
        return _rents[tokenId].inProgress;
    }

    function rentInfo(uint tokenId) external view returns(address originalOwner, address currentOwner, uint endsAt) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not rented currently.");
        return (rent.owner, ownerOf(tokenId), rent.endsAt);
    }

    function returnRented(uint tokenId) external {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Rent not in progress.");
        require(block.timestamp >= rent.endsAt, "Rent period not over.");
        rent.inProgress = false;
        _transfer(ownerOf(tokenId), rent.owner, tokenId);
    }

    // pausable and sale states

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setBaseURI(string memory _newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_newUri);
    }

    function _setBaseURI(string memory _newUri) private {
        baseUri = _newUri;
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

    //misc

    function _mintOne(address to) private {
        uint256 _tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(to, _tokenId);
    }

    // hooks / overrides

    function _mint(address to, uint tokenId) internal override {
        require(totalSupply() < MAX_LAMBOS, "Max supply reached.");
        super._mint(to, tokenId);
    }

    function _baseURI() internal override view returns(string memory) {
        return baseUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(!_rents[tokenId].inProgress, "Currently rented.");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}