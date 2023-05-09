// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IGarageManager {    

    struct GarageDataView {
        uint256 speed; // hVille earning speed (per day)
        uint256 unlocked;
        uint256 locked;
        uint256 lockedInterest;
        uint256 totalSpent;
        uint256 totalEverClaimed;
        uint8 pitCrew; // 0 or 1
        uint8 crewChief; // 0 -> 3
        uint8 mechanic; // 0 -> 3
        uint8 gasman; // 0 -> 3
        uint8 tireChanger; // 0 -> 3
    }

    struct GarageData {
        uint256 unlockedEarnings; // already earned hVille, but not withdrawn yet
        uint256 lockedEarnings; // remaining earned hVille that is locked
        uint64 lastHVilleCheckout; // (now - lastHVilleCheckout) * 'earning speed' + fixedEarnings = farmed so far
        uint64 lastLockedInterestCheckout; // time we last claimed our yearly interest on the locked balance

        uint256 totalSpent; // entire total of hVille spent on upgrades
        uint256 totalEverClaimed; // total hville ever claimed (locked + unlocked)

        uint8 pitCrew; // 0 or 1
        uint8 crewChief; // 0 -> 3
        uint8 mechanic; // 0 -> 3
        uint8 gasman; // 0 -> 3
        uint8 tireChanger; // 0 -> 3
    }

    function getEarnedUnlocked(uint256 _tokenId) external view returns (uint256);

    function getEarnedLocked(uint256 _tokenId) external view returns (uint256, uint256);


    function getTokenAttributes(uint256 _tokenId) external view returns (GarageDataView memory);

    function getTokenAttributesMany(uint256[] calldata _tokenIds) external view returns (GarageDataView[] memory);

    function getTotalLockedForAddress(address _addr) external view returns (uint256, uint256);


}
