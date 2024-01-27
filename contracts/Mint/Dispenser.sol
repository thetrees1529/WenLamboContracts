//SPDX-License-Identifier: Unlicensed
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
pragma solidity 0.8.19;

contract Dispenser is AccessControl {
    bytes32 public constant DISPENSER_ROLE = keccak256("DISPENSER_ROLE");
    IERC721Enumerable public nft;

    constructor(IERC721Enumerable nft_) {
        nft = nft_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(DISPENSER_ROLE) {
        _get(nft, to, amount);
    }

    function emergencyWithdraw(IERC721Enumerable nft_, address to, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _get(nft_, to, amount);
    }    

    function _get(IERC721Enumerable nft_, address to, uint amount) private {
        for(uint256 i = 0; i < amount; i++) {
            nft_.safeTransferFrom(address(this), to, nft.tokenOfOwnerByIndex(address(this), 0));
        }
    }
}