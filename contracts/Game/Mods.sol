// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
// import "@thetrees1529/solutils/contracts/gamefi/OwnerOf.sol";
// import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "../Nfts/Toolboxes.sol";

// contract Mods is Nft, RandomConsumer {
//     using OwnerOf for IERC721;
//     using Counters for Counters.Counter;
//     using EnumerableSet for EnumerableSet.UintSet;

//     struct PerInput {
//         uint toolboxId;
//         uint per;
//     }
//     struct Mod {
//         uint attributeId;
//         uint value;
//     }
//     struct Option {
//         uint attributeId;
//         uint weighting;
//     }
//     struct Request {
//         uint value;
//         address receiver;
//     }
//     struct RequestInput {
//         uint toolboxId;
//         uint numberOf;
//     }
//     struct AttributeConfig {
//         string name;
//         uint maxPerCar;
//     }
//     struct RedeemInput {
//         uint tokenId;
//         uint modId;
//     }
//     struct AttributeCarView {
//         string attribute;
//         uint value;
//     }
//     mapping(address => Mod[]) private _history;
//     Option[] private _options;
//     uint[] private _weightings;

//     Toolboxes public toolboxes;
     
//     mapping(uint => uint) public perToolbox;
//     mapping(uint => Request) private _requests;
//     mapping(uint => Mod) private _mods;
//     mapping(uint => mapping(string => uint)) private _values;
//     AttributeConfig[] private _attributeConfigs;
//     bytes32 public constant MODS_ROLE = keccak256("MODS_ROLE");
//     IERC721 public nfvs;

//     Counters.Counter private _nextTokenId;

//     constructor(Toolboxes toolboxes_, IRandom random_, string memory name, string memory symbol, string memory uri, Option[] memory options, PerInput[] memory perInputs, AttributeConfig[] memory attributeConfigs, IERC721 nfvs_) ERC721(name,symbol) Nft(uri) RandomConsumer(random_) {
//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _setOptions(options);
//         for(uint i; i < perInputs.length; i ++) {
//             _setPerToolbox(perInputs[i]);
//         }
//         toolboxes = toolboxes_;
//         _setAttributeConfigs(attributeConfigs);
//         nfvs = nfvs_;
//     }

//     function getHistory(address from, uint numberOf) external view returns(Mod[] memory history) {
//         Mod[] storage history_ = _history[from];
//         numberOf = numberOf <= history_.length ? numberOf : history_.length;
//         history = new Mod[](numberOf);
//         uint start = history_.length - numberOf;
//         for(uint i = start; i < history_.length; i ++) {
//             history[i - start] = history_[i];
//         }

//     }

//     function getAttributeConfigs() external view returns(AttributeConfig[] memory) {
//         return _attributeConfigs;
//     }

//     function getAttributeKeys() external view returns(string[] memory keys) {
//         keys = new string[](_attributeConfigs.length);
//         for(uint i; i < keys.length; i ++) {
//             keys[i] = _attributeConfigs[i].name;
//         }
//     }

//     function setAttributeConfigs(AttributeConfig[] calldata attributeConfigs) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         _setAttributeConfigs(attributeConfigs);
//     }

//     function setPerToolbox(PerInput memory perInput) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         _setPerToolbox(perInput);
//     }

//     function getMod(uint modId) external view returns(Mod memory) {
//         require(_exists(modId), "Mod does not exist");
//         return _mods[modId];
//     }

//     function burnToolboxes(RequestInput[] calldata requestInputs) external {
//         for(uint i; i < requestInputs.length; i ++) {
//             RequestInput calldata input = requestInputs[i];
//             toolboxes.burn(msg.sender, input.toolboxId, input.numberOf);
//             for(uint j; j < input.numberOf; j ++) {
//                 _requests[random.requestRandom(_weightings)] = Request(perToolbox[input.toolboxId], msg.sender);
//             }
//         }
//     }

//     function redeemMods(RedeemInput[] calldata redeemInputs) external {
//         for(uint i; i < redeemInputs.length; i ++) {
//             require(ownerOf(redeemInputs[i].modId) == msg.sender, "You don't own this mod.");
//             require(nfvs.isOwnerOf(msg.sender, redeemInputs[i].tokenId));
//             _burn(redeemInputs[i].modId);
//             Mod storage mod = _mods[redeemInputs[i].modId];
//             uint current = _values[redeemInputs[i].tokenId][_attributeConfigs[mod.attributeId].name];
//             uint theoretical = current + mod.value;
//             uint n = theoretical <= _attributeConfigs[mod.attributeId].maxPerCar ? theoretical : _attributeConfigs[mod.attributeId].maxPerCar;
//             _values[redeemInputs[i].tokenId][_attributeConfigs[mod.attributeId].name] = n;
//         }
//     }

//     function setExp(uint256 tokenId, string memory attribute, uint256 value) external onlyRole(MODS_ROLE) {
//         _values[tokenId][attribute] = value;
//     }

//     function getExp(uint tokenId, string memory attribute) external view returns(uint) {
//         return _values[tokenId][attribute];
//     }

//     function getAttributes(uint tokenId) external view returns(AttributeCarView[] memory result) {
//         result = new AttributeCarView[](_attributeConfigs.length);
//         for(uint i; i < result.length; i ++) {
//             result[i] = AttributeCarView(_attributeConfigs[i].name, _values[tokenId][_attributeConfigs[i].name]);
//         }
//     }

//     function _setAttributeConfigs(AttributeConfig[] memory attributeConfigs) private {
//         delete _attributeConfigs;
//         for(uint i; i < attributeConfigs.length; i ++) {
//             _attributeConfigs.push(attributeConfigs[i]);
//         }
//     }

//     function _fulfillRandom(uint requestId, uint result) internal override {
//         uint tokenId = _nextTokenId.current();
//         _nextTokenId.increment();

//         Request storage request = _requests[requestId];
//         _mint(request.receiver, tokenId);

//         _mods[tokenId] = Mod(_options[result].attributeId, request.value);
//         _history[request.receiver].push(Mod(_options[result].attributeId, request.value));
//     }

//     function _setPerToolbox(PerInput memory perInput) private {
//         perToolbox[perInput.toolboxId] = perInput.per;
//     }

//     function _setOptions(Option[] memory options) private {
//         delete _options;
//         delete _weightings;
//         for(uint i; i < options.length; i ++) {
//             _options.push(options[i]);
//             _weightings.push(options[i].weighting);
//         }
//     }

// }