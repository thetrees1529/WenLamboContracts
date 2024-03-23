//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Plates.sol";

contract PlateMetadata is AccessControl {

    event AttributeSet(SetAttributeStruct setAttributeStruct);
    event KeyRemoved(string key);
    event KeyAdded(string key);

    struct KeyValuePair {
        string key;
        string value;
    }

    struct SetAttributeStruct {
        uint id;
        KeyValuePair keyValuePair;
    }

    mapping(uint => mapping(string => string)) private _metadata;
    string[] private _keys;

    Plates public plates;

    constructor(Plates plates_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        plates = plates_;
    }

    function getKeys() external view returns (string[] memory) {
        return _keys;
    }

    function getMetadataOf(uint id) public view exists(id) returns (KeyValuePair[] memory metadata) {

        metadata = new KeyValuePair[](_keys.length);
        for (uint i = 0; i < _keys.length; i++) {
            metadata[i] = KeyValuePair(_keys[i], _metadata[id][_keys[i]]);
        }
    }

    function getMetadataOfMultiple(uint[] memory ids) external view returns (KeyValuePair[][] memory metadata) {
        metadata = new KeyValuePair[][](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            metadata[i] = getMetadataOf(ids[i]);
        }
    }

    function removeKey(string memory key) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i; i < _keys.length; i ++) {
            if (keccak256(abi.encodePacked(_keys[i])) == keccak256(abi.encodePacked(key))) {
                _keys[i] = _keys[_keys.length - 1];
                _keys.pop();
                emit KeyRemoved(key);
                return;
            }
        }
    }

    function setAttribute(SetAttributeStruct memory setAttributeStruct) public onlyRole(DEFAULT_ADMIN_ROLE) exists(setAttributeStruct.id) {
        _metadata[setAttributeStruct.id][setAttributeStruct.keyValuePair.key] = setAttributeStruct.keyValuePair.value;
        bool found = false;
        for (uint i; i < _keys.length; i++) {
            if (keccak256(abi.encodePacked(_keys[i])) == keccak256(abi.encodePacked(setAttributeStruct.keyValuePair.key))) {
                found = true;
                break;
            }
        }
        if (!found) {
            _keys.push(setAttributeStruct.keyValuePair.key);
            emit KeyAdded(setAttributeStruct.keyValuePair.key);
        }
        emit AttributeSet(setAttributeStruct);
    }

    function setAttributeMultiple(SetAttributeStruct[] memory setAttributeStructs) external {
        for (uint i; i < setAttributeStructs.length; i++) {
            setAttribute(setAttributeStructs[i]);
        }
    }

    modifier exists(uint id) {
        try plates.ownerOf(id) returns (address) {
            _;
        } catch {
            revert("Plate does not exist.");
        }
    }

}