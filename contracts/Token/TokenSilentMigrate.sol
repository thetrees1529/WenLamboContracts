//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "./Token.sol";

//CONTRACT NOT IN USE
contract TokenSilentMigrate is Token {
    constructor(Token old) Token(old.name(), old.symbol(), old.MAX_SUPPLY()) {}

}