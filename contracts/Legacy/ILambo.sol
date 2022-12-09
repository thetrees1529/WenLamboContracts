//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ILambo {    
    event ExperienceGranted(
        uint256 tokenId,
        string attribute,
        uint256 expAdded,
        uint256 totalExp
    );

    event NewAttributeCreated(
        string attribute,
        uint256 blockNumber,
        uint256 blockTime
    );

    event RaceWon(
        uint256 tokenId,
        uint256 raceId
    );

    event PreSaleStarted(
        uint256 blockNumber,
        uint256 blockTime
    );

    event PublicSaleStarted(
        uint256 blockNumber,
        uint256 blockTime
    );

    struct StatisticView {
        string statistic;
        uint256 value;
    }
}