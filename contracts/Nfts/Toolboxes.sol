// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@thetrees1529/solutils/contracts/gamefi/RandomConsumer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Toolboxes is ERC1155PresetMinterPauser, RandomConsumer, ERC721Enumerable, ReentrancyGuard {

    using ERC20Payments for IERC20;

    struct Config {
        uint toolboxId;
        uint weighting;
    }

    struct Balance {
        uint toolboxId;
        uint balance;
        uint[] erc721TokenIds;
    }

    struct ERC721Details {
        uint tokenId;
        uint toolboxId;
    }

    struct StatsView {
        uint toolboxId;
        uint totalMinted;
    }

    struct ERC721ToERC1155 {
        uint erc1155TokenId;
        uint index;
    }

    ERC20Payments.Payee[] private _payees;
    IERC20 public token;
    Config[] private _configs;
    uint public price;
    mapping(uint => uint) private _stats;
    mapping(address => uint[]) private _history;
    mapping(uint => ERC721ToERC1155) private _erc721ToErc1155;
    mapping(address => mapping(uint => uint[])) private _erc721sOf;
    uint private _nextTokenId;
    

    //input to chainlink intermediary
    uint[] private _options;
    mapping(uint => address) private _requests;

    //ALWAYS HAVE PAYEES BECAUSE IF THERE ARE NONE THEN THEY WILL GET THE SHIT FOR FREE
    constructor(string memory uri, string memory name, IRandom random, IERC20 token_, ERC20Payments.Payee[] memory payees, uint price_, Config[] memory configs) ERC1155PresetMinterPauser(uri) RandomConsumer(random) ERC721(uri, name) {
        token = token_;
        _setPayees(payees);
        _setPrice(price_);
        _setConfigs(configs);
    }

    function toolboxIdFor(uint erc721TokenId) public view returns(uint) {
        require(_exists(erc721TokenId), "Not minted.");
        return _erc721ToErc1155[erc721TokenId].erc1155TokenId;
    }

    function getStats() external view returns(StatsView[] memory history) {
        history = new StatsView[](_configs.length);
        for(uint i; i < history.length; i ++) {
            history[i] = StatsView(_configs[i].toolboxId, _stats[_configs[i].toolboxId]);
        }
    }

    function getHistory(address addr, uint numberOf) external view returns(uint[] memory history) {
        uint[] storage _history_ = _history[addr];
        numberOf = numberOf <= _history_.length ? numberOf : _history_.length;
        history = new uint[](numberOf);
        uint start = _history_.length - numberOf;
        for(uint i = start; i < _history_.length; i ++) {
            history[i - start] = _history_[i];
        }
    }

    function purchase(uint numberOf) whenNotPaused external {
        for(uint i; i < numberOf; i ++) {
            _purchase();
        }
    }

    function getERC721sOf(address addr) external view returns(ERC721Details[] memory erc721Details) {
        uint bal = balanceOf(addr) - 1;
        erc721Details = new ERC721Details[](bal);
        for(uint i; i < bal; i ++) {
            uint tokenId = tokenOfOwnerByIndex(addr, i);
            erc721Details[i] = ERC721Details(tokenId, _erc721ToErc1155[tokenId].erc1155TokenId);
        }
    }
    function getBalances(address addr) external view returns(Balance[] memory balances) {
        balances = new Balance[](_configs.length);
        for(uint i; i < balances.length; i ++) {
            balances[i] = Balance(_configs[i].toolboxId, balanceOf(addr, _configs[i].toolboxId), _erc721sOf[addr][_configs[i].toolboxId]);
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
        _history[from].push(config.toolboxId);
        uint toolboxId = config.toolboxId;
        _mint(from, toolboxId, 1, "");
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal override(ERC1155, ERC721) {
        ERC1155._setApprovalForAll(owner, operator, approved);
        ERC721._setApprovalForAll(owner, operator, approved);
    }


    //accounting for erc1155 transfers (updating erc721 side)
    function _beforeTokenTransfer(address operator, address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data) internal override {
        if(magicLock) return super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        magicLock = true;

        uint len = ids.length;
        for(uint i; i < len; i ++) {
            uint id = ids[i];
            uint amount = amounts[i];


            for(uint j; j < amount; j ++) {
                if(from != address(0) && to != address(0)) {
                    //transfer an erc721 it represents
                    uint tokenId = _removeErc721From(from, id);
                    _transfer(from, to, tokenId);
                    _erc721sOf[to][id].push(tokenId);
                }
                if(to == address(0) && from != address(0)) {
                    //burn an erc721 it represents
                    _burn(_removeErc721From(from, id));
                }
                if(from == address(0) && to != address(0)) {
                    //mint an erc721 it represents
                    uint tokenId = _newERC721TokenId();
                    _mint(to, tokenId);

                    //add to erc721 tracking
                    _erc721sOf[to][id].push(tokenId);
                    _erc721ToErc1155[tokenId] = ERC721ToERC1155(id, _erc721sOf[to][id].length - 1);
                }
            }

        }
        
        magicLock = false;

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //accounting for erc721 transfers (updating erc1155 side)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        if(magicLock) return super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        magicLock = true;

        if(from != address(0) && to != address(0)) {

            //transfer the erc1155 it represents
            ERC721ToERC1155 storage info = _erc721ToErc1155[firstTokenId];
            uint erc1155TokenId = info.erc1155TokenId;
            _safeTransferFrom(from, to,erc1155TokenId, 1, "");

            //account for transfer 
            _erc721sOf[from][erc1155TokenId][info.index] = _erc721sOf[from][erc1155TokenId][_erc721sOf[from][erc1155TokenId].length - 1];
            _erc721sOf[from][erc1155TokenId].pop();
        }

        if(to == address(0) && from != address(0)) {
            //burn an erc1155 it represents
            _burn(from, _erc721ToErc1155[firstTokenId].erc1155TokenId, 1);
        }
        magicLock = false;
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }


    //prevents eternal loop back and forth between _beforeTokenTransfer on erc721 and erc1155.
    bool private magicLock;

    function _removeErc721From(address addr, uint id) private returns(uint tokenId) {
        uint[] storage erc721s = _erc721sOf[addr][id];
        tokenId = erc721s[erc721s.length - 1];
        erc721s.pop();
    }

    function _newERC721TokenId() private returns(uint newTokenId) {
        newTokenId = _nextTokenId;
        _nextTokenId ++;
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721, ERC1155) {
        _setApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view override(IERC721, ERC721, ERC1155) returns (bool) {
        return super.isApprovedForAll(account, operator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC1155PresetMinterPauser) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}