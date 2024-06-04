//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "./Earn.sol";

contract FinalEarn {

    struct Info {
        bool migrated;
        uint lastClaimed;
        bool isInLocation;
        uint totalClaimed;
        Earn.Location location;
    }

    struct InfoOutput {
        bool isInLocation;
        uint totalClaimed;
        uint claimable;
        Earn.Location location;
    }

    uint private constant _MAX_MINTED = 200e24;
    uint private _earnSpeedConversion;
    Nfvs private _nfvs;
    uint private _baseEarn;
    uint private _burned;
    Earn.Stage[] private _stages;
    Token private _token;
    uint private _totalMinted;
    Earn private _earn;
    mapping(uint => Info) private _infos;

    constructor(Earn newEarn) {
        _earn = newEarn;
        _earnSpeedConversion = newEarn.EARN_SPEED_CONVERSION();
        _nfvs = newEarn.nfvs();
        _baseEarn = newEarn.baseEarn();
        _token = newEarn.token();
        (_burned,) = newEarn.tokens(_token);
        _totalMinted = newEarn.totalMinted();
        Earn.Stage[] memory stages = newEarn.getStages();
        for(uint i; i < stages.length; i++) {
            Earn.Stage memory stage = stages[i];
            Earn.Stage storage _stage = _stages.push();
            _stage.name = stage.name;
            for(uint j; j < stages[i].substages.length; j++) {
                Earn.Substage memory substage = stages[i].substages[j];
                Earn.Substage storage _substage = _stage.substages.push();
                _substage.name = substage.name;
                _substage.emission = substage.emission;
                for(uint k; k < substage.payments.length; k++) {
                    _substage.payments.push(substage.payments[k]);
                }
            }
        }
    }

    function getInfo() external view returns(uint baseEarn, Earn.Stage[] memory stages, Token token, uint burned, uint totalMinted, Nfvs nfvs, Earn earn, uint earnSpeedConversion, uint MAX_MINTED) {
        return (_baseEarn, _stages, _token, _burned, _totalMinted, _nfvs, _earn, _earnSpeedConversion, _MAX_MINTED);
    }

    function getNfvInfos(uint[] calldata tokenIds) external view returns(InfoOutput[] memory infoOutputs) {
        infoOutputs = new InfoOutput[](tokenIds.length);
        for(uint i; i < tokenIds.length; i++) {
            InfoOutput memory infoOutput = infoOutputs[i];
            Info storage _info = _infos[tokenIds[i]];
            if(!_info.migrated) {
                (infoOutput.isInLocation, infoOutput.totalClaimed, infoOutput.claimable, infoOutput.location) = _preMigrate(tokenIds[i]);
            } else {
                infoOutput.isInLocation = _info.isInLocation;
                infoOutput.totalClaimed = _info.totalClaimed;
                infoOutput.claimable = _preClaim(_info);
                infoOutput.location = _info.location;
            }
        }
        
    }

    function upgrade(uint[] calldata tokenIds) external {
        uint toBurn;
        uint toMint;
        for(uint i; i < tokenIds.length; i++) {
            require(msg.sender == _nfvs.ownerOf(tokenIds[i]));
            Info storage _info = _infos[tokenIds[i]];
            toMint += _claimOrMigrate(tokenIds[i], _info);
            Earn.Location memory location;
            if(_info.isInLocation) {
                location = _info.location;
                if(location.substage == _stages[location.stage].substages.length - 1) {
                    require(location.stage < _stages.length - 1/*, "Fully upgraded."*/);
                    location.stage ++;
                    location.substage = 0;
                } else {
                    location.substage ++;
                }
                _info.location = location;
            } else _info.isInLocation = true;
            toBurn += _stages[location.stage].substages[location.substage].payments[0].value;
        }
        if(toBurn > toMint) {
            _token.burnFrom(msg.sender, toBurn - toMint);
        } else if(toMint > toBurn) {
            _token.mintTo(msg.sender, toMint - toBurn);
        }
        _totalMinted += toMint;
        _burned += toBurn;
    }

    function claim(uint[] calldata tokenIds) external {
        uint toClaim;
        for(uint i; i < tokenIds.length; i++) {
            require(msg.sender == _nfvs.ownerOf(tokenIds[i]));
            Info storage _info = _infos[tokenIds[i]];
            toClaim += _claimOrMigrate(tokenIds[i], _info);
        }
        _token.mintTo(msg.sender, toClaim);
        _totalMinted += toClaim;
        require(_totalMinted <= _MAX_MINTED/*, "Max minted reached."*/);
    }

    function _claimOrMigrate(uint tokenId, Info storage _info) private returns(uint toClaim) {
        toClaim = _info.migrated ? _claim(_info) : _migrate(tokenId);
    }

    function _claim(Info storage _info) private returns(uint toClaim) {
        toClaim = _preClaim(_info);
        _info.lastClaimed = block.timestamp;
    }

    function _preClaim(Info storage _info) private view returns(uint toClaim) {
        uint time = block.timestamp - _info.lastClaimed;
        uint earn = _info.isInLocation ? _stages[_info.location.stage].substages[_info.location.substage].emission : _baseEarn;
        toClaim = time * earn * _earnSpeedConversion;
    }

    function _migrate(uint tokenId) private returns(uint toClaim) {
        Info storage _info = _infos[tokenId];
        _info.migrated = true;
        (bool isInLocation, uint totalClaimed, uint claimable, Earn.Location memory location) = _preMigrate(tokenId);
        _info.isInLocation = isInLocation;
        _info.totalClaimed = totalClaimed;
        _info.location = location;
        _info.lastClaimed = block.timestamp;
        toClaim = claimable;
    }

    function _preMigrate(uint tokenId) private view returns(bool isInLocation, uint totalClaimed, uint claimable, Earn.Location memory location) {
        Earn.NfvView memory nfv = _earn.getInformation(tokenId);
        isInLocation = nfv.onStages;
        location = nfv.location;
        totalClaimed = nfv.nfv.totalClaimed;
        claimable = nfv.unlockable + nfv.claimable;
    }

}