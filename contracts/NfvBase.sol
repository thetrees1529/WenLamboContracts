// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import "hardhat/console.sol";

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";

abstract contract NfvBase is ERC721Royalty, Nft, ERC1155Holder, Pausable {

    struct Rent {
        bool inProgress;
        address owner;
        uint endsAt;
    }

    using Counters for Counters.Counter;

    bytes32 public constant RENTER_ROLE = keccak256("RENTER_ROLE");
    bytes32 public constant EQUIPPER_ROLE = keccak256("EQUIPPER_ROLE");
    Counters.Counter private tokenIdCounter;
    string private baseUri;

    string[] private attributeKeys;
    mapping(uint => Rent) private _rents;

    constructor() {
    }

    function setRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
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
    function rentTo(uint tokenId, address to, uint period) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(!rent.inProgress, "Currently rented.");
        address owner = ownerOf(tokenId);
        rent.owner = owner;
        rent.endsAt = block.timestamp + period;
        _transfer(owner, to, tokenId);
        rent.inProgress = true;
    }

    function cancelRent(uint tokenId) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not under rent.");
        rent.endsAt = block.timestamp;
    }

    function isUnderRent(uint tokenId) external view returns(bool) {
        return _rents[tokenId].inProgress;
    }

    function rentInfo(uint tokenId) external view returns(address originalOwner, uint endsAt) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Not rented currently.");
        return (rent.owner, rent.endsAt);
    }

    function returnRented(uint tokenId) external onlyRole(RENTER_ROLE) {
        Rent storage rent = _rents[tokenId];
        require(rent.inProgress, "Rent not in progress.");
        require(block.timestamp >= rent.endsAt, "Rent period not over.");
        rent.inProgress = false;
        _transfer(ownerOf(tokenId), rent.owner, tokenId);
    }


    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    // hooks / overrides

    function _baseURI() internal virtual override(ERC721, Nft) view returns(string memory) {
        return super._baseURI();
    }

    function _transfer(address from, address to, uint tokenId) internal virtual whenNotPaused override {
        super._transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        require(!_rents[tokenId].inProgress, "Currently rented.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, ERC1155Receiver, Nft)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint tokenId) internal virtual override(ERC721, ERC721Royalty) {
        return super._burn(tokenId);
    }

}