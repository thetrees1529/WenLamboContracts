// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Attributes is AccessControl {

    struct AttributeView {
        string statistic;
        uint256 value;
    }

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        // attribute/statistics information
        _addNewAttribute("power");
        _addNewAttribute("handling");
        _addNewAttribute("boost");
        _addNewAttribute("tires");
    }

    string[] private attributeKeys;
    mapping(uint => mapping(string => uint)) private statistics;

    function getAttributes(uint256 _tokenId) public view returns (AttributeView[] memory) {
        uint256 _statisticsCount = attributeKeys.length;
        AttributeView[] memory _stats = new AttributeView[](_statisticsCount);
        for (uint256 i = 0; i < _statisticsCount; i++) {
            uint256 _value = getAttribute(_tokenId,attributeKeys[i]);
            _stats[i] = AttributeView({
                statistic: attributeKeys[i],
                value: _value
            });
        }
        return _stats;
    }

    function getAttribute(uint _tokenId, string memory attribute) public view returns(uint) {
        (bool exists,) = _attributeExists(attribute);
        require(exists, "Attribute doesn't exist.");
        return statistics[_tokenId][attribute];
    }

    function addNewAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        _addNewAttribute(_attribute);
    }

    function removeAttribute(string memory _attribute) external onlyRole(UPGRADER_ROLE) {
        _removeAttribute(_attribute);
    }

    function deleteAttributeKeys() external onlyRole(UPGRADER_ROLE) {
        delete attributeKeys;
    }

    struct ExpMod {
        uint tokenId;
        string attribute;
        uint change;
    }

    function addExpMultiple(ExpMod[] calldata expMods) external {
        for(uint i; i < expMods.length; i ++) addExp(expMods[i].tokenId, expMods[i].attribute, expMods[i].change);
    }

    function removeExpMultiple(ExpMod[] calldata expMods) external {
        for(uint i; i < expMods.length; i ++) removeExp(expMods[i].tokenId, expMods[i].attribute, expMods[i].change);
    }

    function addExp(uint256 _tokenId, string memory _attribute, uint256 _toAdd) public onlyRole(UPGRADER_ROLE) {
        statistics[_tokenId][_attribute] += _toAdd;
    }

    function removeExp(uint tokenId, string calldata attribute, uint toRemove) public onlyRole(UPGRADER_ROLE) {
        statistics[tokenId][attribute] -= toRemove;
    }

    function attributeKeyExists(string memory _attribute) external view returns(bool exists) {
        (exists,) = _attributeExists(_attribute);
    }

    function getAttributeKeys() external view returns (string[] memory) {
        return attributeKeys;
    }

    function _addNewAttribute(string memory _attribute) private {
        (bool exists,) = _attributeExists(_attribute);
        require(!exists, "Attribute already exists.");
        attributeKeys.push(_attribute);
    }

    function _removeAttribute(string memory _attribute) private {
        (bool exists,uint at) = _attributeExists(_attribute);
        if(!exists) revert("Attribute does not exist.");
        for(uint i = at + 1; i < attributeKeys.length; i ++) {
            attributeKeys[i - 1] = attributeKeys[i];
        }
        attributeKeys.pop();
    }

    function _attributeExists(string memory attribute) private view returns(bool exists,uint at) {
        for(uint i; i < attributeKeys.length; i ++) {
            if(sha256(bytes(attribute)) == sha256(bytes(attributeKeys[i]))) return (true,i);
        }
    }

}