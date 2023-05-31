// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFarmWatcher {
    function deposited(address addr, uint deposited, uint amount) external;
    function withdrawn(address addr, uint deposited, uint amount) external;
    function claimed(address addr, uint deposited, uint amount) external;
}