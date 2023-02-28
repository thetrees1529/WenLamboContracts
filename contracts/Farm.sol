// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vault.sol";
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
    uint private _emittingFrom;

    uint public totalDeposited;
    uint public totalWithdrawn;
    uint public totalClaimed;

    mapping(address => Account) private _accounts;

    constructor(IERC20 depositToken_, Vault vault_, IERC20 rewardToken_, IFarmWatcher farmWatcher_, uint emissionRate_, uint startDate_, address owner) {
        depositToken = depositToken_;
        vault = vault_;
        rewardToken = rewardToken_;
        emissionRate = emissionRate_;
        _setStartDate(startDate_);
        _setFarmWatcher(farmWatcher_);
        _transferOwnership(owner);
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
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint debt = shares * _pendingPerShare();
        account.debt += debt;
        account.shares += shares;
        _shareCount += shares;

        totalDeposited += amount;
        _debt += debt;
        depositToken.transferFrom(msg.sender, address(this), amount);

        farmWatcher.deposited(msg.sender, amount);
    }

    function withdraw(uint amount) external {
        Account storage account = _accounts[msg.sender];

        uint shares = amount / SHARE;
        uint owed = shares * _pendingPerShare();
        account.owed += owed;
        account.shares -= shares;
        _shareCount -= shares;

        totalWithdrawn += amount;
        _owed += owed;
        depositToken.transfer(msg.sender, amount);

        farmWatcher.withdrawn(msg.sender, amount);
    }

    function claim() external {
        Account storage account = _accounts[msg.sender];
        uint toClaim = _claimableOf(account);
        account.debt += toClaim;
        totalClaimed += toClaim;
        vault.withdraw(rewardToken, msg.sender, toClaim);

        farmWatcher.claimed(msg.sender, toClaim);
    }

    function setStartDate(uint newStartDate) external onlyOwner {
        require(!_isBeforeStartDate(), "Already started.");
        _setStartDate(newStartDate);
    }

    function setEmissionRate(uint newEmissionRate) external onlyOwner {
        _update();
        emissionRate = newEmissionRate;
        _emittingFrom = block.timestamp;
    }

    function setFarmWatcher(IFarmWatcher newFarmWatcher) external onlyOwner {
        _setFarmWatcher(newFarmWatcher);
    }

    function _pendingPerShare() private view returns(uint) {
        if(_isBeforeStartDate()) return 0;
        return _perShare + (((block.timestamp - _emittingFrom) * emissionRate) / _shareCount);
    }

    function _setFarmWatcher(IFarmWatcher newFarmWatcher) private {
        farmWatcher = newFarmWatcher;
    }

    function _isBeforeStartDate() private view returns(bool) {
        return block.timestamp < startDate;
    }

    function _setStartDate(uint newStartDate) private {
        require(newStartDate >= block.timestamp, "Cannot set start date in the past.");
        startDate = newStartDate;
        _emittingFrom = newStartDate;
    }

    function _claimableOf(Account storage account) private view returns(uint) {
        return (account.shares * _pendingPerShare()) + account.owed - account.debt;
    }

    function _update() private {
        uint pendingPerShare = _pendingPerShare();
        if(pendingPerShare != _perShare) _perShare = pendingPerShare;
    }

}