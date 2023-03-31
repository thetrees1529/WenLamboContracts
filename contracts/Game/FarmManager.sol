// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Farm.sol";
import "../Token/Token.sol";

contract FarmManager is Ownable {

    struct FarmData {
        Farm implementation;
        IERC20 depositToken;
        IERC20 rewardToken;
        Vault vault;
        IFarmWatcher farmWatcher;
        uint emissionRate;
        uint startDate;
        uint totalDeposited;
        uint totalWithdrawn;
        uint totalClaimed;
        uint globalClaimable;
        uint currentlyDeposited;
    }

    Farm[] private _farms;

    function getFarmsData() external view returns(FarmData[] memory) {
        FarmData[] memory farmsData = new FarmData[](_farms.length);
        for(uint i = 0; i < _farms.length; i++) {
            farmsData[i] = FarmData({
                implementation: _farms[i],
                depositToken: _farms[i].depositToken(),
                rewardToken: _farms[i].rewardToken(),
                vault: _farms[i].vault(),
                farmWatcher: _farms[i].farmWatcher(),
                emissionRate: _farms[i].emissionRate(),
                startDate: _farms[i].startDate(),
                totalDeposited: _farms[i].totalDeposited(),
                totalWithdrawn: _farms[i].totalWithdrawn(),
                totalClaimed: _farms[i].totalClaimed(),
                globalClaimable: _farms[i].globalClaimable(),
                currentlyDeposited: _farms[i].currentlyDeposited()
            });
        }
        return farmsData;
    }

    function createFarm(IERC20 depositToken, Vault vault, IERC20 rewardToken, IFarmWatcher farmWatcher, uint emissionRate, uint startDate) external onlyOwner {
        Farm farm = new Farm(depositToken, vault, rewardToken, farmWatcher, emissionRate, startDate);
        _farms.push(farm);
        vault.grantRole(vault.VAULT_ROLE(), address(farm));
    }

    /*
    blocks all claims
    if you just want to pause a farm you should set the emission rate to 0 instead 
    so that people can still claim for a while before calling this function 
    */
    function removeFarm(uint i) external onlyOwner {
        _farms[i].vault().revokeRole(_farms[i].vault().VAULT_ROLE(), address(_farms[i]));
        _farms[i] = _farms[_farms.length - 1];
        _farms.pop();
    }

    function setFarmStartDate(uint i, uint newStartDate) external onlyOwner {
        _farms[i].setStartDate(newStartDate);
    }

    function setFarmEmissionRate(uint i, uint newEmissionRate) external onlyOwner {
        _farms[i].setEmissionRate(newEmissionRate);
    }

    function setFarmWatcher(uint i, IFarmWatcher newFarmWatcher) external onlyOwner {
        _farms[i].setFarmWatcher(newFarmWatcher);
    }
}
