//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "./IGasLeech.sol";
contract GasLeecher {
    IGasLeech public gasLeech;
    constructor(IGasLeech gasLeech_) {
        gasLeech = gasLeech_;
    }
    function _leech() internal {
        gasLeech.leech();
    }
}