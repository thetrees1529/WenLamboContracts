//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "./Earn.sol";

contract UnlockHelper {


    function unlockAll(Earn earn) external {
        Nfvs nfvs = earn.nfvs();
        uint[] memory tokens = nfvs.tokensOfOwner(msg.sender);
        for (uint i = 0; i < tokens.length; i++) {
            nfvs.safeTransferFrom(msg.sender, address(this), tokens[i]);
            earn.unlock(tokens[i]);
            nfvs.safeTransferFrom(address(this), msg.sender, tokens[i]);
        }
        Token token = earn.token();
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

}