// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Rewards/Vault.sol";
import "./IFarmWatcher.sol";

contract Farm is Ownable {

    struct Account {
        uint shares;
        uint owed;
        uint debt;
    }

    uint private constant SHARE = 1e9;

    IERC20 public depositToken;
    IERC20 public rewardToken;
    Vault public vault;
    IFarmWatcher public farmWatcher;

    uint private _shareCount;
    uint private _perShare;
    uint private _debt;
    uint private _owed;

    uint public emissionRate;
    uint public startDate;
    uint public emittable;
    uint private _lastUpdate;
    uint private _emittableLeft;
    uint public totalDeposited;
    uint public totalWithdrawn;
    uint public totalClaimed;

    mapping(address => Account) private _accounts;

    constructor(IERC20 depositToken_, Vault vault_, IERC20 rewardToken_, IFarmWatcher farmWatcher_, uint emissionRate_, uint startDate_, uint emittable_) {
        depositToken = depositToken_;
        vault = vault_;
        rewardToken = rewardToken_;
        _setEmissionRate(emissionRate_);
        _setStartDate(startDate_);
        _setFarmWatcher(farmWatcher_);
        _setEmittable(emittable_);
    }

    function totalEmitted() public view returns(uint) {
        (uint pendingEmittableLeft,) = _getPendingValues();
        return emittable - pendingEmittableLeft;
    }

    function claimableOf(address addr) public view returns(uint) {
        return _claimableOf(_accounts[addr]);
    }

    function depositedOf(address addr) public view returns(uint) {
        return _accounts[addr].shares * SHARE;
    }

    function globalClaimable() external view returns(uint) {
        return _getPendingClaimable(_shareCount, _owed, _debt);
    }

    function currentlyDeposited() external view returns(uint) {
        return _shareCount * SHARE;
    }

    function claimFor(address from) external onlyOwner {
        _claim(from);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function depositFrom(address from, uint amount) external onlyOwner {
        _deposit(from, amount);
    }

    function deposit(uint amount) external {
        _deposit(msg.sender, amount);
    }

    function withdrawFrom(address to, uint amount) external onlyOwner {
        _withdraw(to, amount);
    }

    function withdraw(uint amount) external {
        _withdraw(msg.sender, amount);
    }

    function setStartDate(uint newStartDate) external onlyOwner {
        require(_isBeforeStartDate(), "Already started.");
        _setStartDate(newStartDate);
    }

    function setEmissionRate(uint newEmissionRate) external onlyOwner {
        _setEmissionRate(newEmissionRate);
    }

    function setFarmWatcher(IFarmWatcher newFarmWatcher) external onlyOwner {
        _setFarmWatcher(newFarmWatcher);
    }

    function setEmittable(uint amount) external onlyOwner {
        _setEmittable(amount);
    }

    function _setFarmWatcher(IFarmWatcher newFarmWatcher) private {
        farmWatcher = newFarmWatcher;
    }

    function _isBeforeStartDate() private view returns(bool) {
        return block.timestamp < startDate;
    }

    function _setStartDate(uint newStartDate) private {
        startDate = newStartDate;
    }

    function _setEmissionRate(uint newEmissionRate) private {
        _update();
        emissionRate = newEmissionRate;
    }

    function _setEmittable(uint amount) private {
        _update();
        uint totalEmitted_ = emittable - _emittableLeft;
        require(amount >= totalEmitted_);
        emittable = amount;
        _emittableLeft = emittable - totalEmitted_;
    }

    function _claim(address from) private {
        Account storage account = _accounts[from];
        uint toClaim = _claimableOf(account);
        account.debt += toClaim;
        totalClaimed += toClaim;

        _debt += toClaim;
        vault.withdraw(rewardToken, from, toClaim);

        if(address(farmWatcher) != address(0)) farmWatcher.claimed(from, toClaim);
    }

    function _deposit(address from, uint amount) private {
        _update();
        Account storage account = _accounts[from];

        uint shares = amount / SHARE;
        uint debt = shares * _perShare;
        account.debt += debt;
        account.shares += shares;
        _shareCount += shares;

        totalDeposited += amount;
        _debt += debt;
        depositToken.transferFrom(from, address(this), amount);

        if(address(farmWatcher) != address(0)) farmWatcher.deposited(from, amount);
    }

    function _withdraw(address from, uint amount) private {
        _update();
        Account storage account = _accounts[from];

        uint shares = amount / SHARE;
        uint owed = shares * _perShare;
        account.owed += owed;
        account.shares -= shares;
        _shareCount -= shares;

        totalWithdrawn += amount;
        _owed += owed;
        depositToken.transfer(from, amount);

        if(address(farmWatcher) != address(0)) farmWatcher.withdrawn(from, amount);
    }

    function _claimableOf(Account storage account) private view returns(uint) {
        return _getPendingClaimable(account.shares, account.owed, account.debt);
    }


    function _getPendingClaimable(uint shares, uint owed, uint debt) private view returns(uint) {
        (,uint pendingPerShare) = _getPendingValues();
        return (shares * pendingPerShare) + owed - debt;
    }

    function _getPendingValues() private view returns(uint pendingEmittableLeft,  uint pendingPerShare) {
        if(!_isBeforeStartDate() && _shareCount > 0) {
            uint emittingFrom = _lastUpdate > startDate ? _lastUpdate : startDate;
            uint potentiallyEmitted = (((block.timestamp - emittingFrom) * emissionRate) / _shareCount);
            uint pendingEmitted = potentiallyEmitted > _emittableLeft ? _emittableLeft : potentiallyEmitted;
            pendingEmittableLeft = _emittableLeft - pendingEmitted;
            pendingPerShare = _perShare + pendingEmitted / _shareCount;
        } else {
            pendingEmittableLeft = _emittableLeft;
            pendingPerShare = _perShare;
        }
    }


    function _update() private {
        (uint pendingEmittableLeft,uint pendingPerShare) = _getPendingValues();
        _perShare = pendingPerShare;
        _emittableLeft = pendingEmittableLeft;
        _lastUpdate = block.timestamp;
    }

}