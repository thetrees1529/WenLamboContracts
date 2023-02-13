pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@thetrees1529/solutils/contracts/payments/Fees.sol";

contract Farms is Ownable {
    using Fees for uint;
    struct Account {
        uint debt;
        uint unclaimed;
        uint shares;
    }
    struct FarmConfig {
        IERC20 sharesToken;
        IERC20 farmToken;
        uint emission;
    }
    struct Farm {
        uint lastUpdated;
        uint shares;
        FarmConfig config;
        Fees.Fee perShare;
        mapping(address => Account) accounts;
    }
    Farm[] private _farms;
    function farmCount() external view returns(uint) {
        return _farms.length;
    }
    function farmConfig(uint farmId) external view returns(FarmConfig memory) {
        return _farms[farmId].config;
    }
    function createFarm(FarmConfig calldata config) external onlyOwner {
        Farm storage farm = _farms.push();
        farm.config = config;
        farm.lastUpdated = block.timestamp;
        farm.perShare = Fees.Fee(0,1);
    }
    function updateFarm(uint farmId) public {
        Farm storage farm = _farms[farmId];
        uint timeSince = block.timestamp - farm.lastUpdated;
        uint earned = timeSince * farm.config.emission;
        
    }
    function editEmission(uint farmId, uint emission) external onlyOwner {
        _farms[farmId].config.emission = emission;
    }

}
