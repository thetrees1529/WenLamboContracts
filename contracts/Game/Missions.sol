//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Missions is Ownable {

    struct QualifyingNftInput {
        IERC721 qualifyingNft;
        uint tokenId;
    }

    struct QualifyingNft {
        bool inMission;
        uint missionId;
        uint missionEndsAt;
    }

    struct QualifyingNftView {
        bool inMission;
        uint missionId;
        uint missionEndsAt;
        uint[] completionCounts;
    }

    struct Mission {
        bool active;

        string meta;
        uint duration;
        uint maxCompletionCount;
        uint globalMaxCompletionCount;

        uint globalCompletionCount;
        uint currentlyInMission;

        IERC721 qualifyingNft;

        Nft[] entryNfts;
        Nft[] rewardNfts;

        mapping(uint => uint) completionCounts;
    }

    struct MissionView {
        bool active;

        string meta;
        uint duration;
        uint maxCompletionCount;
        uint globalMaxCompletionCount;

        uint globalCompletionCount;
        uint currentlyInMission;

        IERC721 qualifyingNft;

        Nft[] entryNfts;
        Nft[] rewardNfts;
    }

    Mission[] private _missions;
    mapping(IERC721 => mapping(uint => QualifyingNft)) private _qualifyingNfts;
    uint public completionCount;
    uint public currentlyInMission;

    function getMissions() public view returns (MissionView[] memory missionViews) {
        missionViews = new MissionView[](_missions.length);
        for (uint i = 0; i < _missions.length; i++) {
            Mission storage mission = _missions[i];
            missionViews[i] = MissionView({
                active: mission.active,
                meta: mission.meta,
                duration: mission.duration,
                maxCompletionCount: mission.maxCompletionCount,
                globalMaxCompletionCount: mission.globalMaxCompletionCount,
                globalCompletionCount: mission.globalCompletionCount,
                currentlyInMission: mission.currentlyInMission,
                qualifyingNft: mission.qualifyingNft,
                entryNfts: mission.entryNfts,
                rewardNfts: mission.rewardNfts
            });
        }
    }

    function getQualifyingNfts(QualifyingNftInput[] memory qualifyingNftInputs) public view returns(QualifyingNftView[] memory qualifyingNftViews) {
        qualifyingNftViews = new QualifyingNftView[](qualifyingNftInputs.length);
        for(uint j; j < qualifyingNftInputs.length; j ++) {
            QualifyingNftInput memory qualifyingNftInput = qualifyingNftInputs[j];
            QualifyingNft storage _qualifyingNft = _qualifyingNfts[qualifyingNftInput.qualifyingNft][qualifyingNftInput.tokenId];
            qualifyingNftViews[j] = QualifyingNftView({
                inMission: _qualifyingNft.inMission,
                missionId: _qualifyingNft.missionId,
                missionEndsAt: _qualifyingNft.missionEndsAt,
                completionCounts: new uint[](_missions.length)
            });
            for (uint i = 0; i < _missions.length; i++) {
                Mission storage mission = _missions[i];
                qualifyingNftViews[j].completionCounts[i] = mission.completionCounts[qualifyingNftInput.tokenId];
            }
        }

    }

    function createMission(
        string memory meta,
        uint duration,
        uint maxCompletionCount,
        uint globalMaxCompletionCount,
        IERC721 qualifyingNft,
        Nft[] memory entryNfts,
        Nft[] memory rewardNfts
    ) public onlyOwner {
        _missions.push();
        Mission storage mission = _missions[_missions.length - 1];
        mission.active = true;
        mission.meta = meta;
        mission.duration = duration;
        mission.maxCompletionCount = maxCompletionCount;
        mission.globalMaxCompletionCount = globalMaxCompletionCount;
        mission.qualifyingNft = qualifyingNft;
        mission.entryNfts = entryNfts;
        mission.rewardNfts = rewardNfts;
    }

    function disableMission(uint missionId) public onlyOwner {
        Mission storage mission = _missions[missionId];
        mission.active = false;
    }

    function enableMission(uint missionId) public onlyOwner {
        Mission storage mission = _missions[missionId];
        mission.active = true;
    }

    function enterMission(uint missionId, Nft qualifyingNft, uint tokenId) public {
        require(qualifyingNft.ownerOf(tokenId) == msg.sender, "Not owner of qualifying NFT");

        Mission storage mission = _missions[missionId];
        require(mission.active, "Mission is not active");
        require(mission.qualifyingNft == qualifyingNft, "Qualifying NFT is not valid");
        require(mission.completionCounts[tokenId] < mission.maxCompletionCount, "Max entry count reached");
        require(mission.currentlyInMission < mission.globalMaxCompletionCount - mission.globalCompletionCount, "Global max entry count reached");

        QualifyingNft storage _qualifyingNft = _qualifyingNfts[qualifyingNft][tokenId];
        require(!_qualifyingNft.inMission, "Already in mission");

        mission.currentlyInMission += 1;

        _qualifyingNft.inMission = true;
        _qualifyingNft.missionId = missionId;
        _qualifyingNft.missionEndsAt = block.timestamp + mission.duration;

        currentlyInMission += 1;

        for(uint i; i < mission.entryNfts.length; i ++) {
            mission.entryNfts[i].burn(mission.entryNfts[i].tokenOfOwnerByIndex(msg.sender, 0));
        }
    }

    function quitMission(Nft qualifyingNft, uint tokenId) public {
        require(qualifyingNft.ownerOf(tokenId) == msg.sender, "Not owner of qualifying NFT");

        QualifyingNft storage _qualifyingNft = _qualifyingNfts[qualifyingNft][tokenId];
        require(_qualifyingNft.inMission, "Not in mission");

        _qualifyingNft.inMission = false;

        Mission storage mission = _missions[_qualifyingNft.missionId];
        mission.currentlyInMission -= 1;
        currentlyInMission -= 1;

        for(uint i; i < mission.entryNfts.length; i ++) {
            mission.entryNfts[i].mint(msg.sender, 1);
        }
    }

    function completeMission(Nft qualifyingNft, uint tokenId) public {
        require(qualifyingNft.ownerOf(tokenId) == msg.sender, "Not owner of qualifying NFT");

        QualifyingNft storage _qualifyingNft = _qualifyingNfts[qualifyingNft][tokenId];
        require(_qualifyingNft.inMission, "Not in mission");

        Mission storage mission = _missions[_qualifyingNft.missionId];
        require(block.timestamp > _qualifyingNft.missionEndsAt, "Mission not completed");

        mission.completionCounts[tokenId] += 1;
        mission.globalCompletionCount += 1;
        mission.currentlyInMission -= 1;

        _qualifyingNft.inMission = false;
        _qualifyingNft.missionId = 0;
        _qualifyingNft.missionEndsAt = 0;

        currentlyInMission -= 1;
        completionCount += 1;

        for(uint i; i < mission.rewardNfts.length; i ++) {
            mission.rewardNfts[i].mint(msg.sender, 1);
        }
    }


}