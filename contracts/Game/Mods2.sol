// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Nfts/Toolboxes2.sol";
import "../Nfvs/Nfvs.sol";

contract Mods is Nft, RandomConsumer {
    using OwnerOf for address;

    struct AttributeView {
        string attribute;
        uint value;
    }

    struct NfvView {
        uint tokenId;
        AttributeView[] attributes;
    }

    struct Config {
        string name;
        uint weighting;
    }

    struct Redeem {
        uint toolboxId;
        uint nfvId;
    }

    struct Request {
        uint value;
        address from;
    }

    struct MaxPerCarInput {
        string name;
        uint maxPerCar;
    }

    struct ValuePerToolboxInput {
        string name;
        uint value;
    }

    struct Mod {
        string attributeName;
        uint value;
    }

    struct ModView {
        uint tokenId;
        Mod mod;
    }

    struct Create {
        address to;
        Mod mod;
    }

    struct ModInput {
        uint modId;
        uint nfvId;
    }

    Toolboxes public toolboxes;
    Nfvs public nfvs;

    string[] private _attributeList;

    mapping(uint => mapping(string => uint)) private _attributeValues;

    mapping(string => uint) public maxPerCar;

    mapping(string => uint) public valuePerToolbox;

    mapping(uint => Request) private _requests;

    mapping(uint => Mod) public mods;

    mapping(address => uint[]) private _history;

    Config[] private _config;
    uint[] private _options;

    uint private _nextTokenId;

    constructor(string memory name, string memory symbol, string memory uri, Toolboxes toolboxes_, IRandom random, Nfvs nfvs_, MaxPerCarInput[] memory maxPerCars_, string[] memory attributeList, Config[] memory config, ValuePerToolboxInput[] memory valuePerToolboxes) ERC721(name, symbol) Nft(uri) RandomConsumer(random) {
        _init(maxPerCars_, attributeList, config, valuePerToolboxes);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        toolboxes = toolboxes_;
        nfvs = nfvs_;
    }

    function getAttributeList() external view returns(string[] memory res) {
        res = _attributeList;
    }

    function getHistoryOf(address user, uint skip, uint count) external view returns(Mod[] memory res) {
        count = _history[user].length <= skip ? 0 : count > _history[user].length - skip ? _history[user].length - skip : count;
        res = new Mod[](count);
        for(uint i = 1; i <= count; i ++) {
            res[i] = mods[_history[user][_history[user].length - i - skip]];
        }
    }

    function getAllModsOf(address user) external view returns(ModView[] memory res) {
        uint[] memory tokenIds = new uint[](balanceOf(user));
        res = new ModView[](tokenIds.length);
        for(uint i; i < tokenIds.length; i ++) {
            res[i] = ModView({tokenId: tokenOfOwnerByIndex(user, i), mod: mods[tokenOfOwnerByIndex(user, i)]});
        }
    }

    function getAllNfvsOf(address user) external view returns(NfvView[] memory res) {
        uint[] memory tokenIds = new uint[](nfvs.balanceOf(user));
        res = new NfvView[](tokenIds.length);
        for(uint i; i < tokenIds.length; i ++) {
            res[i] = getNfv(nfvs.tokenOfOwnerByIndex(user, i));
        }
    }

    function getNfv(uint tokenId) public view returns(NfvView memory res) {
        res.tokenId = tokenId;
        res.attributes = new AttributeView[](_attributeList.length);
        for(uint i; i < _attributeList.length; i ++) {
            res.attributes[i] = AttributeView({attribute: _attributeList[i], value: _attributeValues[tokenId][_attributeList[i]]});
        }
    }

    function init(MaxPerCarInput[] memory maxPerCars_, string[] memory attributeList, Config[] memory config, ValuePerToolboxInput[] memory valuePerToolboxes) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _init(maxPerCars_, attributeList, config, valuePerToolboxes);
    }

    function burnToolboxesForMods(uint[] calldata toolboxes_) external {
        for(uint i; i < toolboxes_.length; i ++) {
            uint toolboxId = toolboxes_[i];
            require(msg.sender.isOwnerOf(IERC721(address(toolboxes)), toolboxId));
            toolboxes.burn(toolboxId);
            _requests[_requestRandom(_options)] = Request({value: valuePerToolbox[toolboxes.toolboxes(toolboxId)], from: msg.sender});
        }
    }

    function mintMods(Create[] memory creates) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint i; i < creates.length; i ++) {
            _mintTo(creates[i]);
        }
    }

    function applyMods(ModInput[] calldata mods_) external {
        for(uint i; i < mods_.length; i ++) {
            Mod memory mod = mods[mods_[i].modId];
            require(msg.sender.isOwnerOf(IERC721(address(this)), mods_[i].modId));
            _burn(mods_[i].modId);
            uint current = _attributeValues[mods_[i].nfvId][mod.attributeName];
            uint theoretical = current + mod.value;
            _attributeValues[mods_[i].nfvId][mod.attributeName] = theoretical >= maxPerCar[mod.attributeName] ? maxPerCar[mod.attributeName] : theoretical;
        }
    }

    function _fulfillRandom(uint requestId, uint result) internal override {
        Request storage request = _requests[requestId];
        Config storage config = _config[result];
        Mod memory mod = Mod({attributeName: config.name, value: request.value});
        uint tokenId = _mintTo(Create({to: request.from, mod: mod}));
        _history[request.from].push(tokenId);
    }

    function _mintTo(Create memory create) private returns(uint tokenId) {
        tokenId = _nextTokenId;
        _nextTokenId ++;
        mods[tokenId] = create.mod;
        _mint(create.to, tokenId);
    }

    function _init(MaxPerCarInput[] memory maxPerCars_, string[] memory attributeList, Config[] memory config, ValuePerToolboxInput[] memory valuePerToolboxes) private {
        for(uint i; i < maxPerCars_.length; i ++) {
            maxPerCar[maxPerCars_[i].name] = maxPerCars_[i].maxPerCar;
        }
        for(uint i; i < valuePerToolboxes.length; i ++) {
            valuePerToolbox[valuePerToolboxes[i].name] = valuePerToolboxes[i].value;
        }
        _attributeList = attributeList;
        delete _config;
        delete _options;
        for(uint i; i < config.length; i ++) {
            _config.push(config[i]);
            _options.push(config[i].weighting);
        }
    }

}