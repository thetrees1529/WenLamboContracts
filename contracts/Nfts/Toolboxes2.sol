// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";


contract Toolboxes is ERC721Enumerable, RandomConsumer, AccessControl {

    constructor(string memory name, string memory symbol, IERC20 token_, IRandom random) ERC721(name, symbol) RandomConsumer(random) {
        token = token_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IERC20 public token;

    uint private _nextTokenId;

    ERC20Payments.Payee[] private _payees;
    Config[] private _config;
    uint[] private _options;
    uint public price;

    mapping(uint => string) public toolboxes;
    mapping(uint => address) private _requests;

    function setConfig(Config[] calldata config) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _config;
        delete _options;
        for(uint i; i < config.length; i ++) {
            _config.push(config[i]);
            _options.push(config[i].weighting);
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
        price = newPrice;
    }

    function setPayees(ERC20Payments.Payee[] memory payees) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
        _create(Create({to: _requests[requestId], name: _config[result].name}));
    }

    function _create(Create memory input) internal {
        uint tokenId = _nextTokenId;
        _nextTokenId ++;
        _mint(input.to, tokenId);
        toolboxes[tokenId] = input.name;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}