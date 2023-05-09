// SPDX-License-Identifier: MIT
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

    struct TokenInfo {
        IERC20 implementation;
        string name;
        string symbol;
    }

    struct FarmData {
        Farm implementation;
        TokenInfo depositToken;
        TokenInfo rewardToken;
        Vault vault;
        IFarmWatcher farmWatcher;
        uint emissionRate;
        uint startDate;
        uint totalDeposited;
        uint totalWithdrawn;
        uint totalClaimed;
        uint globalClaimable;
        uint currentlyDeposited;
        uint userDeposited;
        uint userClaimable;

        uint allowanceOnDepositToken;
    }

    Farm[] private _farms;

    //input the zero address if there is no wallet involved
    function getFarmsDataFor(address addr) external view returns(FarmData[] memory) {
        FarmData[] memory farmsData = new FarmData[](_farms.length);
        for(uint i = 0; i < _farms.length; i++) {
            farmsData[i] = FarmData({
                implementation: _farms[i],
                depositToken: _getTokenInfo(_farms[i].depositToken()),
                rewardToken: _getTokenInfo(_farms[i].rewardToken()),
                vault: _farms[i].vault(),
                farmWatcher: _farms[i].farmWatcher(),
                emissionRate: _farms[i].emissionRate(),
                startDate: _farms[i].startDate(),
                totalDeposited: _farms[i].totalDeposited(),
                totalWithdrawn: _farms[i].totalWithdrawn(),
                totalClaimed: _farms[i].totalClaimed(),
                globalClaimable: _farms[i].globalClaimable(),
                currentlyDeposited: _farms[i].currentlyDeposited(),
                userDeposited: _farms[i].depositedOf(addr),
                userClaimable: _farms[i].claimableOf(addr),
                allowanceOnDepositToken: _farms[i].depositToken().allowance(addr, address(_farms[i]))
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

    function _getTokenInfo(IERC20 token) private view returns(TokenInfo memory) {
        return TokenInfo({
            implementation: token,
            name: ERC20(address(token)).name(),
            symbol: ERC20(address(token)).symbol()
        });
    }
}
