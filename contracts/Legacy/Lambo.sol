// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ILambo.sol";

// import "hardhat/console.sol";

contract Lambos is ERC721, ERC721Enumerable, Pausable, AccessControl, ILambo {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RACE_MANAGER_ROLE = keccak256("RACE_MANAGER_ROLE");
    Counters.Counter private tokenIdCounter;
    string private baseUri;

    bool public isPreSale;

    struct PreSaleData {
        bool isListed;
        uint8 count;
    }
    mapping (address => PreSaleData) private presaleList;

    bool public isPublicSale;
    uint256 constant public MAX_LAMBOS = 10000;
    string[] private attributeKeys;
    mapping(uint256 => mapping(string => uint256)) private statistics; // token id => attribute name => counter
    mapping(uint256 => bytes) private licensePlates;

    error SaleNotStartedYet();
    error CannotSetPublicSaleBeforePreSale();
    error LamboDoesNotExist();
    error MoreThanMintAllowance();
    error AddressNotOnPreSaleList();
    error MaxPresaleMintsHit();
    error MaxLambosAlreadyExist();
    error InsufficientFundsSent();
    error AttributeAlreadyMaxLevel(uint256 tokenId, string attribute);
    error BadLicensePlate(uint256 tokenId, string newPlate);

    constructor() ERC721("WenLambo", "LAMBO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(RACE_MANAGER_ROLE, msg.sender);

        baseUri = "https://todo.wen.lambo/";

        // attribute/statistics information
        attributeKeys.push("power");
        attributeKeys.push("handling");
        attributeKeys.push("boost");
        attributeKeys.push("tires");

        // sales data
        isPreSale = false;
        isPublicSale = false;
    }

    // minting

    function mint(uint256 _amount) public payable {
        // revert checks
        if (!isPreSale && !isPublicSale) revert SaleNotStartedYet();
        if (totalSupply() + _amount > MAX_LAMBOS) revert MaxLambosAlreadyExist();
        if (_amount > 3) revert MoreThanMintAllowance();
        if (msg.value < (getMintPrice() * _amount)) revert InsufficientFundsSent();

        // presale rules only
        if (isPreSale && !isPublicSale) {
            if (!presaleList[msg.sender].isListed) revert AddressNotOnPreSaleList();
            if (presaleList[msg.sender].count + uint8(_amount) > 3) revert MaxPresaleMintsHit();
            presaleList[msg.sender].count += uint8(_amount);
        }

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenId);

            // set our token attributes here
            _setBaseStatistics(_tokenId);
        }
    }

    function ownerMint(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (totalSupply() + _amount > MAX_LAMBOS) revert MaxLambosAlreadyExist();

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_to, _tokenId);

            // set our token attributes here
            _setBaseStatistics(_tokenId);
        }
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

    // attributes

    function _setBaseStatistics(uint256 _tokenId) internal {
        statistics[_tokenId]["power"] = 0;
        statistics[_tokenId]["handling"] = 0;
        statistics[_tokenId]["boost"] = 0;
        statistics[_tokenId]["tires"] = 0;
        // added in a later phase?
        //statistics[_tokenId]["armour"] = 0;
        //statistics[_tokenId]["weapons"] = 0;
        statistics[_tokenId]["xp"] = 0;
        statistics[_tokenId]["racesTotal"] = 0;
        statistics[_tokenId]["racesWon"] = 0;
    }

    function getAttributes(uint256 _tokenId) public view returns (StatisticView[] memory) {
        if (_tokenId >= totalSupply()) revert LamboDoesNotExist();
        uint256 _statisticsCount = attributeKeys.length;
        StatisticView[] memory _stats = new StatisticView[](_statisticsCount);
        
        for (uint256 i = 0; i < _statisticsCount; i++) {
            uint256 _value = statistics[_tokenId][attributeKeys[i]];

            _stats[i] = StatisticView({
                statistic: attributeKeys[i],
                value: _value
            });
        }

        return _stats;
    }

    function addExp(uint256 _tokenId, string memory _attribute, uint256 _toAdd) external onlyRole(UPGRADER_ROLE) {
        statistics[_tokenId][_attribute] += _toAdd;

        emit ExperienceGranted(_tokenId, _attribute, _toAdd, statistics[_tokenId][_attribute]);
    }

    function finishedRace(uint256 _tokenId, uint256 _raceId, bool _won) external onlyRole(RACE_MANAGER_ROLE) {
        statistics[_tokenId]["racesTotal"] += 1;

        if (_won) {
            statistics[_tokenId]["racesWon"] += 1;
        }

        emit RaceWon(_tokenId, _raceId);
    }

    function getAttributeKeys() external view returns (string[] memory) {
        return attributeKeys;
    }

    function addNewAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        attributeKeys.push(_attribute);

        emit NewAttributeCreated(_attribute, block.number, block.timestamp);
    }

    function getLicensePlate(uint256 _tokenId) external view returns (string memory) {
        if (_tokenId > totalSupply()) {
            return "";
        }

        return string(licensePlates[_tokenId]);
    }


    function setLicensePlate(uint256 _tokenId, string memory _newPlate) external {
        if (!_isStringValid(_newPlate)) revert BadLicensePlate(_tokenId, _newPlate);

        licensePlates[_tokenId] = bytes(_newPlate);
    }

    // pausable and sale states

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function startPreSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPreSale = true;

        emit PreSaleStarted(block.number, block.timestamp);
    }

    function startPublicSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!isPreSale) revert CannotSetPublicSaleBeforePreSale();
        isPreSale = false;
        isPublicSale = true;

        emit PublicSaleStarted(block.number, block.timestamp);
    }

    function hasPresalesLeft(address _addr) external view returns (bool, uint256) {
        if (presaleList[_addr].isListed) {
            uint256 _mintCount = presaleList[_addr].count;
            return (
                _mintCount < 3,
                3 - _mintCount
            );
        } else {
            return (
                false,
                0
            );
        }
    }

    function addToPresaleList(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleList[_addr].count = 0;
        presaleList[_addr].isListed = true;
    }

    function addManyToPresaleList(address[] memory _addrs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _addrs.length; i++) {
            address _addr = _addrs[i];
            presaleList[_addr].count = 0;
            presaleList[_addr].isListed = true;
        }
    }

    function getMintPrice() public view returns (uint256) {
        if (isPreSale) {
            return 500 * 1e18; // 500 ONE
        } else if (!isPreSale && isPublicSale) {
            return 750 * 1e18; // 750 ONE
        } else {
            return 0;
        }
    }

    function setBaseURI(string memory _newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
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

    // hooks / overrides

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist yet");
        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint a)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, a);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // currency stuff
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function balance() public view returns (uint256) {
      return address(this).balance;
    }
}