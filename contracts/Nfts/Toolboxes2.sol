// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";


contract Toolboxes is RandomConsumer, AccessControl, Nft {

    struct Config {
        string name;
        uint weighting;
    }

    struct Create {
        address to;
        string name;
    }

    struct Toolbox {
        uint tokenId;
        string name;
    }

    struct Stat {
        string toolboxName;
        uint minted;
    }

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IERC20 public token;

    uint private _nextTokenId;

    ERC20Payments.Payee[] private _payees;
    Config[] private _config;
    uint[] private _options;
    uint public price;

    mapping(uint => string) public toolboxes;
    mapping(uint => address) private _requests;
    mapping(address => mapping(string => uint)) private _stats;
    mapping(string => uint) private _globalStats;

    constructor(string memory uri, string memory name, string memory symbol, IERC20 token_, IRandom random, Config[] memory config, uint price_, ERC20Payments.Payee[] memory payees) Nft(uri) ERC721(name, symbol) RandomConsumer(random) {
        token = token_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setConfig(config);
        _setPrice(price_);
        _setPayees(payees);
    }

    function setConfig(Config[] calldata config) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setConfig(config);
    }

    function _setConfig(Config[] memory config) private {
        delete _config;
        delete _options;
        for(uint i; i < config.length; i ++) {
            _config.push(config[i]);
            _options.push(config[i].weighting);
        }
    }

    function getStatsOf(address user) external view returns(Stat[] memory stats) {
        stats = new Stat[](_config.length);
        for(uint i; i < _config.length; i ++) {
            stats[i] = Stat({toolboxName: _config[i].name, minted: _stats[user][_config[i].name]});
        }
    }

    function getGlobalStats() external view returns(Stat[] memory stats) {
        stats = new Stat[](_config.length);
        for(uint i; i < _config.length; i ++) {
            stats[i] = Stat({toolboxName: _config[i].name, minted: _globalStats[_config[i].name]});
        }
    }

    function getToolboxesOf(address user) external view returns(Toolbox[] memory res) {
        res = new Toolbox[](balanceOf(user));
        for(uint i; i < balanceOf(user); i++) res[i] = Toolbox({tokenId: tokenOfOwnerByIndex(user, i), name: toolboxes[tokenOfOwnerByIndex(user, i)]});
    }

    function burn(uint tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function setPrice(uint newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPrice(newPrice);
    }

    function _setPrice(uint newPrice) private {
        price = newPrice;
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPayees(payees);
    }
    function _setPayees(ERC20Payments.Payee[] memory payees) private {
        delete _payees;
        for(uint i; i < payees.length; i ++) _payees.push(payees[i]);
    }

    function create(Create[] memory inputs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint i; i < inputs.length; i ++) _create(inputs[i]);
    }

    function mint(uint numberOf) external {
        ERC20Payments.splitFrom(token, msg.sender, numberOf * price, _payees);
        for(uint i; i < numberOf; i ++) _requests[_requestRandom(_options)] = msg.sender;
    }

    function _fulfillRandom(uint requestId, uint result) internal override {
        _stats[_requests[requestId]][_config[result].name] ++;
        _create(Create({to: _requests[requestId], name: _config[result].name}));
    }

    function _create(Create memory input) internal {
        uint tokenId = _nextTokenId;
        _nextTokenId ++;
        _mint(input.to, tokenId);
        toolboxes[tokenId] = input.name;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(Nft, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}