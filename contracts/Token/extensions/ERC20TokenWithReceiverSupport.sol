//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "../utils/IERC20TokenReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
abstract contract ERC20TokenWithReceiverSupport is ERC20 {
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        super._transfer(sender, recipient, amount);
        
        if(ERC165Checker.supportsInterface(recipient, type(IERC20TokenReceiver).interfaceId)) {
            IERC20TokenReceiver(recipient).onERC20Received(sender, amount, "");
        }
    }
}
