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
    address public spiliter; // spiliter address

    uint public prizePool = 10; // prize pool
    uint public prizePoolOffset = 5; // prize pool offset
    uint public jackpot = 0; // jackpot
    uint public counter = 0; // counter
    uint public minChancePrizepool = 10; // min chance prize pool
    uint public minChanceJackpot = 100; // min chance jackpot
    uint public fee = 10; // fee
    uint public entryPrice = 10; // entry price

    // only admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // constructor
    constructor() {
        admin = msg.sender; // set admin to the contract deployer address
        spiliter = msg.sender; // set spiliter to the contract deployer address
    }

    // admin only add jackpot
    function adminAddJackpot() public payable onlyAdmin {
        jackpot += msg.value;
    }

    // enter jackpot
    function enterJackpot() public payable {
        require(msg.value == entryPrice, "Invalid entry price"); // require entry price

        // determine if this is a winner or not for prize pool
        bool prizePoolWin = _isWinner(
            1,
            minChancePrizepool * (100 / prizePoolOffset)
        );

        // determine if this is a winner or not for jackpot
        bool jackpotWin = _isWinner(1, minChanceJackpot + counter);

        // if prize pool win, transfer prize pool to winner and reduce counter
        if (prizePoolWin) {
            jackpot -= prizePool;
            payable(msg.sender).transfer(prizePool);
            counter = counter - (prizePool / entryPrice);
        }

        // if jackpot win, transfer jackpot to winner and spiliter and reduce counter
        if (jackpotWin) {
            payable(msg.sender).transfer((jackpot * 4) / 10);
            payable(spiliter).transfer(jackpot / 10);
            counter = (counter * 4) / 10;
        }

        // add entry price to jackpot and increment counter
        jackpot += entryPrice;
        counter++;
    }

    // determine if this is a winner or not
    function _isWinner(uint total, uint chance) internal view returns (bool) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        msg.sender
                    )
                )
            ) %
                100 <
            total * chance * 100;
    }

    // get jackpot
    function getJackpot() public view returns (uint) {
        return jackpot;
    }

    // get counter
    function getCounter() public view returns (uint) {
        return counter;
    }

    // set spiliter
    function setSpiliter(address newSpiliter) public onlyAdmin {
        spiliter = newSpiliter;
    }
}
