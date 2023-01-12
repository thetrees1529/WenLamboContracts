// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";

contract Toolboxes is ERC1155PresetMinterPauser, RandomConsumer {

    using ERC20Payments for IERC20;

    struct Config {
        uint toolboxId;
        uint weighting;
    }

    struct Balance {
        uint toolboxId;
        uint balance;
    }

    struct StatsView {
        uint toolboxId;
        uint totalMinted;
    }

    ERC20Payments.Payee[] private _payees;
    IERC20 public token;
    Config[] private _configs;
    uint public price;
    mapping(uint => uint) private _stats;
    uint[] private _history;
    
    //input to chainlink intermediary
    uint[] private _options;
    mapping(uint => address) private _requests;

    //ALWAYS HAVE PAYEES BECAUSE IF THERE ARE NONE THEN THEY WILL GET THE SHIT FOR FREE
    constructor(string memory uri, IRandom random, IERC20 token_, ERC20Payments.Payee[] memory payees, uint price_, Config[] memory configs) ERC1155PresetMinterPauser(uri) RandomConsumer(random)  {
        token = token_;
        _setPayees(payees);
        _setPrice(price_);
        _setConfigs(configs);
    }

    function getStats() external view returns(StatsView[] memory history) {
        history = new StatsView[](_configs.length);
        for(uint i; i < history.length; i ++) {
            history[i] = StatsView(_configs[i].toolboxId, _stats[_configs[i].toolboxId]);
        }
    }

    function getHistory(uint numberOf) external view returns(uint[] memory history) {
        history = new uint[](numberOf);
        uint start = _history.length - numberOf;
        for(uint i = start; i < _history.length; i ++) {
            history[i - start] = _history[i];
        }
    }

    function purchase(uint numberOf) whenNotPaused external {
        for(uint i; i < numberOf; i ++) {
            _purchase();
        }
    }

    function getBalances(address addr) external view returns(Balance[] memory balances) {
        balances = new Balance[](_configs.length);
        for(uint i; i < balances.length; i ++) {
            balances[i] = Balance(_configs[i].toolboxId, balanceOf(addr, _configs[i].toolboxId));
        }
    }

    function _purchase() internal {
        token.splitFrom(msg.sender, price, _payees);
        _requests[_requestRandom(_options)] = msg.sender;
    }

    function setPrice(uint newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPrice(newPrice);
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPayees(payees);
    }

    function getPayees() external view returns(ERC20Payments.Payee[] memory) {return _payees;}

    function setUri(string memory newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    function setConfigs(Config[] calldata configs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setConfigs(configs);
    }
    function _setConfigs(Config[] memory configs) private {
        delete _configs;
        delete _options;
        for(uint i; i < configs.length; i ++) {
            Config memory config = configs[i];
            _configs.push(config);
            _options.push(config.weighting);
        }
    }

    function getConfigs() external view returns(Config[] memory) {return _configs;}

    function _setPayees(ERC20Payments.Payee[] memory payees) private {
        delete _payees;
        for(uint i; i < payees.length; i ++) _payees.push(payees[i]);
    }

    function _setPrice(uint newPrice) private {
        price = newPrice;
    }

    function _fulfillRandom(uint requestId, uint result) internal override {
        address from = _requests[requestId];
        Config storage config = _configs[result];
        _stats[config.toolboxId] ++;
        _history.push(config.toolboxId);
        uint toolboxId = config.toolboxId;
        _mint(from, toolboxId, 1, "");
    }



}