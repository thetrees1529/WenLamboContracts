// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Legacy/GarageManager.sol";
import "./Earn.sol";

contract GarageMigrator is AccessControl {

    bytes32 public MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    mapping(uint => bool) public migrated;

    struct Data {
        bool inLocation;
        Earn.Location newLocation;
        uint locked;
        uint claimable;
    }

    struct MigrateInput {
        uint tokenId;
        Data data;
    }

    Earn public earn;

    constructor(Earn earn_) {
        earn = earn_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MIGRATOR_ROLE, msg.sender);
    }

    function migrate(MigrateInput[] calldata inputs) external onlyRole(MIGRATOR_ROLE) {
        for(uint i; i < inputs.length; i ++) {
            MigrateInput calldata input = inputs[i];
            if(migrated[input.tokenId]) return;
            earn.editLocked(input.tokenId, int(input.data.locked));
            if(input.data.inLocation) earn.setLocation(input.tokenId, input.data.newLocation);
            earn.editClaimable(input.tokenId, int(input.data.claimable));
        }
    }

    

}