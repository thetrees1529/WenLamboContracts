//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PlateMetadata.sol";

contract PlateRegister is AccessControl {

    event PlateRegistered(uint indexed id, string plate);

    uint public constant MIN_CHARACTERS = 2;
    uint public constant MAX_CHARACTERS = 7;
    string public constant ALLOWED_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    bytes private _allowedCharacters = bytes(ALLOWED_CHARACTERS);

    mapping(uint => bool) public plateRegistered;
    mapping(string => bool) public plateExists;

    PlateMetadata public plateMetadata;

    constructor(PlateMetadata plateMetadata_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        plateMetadata = plateMetadata_;
    }

    function registerPlate(uint id, string memory plate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool isValid, string memory errorMessage) = _isValidPlate(plate);
        require(isValid, errorMessage);

        plateRegistered[id] = true;
        plateExists[plate] = true;

        plateMetadata.setAttribute(PlateMetadata.SetAttributeStruct(id, PlateMetadata.KeyValuePair("plate", plate)));

        emit PlateRegistered(id, plate);
    }

    function _isValidPlate(string memory plate) private view returns (bool, string memory) {
        if(plateExists[plate]) {
            return (false, "Plate already exists.");
        }
        bytes memory plateBytes = bytes(plate);
        if (plateBytes.length < MIN_CHARACTERS) {
            return (false, "Too short.");
        }
        if (plateBytes.length > MAX_CHARACTERS) {
            return (false, "Too long.");
        }
        for (uint i = 0; i < plateBytes.length; i++) {
            bool found = false;
            for (uint j = 0; j < _allowedCharacters.length; j++) {
                if (plateBytes[i] == _allowedCharacters[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return (false, "Invalid character(s).");
            }
        }
        return (true, "");
    }

}