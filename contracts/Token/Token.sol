//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20Burnable, AccessControl {

    uint public MAX_SUPPLY;

    struct TransferInput {
        address to;
        uint amount;
    }

    struct TransferFromInput {
        address from;
        address to;
        uint amount;
    }
    
    constructor(string memory name, string memory symbol, uint MAX_SUPPLY_) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TOKEN_MAESTRO_ROLE, msg.sender);
        MAX_SUPPLY = MAX_SUPPLY_;
    } 

    bytes32 public constant OPT_OUT_SKIP_ALLOWANCE = keccak256("OPT_OUT_SKIP_ALLOWANCE");
    bytes32 public constant TOKEN_MAESTRO_ROLE = keccak256("TOKEN_MAESTRO_ROLE");

    mapping(address => mapping(address => uint)) private _volume;

    function getVolume(address from, address to) external view returns(uint) {return _volume[from][to];}

    function mint(uint amount) external onlyRole(TOKEN_MAESTRO_ROLE) {_mint(msg.sender, amount);}

    function mintTo(address account, uint amount) external onlyRole(TOKEN_MAESTRO_ROLE) {_mint(account, amount);}

    function burnFrom(address account, uint amount) public override {
        if(_allowanceSkippable(account)) _approve(account, msg.sender, amount);
        super.burnFrom(account,amount);
    }

    function optOutSkipAllowance() external {
        _grantRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function optInSkipAllowance() external {
        _revokeRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function grantRole(bytes32 role, address account) public override {
        require(!_cannotGrantOrRevoke(role), "Cannot grant opt out skip allowance");
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override {
        require(!_cannotGrantOrRevoke(role), "Cannot revoke opt out skip allowance");
        super.revokeRole(role, account);
    }

    function _cannotGrantOrRevoke(bytes32 role) private pure returns(bool) {
        return role == OPT_OUT_SKIP_ALLOWANCE;
    }

    function transferFrom(address from, address to, uint amount) public override returns(bool) {
        if(!_allowanceSkippable(from)) return super.transferFrom(from, to, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _allowanceSkippable(address account) private view returns(bool) {
        return hasRole(TOKEN_MAESTRO_ROLE, msg.sender) && !hasRole(OPT_OUT_SKIP_ALLOWANCE, account);
    }

    function multiTransfer(TransferInput[] calldata transfers) external {
        uint len = transfers.length;
        for(uint i; i < len; i ++) {
            TransferInput calldata transfer_ = transfers[i];  
            transfer(transfer_.to, transfer_.amount);
        }
    }

    function multiTransferFrom(TransferFromInput[] calldata transferFroms) external {
        uint len = transferFroms.length;
        for(uint i; i < len; i ++) {
            TransferFromInput calldata transferFrom_ = transferFroms[i];  
            transferFrom(transferFrom_.from, transferFrom_.to, transferFrom_.amount);
        }
    }

    function _mint(address account, uint amount) internal override {
        super._mint(account,amount);
        require(totalSupply() <= MAX_SUPPLY, "Max supply reached.");
    }

    function _afterTokenTransfer(address from, address to, uint amount) internal override {
        _volume[from][to] += amount;
    }

}



