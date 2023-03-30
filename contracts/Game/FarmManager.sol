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

    function getFarmAddressFor(IERC20 depositToken) external view returns(Farm) {
        for(uint i = 0; i < _farms.length; i++) {
            if(_farms[i].depositToken() == depositToken) {
                return _farms[i];
            }
        }
        revert("Farm does not exist for this token.");
    }

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
        for(uint i = 0; i < _farms.length; i++) {
            require(_farms[i].depositToken() != depositToken, "Farm already exists for this token.");
        }
        Farm farm = new Farm(depositToken, vault, rewardToken, farmWatcher, emissionRate, startDate);
        _farms.push(farm);
        vault.grantRole(vault.VAULT_ROLE(), address(farm));
    }

    function setFarmStartDate(IERC20 depositToken, uint newStartDate) external onlyOwner {
        for(uint i = 0; i < _farms.length; i++) {
            if(_farms[i].depositToken() == depositToken) {
                _farms[i].setStartDate(newStartDate);
                return;
            }
        }
        revert("Farm does not exist for this token.");
    }

    function setFarmEmissionRate(IERC20 depositToken, uint newEmissionRate) external onlyOwner {
        for(uint i = 0; i < _farms.length; i++) {
            if(_farms[i].depositToken() == depositToken) {
                _farms[i].setEmissionRate(newEmissionRate);
                return;
            }
        }
        revert("Farm does not exist for this token.");
    }

    function setFarmWatcher(IERC20 depositToken, IFarmWatcher newFarmWatcher) external onlyOwner {
        for(uint i = 0; i < _farms.length; i++) {
            if(_farms[i].depositToken() == depositToken) {
                _farms[i].setFarmWatcher(newFarmWatcher);
                return;
            }
        }
        revert("Farm does not exist for this token.");
    }
}
