//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AHILLE is ERC20, AccessControl {

    struct TransferInput {
        address to;
        uint amount;
    }

    struct TransferFromInput {
        address from;
        address to;
        uint amount;
    }
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);} 

    bytes32 public constant OPT_OUT_SKIP_ALLOWANCE = keccak256("OPT_OUT_SKIP_ALLOWANCE");

    mapping(address => mapping(address => uint)) private _volume;

    function getVolume(address from, address to) external view returns(uint) {return _volume[from][to];}

    function mint(address account, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {_mint(account, amount);}

    function burn(uint amount) external {_burn(msg.sender, amount);}

    function burnFrom(address account, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {_burn(account, amount);}

    function optOutSkipAllowance() external {
        _grantRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function optInSkipAllowance() external {
        _revokeRole(OPT_OUT_SKIP_ALLOWANCE, msg.sender);
    }

    function transferFrom(address from, address to, uint amount) public override returns(bool) {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(OPT_OUT_SKIP_ALLOWANCE, from)) return super.transferFrom(from, to, amount);
        _transfer(from, to, amount);
        return true;
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

    function _afterTokenTransfer(address from, address to, uint amount) internal override {
        _volume[from][to] += amount;
    }

}



