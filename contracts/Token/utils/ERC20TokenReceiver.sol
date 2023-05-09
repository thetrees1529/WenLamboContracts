//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC20TokenReceiver.sol";
abstract contract ERC20TokenReceiver is IERC20TokenReceiver, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20TokenReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}