// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Farm.sol";
import "../Token/Token.sol";

contract FarmManager is Ownable {

    struct DepositInput {
        uint farmIndex;
        uint amount;
    }

    struct WithdrawInput {
        uint farmIndex;
        uint amount;
    }

    struct FarmData {
        Farm implementation;
        IERC20 depositToken;
        IERC20 rewardToken;
        Vault vault;
        IFarmWatcher farmWatcher;
        uint emissionRate;
        uint startDate;
        uint emittable;
        uint totalEmitted;
        uint totalDeposited;
        uint totalWithdrawn;
        uint totalClaimed;
        uint globalClaimable;
        uint currentlyDeposited;
        uint userDeposited;
        uint userClaimable;
    }

    Farm[] private _farms;

    //input the zero address if there is no wallet involved
    function getFarmsDataFor(address addr) external view returns(FarmData[] memory) {
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
                emittable: _farms[i].emittable(),
                totalEmitted: _farms[i].totalEmitted(),
                totalDeposited: _farms[i].totalDeposited(),
                totalWithdrawn: _farms[i].totalWithdrawn(),
                totalClaimed: _farms[i].totalClaimed(),
                globalClaimable: _farms[i].globalClaimable(),
                currentlyDeposited: _farms[i].currentlyDeposited(),
                userDeposited: _farms[i].depositedOf(addr),
                userClaimable: _farms[i].claimableOf(addr)
            });
        }
        return farmsData;
    }

    function deposit(DepositInput[] calldata inputs) external {
        for(uint i = 0; i < inputs.length; i++) {
            _farms[inputs[i].farmIndex].depositFrom(msg.sender, inputs[i].amount);
        }
    }

    function withdraw(WithdrawInput[] calldata inputs) external {
        for(uint i = 0; i < inputs.length; i++) {
            _farms[inputs[i].farmIndex].withdrawFrom(msg.sender, inputs[i].amount);
        }
    }

    function claim(uint[] calldata farmIndexes) external {
        for(uint j = 0; j < farmIndexes.length; j++)
            _farms[farmIndexes[j]].claimFor(msg.sender);
    }

    function withdrawAll() external {
        for(uint i = 0; i < _farms.length; i++) {
            uint deposited = _farms[i].depositedOf(msg.sender);
            if(deposited > 0)
                _farms[i].withdrawFrom(msg.sender, deposited);
        }
    }

    function claimAll() external {
        for(uint i = 0; i < _farms.length; i++) {
            if(_farms[i].claimableOf(msg.sender) > 0)
                _farms[i].claimFor(msg.sender);
        }
    }

    function createFarm(IERC20 depositToken, Vault vault, IERC20 rewardToken, IFarmWatcher farmWatcher, uint emissionRate, uint startDate, uint emittable) external onlyOwner {
        Farm farm = new Farm(depositToken, vault, rewardToken, farmWatcher, emissionRate, startDate, emittable);
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

    function setFarmEmittable(uint i, uint newEmittable) external onlyOwner {
        _farms[i].setEmittable(newEmittable);
    }
}