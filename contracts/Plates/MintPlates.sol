//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "./Plates.sol";
import "./PlateRegister.sol";

contract MintPlates {
    uint public mintPrice;
    bool public ended;
    uint public totalMinted;
    uint public maxMinted;
    Plates internal _plates;
}