//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
interface IERC20TokenReceiver {
    function onERC20Received(address from, uint256 amount, bytes calldata data) external returns (bytes4);
}