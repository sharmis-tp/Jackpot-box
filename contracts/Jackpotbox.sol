// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Use console.log for Hardhat debugging
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Jackpotbox
 * @notice A simple jackpot box contract
 */
contract Jackpotbox {
    address public admin; // admin address

    uint public prizePool = 1000; // prize pool
    uint public prizePoolOffset = 5; // prize pool offset
    uint public jackpot = 0; // jackpot
    uint public counter = 0; // counter
    uint public minChancePrizepool = 1000; // min chance prize pool
    uint public minChanceJackpot = 10000; // min chance jackpot
    uint public fee = 10; // fee
    uint public entryPrice = 1000; // entry price

    // only admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // constructor
    constructor() {
        admin = msg.sender; // set admin to the contract deployer address
    }

    // admin only add jackpot
    function adminAddJackpot() public payable onlyAdmin {
        jackpot += msg.value;
    }

    // enter jackpot
    function enterJackpot() public payable {
        require(msg.value == entryPrice, "Invalid entry price");
        prizePool += msg.value;
    }

    // get jackpot
    function getJackpot() public view returns (uint) {
        return jackpot;
    }
}
