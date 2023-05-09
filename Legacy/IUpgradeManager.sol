//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IUpgradeManager {  
    
    event ToolboxCreated (
        address owner,
        uint256 indexed toolboxToken,
        bool wasBought
    );

    event ToolboxOpened (
        uint256 indexed toolboxToken,
        uint8 upgradeType,
        uint8 upgradeRarity,
        uint256 upgradeAmount
    );

    event ToolboxUsed (
        address collection,
        uint256 indexed nftToken,
        uint256 toolboxToken
    );

    event ToolboxPriceChange (
        uint256 oldPrice,
        uint256 newPrice
    );

    struct ToolboxView {
        uint256 toolboxToken;
        bool isOpened;
        bool isUsed;
        uint8 upgradeType;
        uint8 upgradeRarity;
        uint256 upgradeAmount;
        address owner;
    }

}