// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Use console.log for Hardhat debugging
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

/**
 * @title Jackpotbox
 * @notice A simple jackpot box contract
 */
contract Jackpotbox is IEntropyConsumer {
    // variables
    uint256 private constant ROLL_IN_PROGRESS = 42;

    IEntropy entropy;

    // events
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event PrizePoolWon(address indexed winner, uint256 prizePool);
    event JackpotWon(address indexed winner, uint256 jackpot);
    event EnteredJackpot(address indexed player, uint256 entryPrice);

    address public admin; // admin address
    address public spiliter; // spiliter address
    address public oracle; // oracle address

    uint public prizePool = 10; // prize pool
    uint public prizePoolOffset = 5; // prize pool offset
    uint public jackpot = 0; // jackpot
    uint public counter = 0; // counter
    uint public minChancePrizepool = 10; // min chance prize pool
    uint public minChanceJackpot = 100; // min chance jackpot
    uint public fee = 10; // fee
    uint public entryPrice = 1; // entry price
    bytes32 public userRandomNumber1;

    mapping(bytes32 => address) private s_rollers;
    mapping(address => uint256) private s_results;
    mapping(uint64 => bytes32) private requestIdBySequence;

    // admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    // oracle modifier
    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle can call this function");
        _;
    }

    // constructor
    constructor(address entropyAddress) {
        admin = msg.sender; // set admin to the contract deployer address
        spiliter = msg.sender; // set spiliter to the contract deployer address
        oracle = msg.sender; // set oracle to the contract deployer address

        entropy = IEntropy(entropyAddress);
    }

    function entropyCallback(
        uint64 sequenceNumber,
        address provider,
        bytes32 randomNumber
    ) internal override {
        // Implement your callback logic here.
        bytes32 requestId = requestIdBySequence[sequenceNumber];
        address player = s_rollers[requestId];

        require(player != address(0), "Invalid callback");

        uint256 rand = uint256(randomNumber);
        emit DiceLanded(requestId, rand);

        // Prizepool logic
        uint256 prizeChanceDenominator = minChancePrizepool *
            (100 / prizePoolOffset);
        bool wonPrize = (rand % prizeChanceDenominator == 0);

        // Jackpot logic
        bool wonJackpot = (rand % (minChanceJackpot + counter) == 0);

        // if prize pool win, transfer prize pool to winner and reduce counter
        if (wonPrize) {
            jackpot -= prizePool;
            payable(player).transfer(prizePool);
            counter = counter - (prizePool / entryPrice);
            emit PrizePoolWon(player, prizePool);
        }

        // if jackpot win, transfer jackpot to winner and spiliter and reduce counter
        if (wonJackpot) {
            payable(player).transfer((jackpot * 4) / 10);
            payable(spiliter).transfer(jackpot / 10);
            counter = (counter * 4) / 10;
            emit JackpotWon(player, jackpot);
        }

        // increment counter
        counter++;

        s_results[player] = 0;

        emit EnteredJackpot(player, entryPrice);
    }

    // admin only add jackpot
    function adminAddJackpot() public payable onlyAdmin {
        jackpot += msg.value;
    }

    // enter jackpot
    function enterJackpot() public payable {
        require(msg.value == entryPrice, "Invalid entry price"); // require entry price

        require(s_results[msg.sender] == 0, "Already rolled");

        jackpot += entryPrice;

        bytes32 userSeed = keccak256(
            abi.encodePacked(block.number, msg.sender, address(this))
        );

        // Get the default provider and the fee for the request
        address entropyProvider = entropy.getDefaultProvider();
        uint256 fee1 = entropy.getFee(entropyProvider);

        require(
            address(this).balance >= fee1,
            "Insufficient funds for entropy fee"
        );

        // Request the random number with the callback
        uint64 sequenceNumber = entropy.requestWithCallback{value: fee1}(
            entropyProvider,
            userSeed
        );
        bytes32 requestId = keccak256(
            abi.encodePacked(sequenceNumber, msg.sender)
        );
        // Store the sequence number to identify the callback request

        requestIdBySequence[sequenceNumber] = requestId;
        s_rollers[requestId] = msg.sender;
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    // fulfillRandom function
    function fulfillRandom(bytes32 requestId, uint256 rand) public onlyOracle {
        // emitting event to signal that dice landed
        emit DiceLanded(requestId, rand);

        // Prizepool logic
        uint256 prizeChanceDenominator = minChancePrizepool *
            (100 / prizePoolOffset);
        bool wonPrize = (rand % prizeChanceDenominator == 0);

        // Jackpot logic
        bool wonJackpot = (rand % (minChanceJackpot + counter) == 0);

        // if prize pool win, transfer prize pool to winner and reduce counter
        if (wonPrize) {
            jackpot -= prizePool;
            payable(s_rollers[requestId]).transfer(prizePool);
            counter = counter - (prizePool / entryPrice);
            emit PrizePoolWon(s_rollers[requestId], prizePool);
        }

        // if jackpot win, transfer jackpot to winner and spiliter and reduce counter
        if (wonJackpot) {
            payable(s_rollers[requestId]).transfer((jackpot * 4) / 10);
            payable(spiliter).transfer(jackpot / 10);
            counter = (counter * 4) / 10;
            emit JackpotWon(s_rollers[requestId], jackpot);
        }

        // increment counter
        counter++;

        s_results[s_rollers[requestId]] = 0;

        emit EnteredJackpot(s_rollers[requestId], entryPrice);
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

    // set oracle
    function setOracle(address newOracle) public onlyAdmin {
        oracle = newOracle;
    }

    // This method is required by the IEntropyConsumer interface.
    // It returns the address of the entropy contract which will call the callback.
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }
}
