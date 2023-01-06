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

    ERC20Payments.Payee[] private _payees;
    IERC20 public token;
    Config[] private _configs;
    uint public price;
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

    function purchase(uint numberOf) whenNotPaused external {
        for(uint i; i < numberOf; i ++) {
            _purchase();
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
        uint toolboxId = _configs[result].toolboxId;
        _mint(from, toolboxId, 1, "");
    }



}