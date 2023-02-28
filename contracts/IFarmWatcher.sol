// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFarmWatcher {
    function deposited(address addr, uint amount) external;
    function withdrawn(address addr, uint amount) external;
    function claimed(address addr, uint amount) external;
}