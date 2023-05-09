// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract Items is ERC1155PresetMinterPauser {

    constructor(string memory URI) ERC1155PresetMinterPauser(URI) {}

    function setURI(string memory URI) external onlyRole(DEFAULT_ADMIN_ROLE) {_setURI(URI);}

}

