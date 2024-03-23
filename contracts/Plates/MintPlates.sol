//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Plates.sol";
import "./PlateRegister.sol";

contract MintPlates is Ownable {

    struct MintInput {
        string plate;
        string background;
    }

    address public beneficiary;
    uint public mintPrice;
    bool public ended;
    uint public totalMinted;
    uint public maxMinted;
    Plates public plates;
    PlateRegister public plateRegister;

    constructor(address beneficiary_, Plates plates_, PlateRegister plateRegister_, uint mintPrice_, uint maxMinted_) {
        beneficiary = beneficiary_;
        plates = plates_;
        plateRegister = plateRegister_;
        mintPrice = mintPrice_;
        maxMinted = maxMinted_;
    }

    function end() external onlyOwner {
        ended = true;
    }

    function mint(MintInput[] memory mintInput) external payable {
        uint payment = mintInput.length * mintPrice;
        require(msg.value == payment, "Incorrect funds.");
        require(!ended, "Ended.");
        require(totalMinted + mintInput.length <= maxMinted, "Too many.");
        totalMinted += mintInput.length;

        uint supply = plates.totalSupply();
        plates.mint(msg.sender, mintInput.length);
        for (uint i; i < mintInput.length; i++) {
            plateRegister.registerPlate(supply + i, mintInput[i].plate, mintInput[i].background);
        }

        (bool succ,) = beneficiary.call{value: msg.value}("");
        require(succ, "Transfer failed.");
    }

}