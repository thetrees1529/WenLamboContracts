//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "@thetrees1529/solutils/contracts/gamefi/Nft.sol";
import "./Vault.sol";

contract RandomPouch {
    
    struct Pouch {
        IERC20 token;
        uint amount;
        uint weighting;
    }

    uint private _nonce;
    Pouch[] private _pouches;
    Nft[] private _inputs;
    Vault public vault;
    IERC20 public mcv;

    constructor(Nft[] memory inputs_, Pouch[] memory pouches_, Vault vault_) {
        _inputs = inputs_;
        vault = vault_;
        _pouches = pouches_;
    }

    function pouches() external view returns (Pouch[] memory) {
        return _pouches;
    }

    function inputs() external view returns (Nft[] memory) {
        return _inputs;
    }

    function redeem(uint[] calldata tokenIds) external {

        for(uint i = 0; i < _inputs.length; i++) {
            _burn(_inputs[i], tokenIds[i], msg.sender);
        }

        uint totalWeighting;
        for (uint i = 0; i < _pouches.length; i++) {
            totalWeighting += _pouches[i].weighting;
        }

        uint random = uint(keccak256(abi.encode(_nonce))) % totalWeighting;
        _nonce++;

        for (uint i = 0; i < _pouches.length; i++) {
            if (random < _pouches[i].weighting) {
                vault.withdraw(_pouches[i].token,msg.sender, _pouches[i].amount);
                return;
            }
            random -= _pouches[i].weighting;
        }

    }

    function _burn(Nft nft, uint tokenId, address from) private {
        require(nft.ownerOf(tokenId) == from, "Not owner.");
        nft.burn(tokenId);
    }

}