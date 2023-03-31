// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Rewards/Vault.sol";
import "./extensions/IFarmWatcher.sol";

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
    uint private _emittingFrom;

    uint public totalDeposited;
    uint public totalWithdrawn;
    uint public totalClaimed;

    mapping(address => Account) private _accounts;

    constructor(IERC20 depositToken_, Vault vault_, IERC20 rewardToken_, IFarmWatcher farmWatcher_, uint emissionRate_, uint startDate_) {
        depositToken = depositToken_;
        vault = vault_;
        rewardToken = rewardToken_;
        emissionRate = emissionRate_;
        _setStartDate(startDate_);
        _setFarmWatcher(farmWatcher_);
    }

    function claimableOf(address addr) public view returns(uint) {
        return _claimableOf(_accounts[addr]);
    }

    function globalClaimable() external view returns(uint) {
        return (_pendingPerShare() * _shareCount) + _owed - _debt;
    }

    function currentlyDeposited() external view returns(uint) {
        return _shareCount * SHARE;
    }

    function deposit(uint amount) external {
        _update();
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint debt = shares * _perShare;
        account.debt += debt;
        account.shares += shares;
        _shareCount += shares;

        totalDeposited += amount;
        _debt += debt;
        depositToken.transferFrom(msg.sender, address(this), amount);

        if(address(farmWatcher) != address(0)) farmWatcher.deposited(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        _update();
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint owed = shares * _perShare;
        account.owed += owed;
        account.shares -= shares;
        _shareCount -= shares;

        totalWithdrawn += amount;
        _owed += owed;
        depositToken.transfer(msg.sender, amount);

        if(address(farmWatcher) != address(0)) farmWatcher.withdrawn(msg.sender, amount);
    }

    function claim() external {
        Account storage account = _accounts[msg.sender];
        uint toClaim = _claimableOf(account);
        account.debt += toClaim;
        totalClaimed += toClaim;

        _debt += toClaim;
        totalClaimed += toClaim;
        vault.withdraw(rewardToken, msg.sender, toClaim);

        if(address(farmWatcher) != address(0)) farmWatcher.claimed(msg.sender, toClaim);
    }

    function setStartDate(uint newStartDate) external onlyOwner {
        require(!_isBeforeStartDate(), "Already started.");
        _setStartDate(newStartDate);
    }

    function setEmissionRate(uint newEmissionRate) external onlyOwner {
        _update();
        emissionRate = newEmissionRate;
    }

    function setFarmWatcher(IFarmWatcher newFarmWatcher) external onlyOwner {
        _setFarmWatcher(newFarmWatcher);
    }

    function _pendingPerShare() private view returns(uint) {
        if(_isBeforeStartDate() || _shareCount == 0) return 0;
        return _perShare + ((block.timestamp - _emittingFrom) * emissionRate) / _shareCount;
    }

    function _setFarmWatcher(IFarmWatcher newFarmWatcher) private {
        farmWatcher = newFarmWatcher;
    }

    function _isBeforeStartDate() private view returns(bool) {
        return block.timestamp < startDate;
    }

    function _setStartDate(uint newStartDate) private {
        startDate = newStartDate;
        _emittingFrom = newStartDate;
    }

    function _claimableOf(Account storage account) private view returns(uint) {
        return (account.shares * _pendingPerShare()) + account.owed - account.debt;
    }

    function _update() private {
        uint pendingPerShare = _pendingPerShare();
        if(pendingPerShare != _perShare) _perShare = pendingPerShare;
        _emittingFrom = block.timestamp;
    }

}