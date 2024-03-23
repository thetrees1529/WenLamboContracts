//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PlateMetadata.sol";

contract PlateRegister is AccessControl {

    event PlateRegistered(uint indexed id, string plate);

    uint private _minCharacters = 1;
    uint private _maxCharacters = 7;

    string private _allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    bytes private _allowedCharactersBytes = bytes(_allowedCharacters);

    string[] private _backgrounds;
    bytes[] private _backgroundsBytes;


    mapping(uint => bool) public plateRegistered;
    mapping(string => mapping(string => bool)) public plateExists;

    PlateMetadata public plateMetadata;

    constructor(PlateMetadata plateMetadata_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        plateMetadata = plateMetadata_;
    }

    function getRules() external view returns (uint minCharacters, uint maxCharacters, string memory allowedCharacters, string[] memory backgrounds) {
        return (_minCharacters, _maxCharacters, _allowedCharacters, _backgrounds);
    }

    function setBackgrounds(string[] memory backgrounds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _backgrounds = backgrounds;
        delete _backgroundsBytes;
        for (uint i = 0; i < backgrounds.length; i++) {
            _backgroundsBytes.push(bytes(backgrounds[i]));
        }
    }

    function registerPlate(uint id, string memory plate, string memory background) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool isValid, string memory errorMessage) = _isValidPlate(id, plate, background);
        require(isValid, errorMessage);

        plateRegistered[id] = true;
        plateExists[plate][background] = true;

        plateMetadata.setAttribute(PlateMetadata.SetAttributeStruct(id, PlateMetadata.KeyValuePair("plate", plate)));
        plateMetadata.setAttribute(PlateMetadata.SetAttributeStruct(id, PlateMetadata.KeyValuePair("background", background)));

        emit PlateRegistered(id, plate);
    }

    function _isValidPlate(uint id, string memory plate, string memory background) private view returns (bool, string memory) {
        if(plateRegistered[id]) {
            return (false, "Plate already registered at this id.");
        }
        if(plateExists[plate][background]) {
            return (false, "Plate already exists.");
        }
        bytes memory plateBytes = bytes(plate);
        if (plateBytes.length < _minCharacters) {
            return (false, "Too short.");
        }
        if (plateBytes.length > _maxCharacters) {
            return (false, "Too long.");
        }
        for (uint i = 0; i < plateBytes.length; i++) {
            bool found;
            for (uint j = 0; j < _allowedCharactersBytes.length; j++) {
                if (plateBytes[i] == _allowedCharactersBytes[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return (false, "Invalid character(s).");
            }
        }

        bool foundBackground;
        for(uint j; j < _backgroundsBytes.length; j++) {
            if(keccak256(abi.encode(bytes(background))) == keccak256(abi.encode(bytes(_backgroundsBytes[j])))) {
                foundBackground = true;
                break;
            }
        }
        if (!foundBackground) {
            return (false, "Invalid background.");
        }
        
        return (true, "");
    }

}