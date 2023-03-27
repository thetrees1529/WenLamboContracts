// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@thetrees1529/solutils/contracts/payments/Payments.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MintWithTokens.sol";
import "./Earn.sol";

contract MigrateSimulateMint is MintWithTokens {
    using Fees for uint;

    uint public startFrom;
    mapping(uint16 => bool) private _golds;
    Earn public earn;
    uint16 constant private splitInto = 256 / 16;

    constructor(Earn earn_, uint mintPrice_, uint maxMinted_, IERC20 token_, ERC20Payments.Payee[] memory payees, uint startFrom_) MintWithTokens(Nfvs(address(earn_.nfvs())),mintPrice_, maxMinted_, token_, payees) {
        startFrom = startFrom_;
        earn = earn_;
    }

    Fees.Fee private _lockRatio;

    function akhjsdfas(uint[] calldata a) external onlyOwner {
        for(uint i; i < a.length; i ++) {
            uint b = a[i];
            for(uint j; j < splitInto; j ++) {
                uint16 value = uint16(b / (2**(j * splitInto)));
                if(value != 0) _golds[value] = true;
            }
        }
    }

    function _beforeMint(address, uint numberOf) internal override {

        Earn.Stage[] memory stages = earn.getStages();
        uint stageIndex = stages.length - 1;

        Earn.Substage[] memory finalStageSubstages = stages[stageIndex].substages;
        uint finalStageSubstagesIndex = finalStageSubstages.length - 1;

        Earn.Location memory goldLocation = Earn.Location(stageIndex, finalStageSubstagesIndex);

        uint goldEarn = finalStageSubstages[finalStageSubstagesIndex].emission;
        uint baseEarn = earn.baseEarn();

        (uint parts, uint outOf) = earn.lockRatio();
        _lockRatio = Fees.Fee(parts, outOf);

        uint16 supply = uint16(_nfvs.totalSupply());
        uint last = supply + numberOf;

        uint time = block.timestamp - startFrom;

        for(uint16 i = supply; i < last; i++) {

            uint emission;

            if(_golds[i]) {
                emission = goldEarn;
                earn.setLocation(i, goldLocation);
            } else {
                emission = baseEarn;
            }

            uint toAccountFor = emission * 1 days * time;
            uint locked = toAccountFor.feesOf(_lockRatio);
            uint unlocked = toAccountFor - locked;

            earn.addToLocked(i, locked);
            earn.addToClaimable(i, unlocked);

        }
    }

}