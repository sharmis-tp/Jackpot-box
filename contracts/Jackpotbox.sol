// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Use console.log for Hardhat debugging
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Jackpotbox
 * @notice A simple jackpot box contract
 */
contract Jackpotbox is VRFConsumerBaseV2 {
    // variables
    uint256 private constant ROLL_IN_PROGRESS = 42;

    // events
    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);
    event PrizePoolWon(address indexed winner, uint256 prizePool);
    event JackpotWon(address indexed winner, uint256 jackpot);
    event EnteredJackpot(address indexed player, uint256 entryPrice);

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

    uint64 s_subscriptionId;
    address s_owner;
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 s_keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    // mapping for requestId to player
    mapping(uint256 => address) public requestIdToPlayer;

    // only admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // constructor
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;

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

        require(s_results[msg.sender] == 0, "Already rolled");
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_rollers[requestId] = msg.sender;
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    // fulfillRandomWords function
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // transform the result to a number between 1 and 20 inclusively
        uint256 rand = randomWords[0];

        // assign the transformed value to the address in the s_results mapping variable
        s_results[s_rollers[requestId]] = rand;

        // emitting event to signal that dice landed
        emit DiceLanded(requestId, rand);

        // Prizepool logic
        uint256 prizeChanceDenominator = minChancePrizepool *
            (100 / prizePoolOffset);
        bool wonPrize = (rand % prizeChanceDenominator == 0);

        // Jackpot logic
        bool wonJackpot = ((rand / 1e6) % (minChanceJackpot + counter) == 0);

        // if prize pool win, transfer prize pool to winner and reduce counter
        if (wonPrize) {
            jackpot -= prizePool;
            payable(msg.sender).transfer(prizePool);
            counter = counter - (prizePool / entryPrice);
            emit PrizePoolWon(msg.sender, prizePool);
        }

        // if jackpot win, transfer jackpot to winner and spiliter and reduce counter
        if (wonJackpot) {
            payable(msg.sender).transfer((jackpot * 4) / 10);
            payable(spiliter).transfer(jackpot / 10);
            counter = (counter * 4) / 10;
            emit JackpotWon(msg.sender, jackpot);
        }

        // add entry price to jackpot and increment counter
        jackpot += entryPrice;
        counter++;
        emit EnteredJackpot(msg.sender, entryPrice);
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
