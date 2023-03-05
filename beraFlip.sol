pragma solidity ^0.8.0;

import "./binaryFlip.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract BeraFlip {

    // Allows the BinaryFlip library to be used on the uint256 data type
    using BinaryFlip for uint256;
    
    uint256 public lastFlipBlock; // The block number of the last flip
    uint256 public flipCount; // The number of flips that have occurred
    uint256 public totalWins; // The total number of wins
    uint256 public totalLosses; // The total number of losses
    uint256 public pot; // The total amount of money in the pot
    uint256 public cost = 1 ether; // The cost of making a flip.
    uint public minBlocks = 5;
    address public cantoBeraContractAdd;
    address public honeyToken;
    address public owner;
    bool public paused = false;
    
    event NewFlip(address indexed player, bool indexed win, uint256 indexed blockNumber, uint256 randomNumber);
    
    constructor(address _cantoBeraAddress, address _honeyToken) payable {
        // Initializes the lastFlipBlock, flipCount, totalWins, and totalLosses variables
        lastFlipBlock = block.number-5;
        flipCount = 0;
        totalWins = 0;
        totalLosses = 0;
        pot = msg.value;
        cantoBeraContractAdd = _cantoBeraAddress;
        honeyToken = _honeyToken;
        owner = msg.sender;
    }
    
    function flipCoin() public payable {
        IERC20 honeyContract = IERC20(honeyToken);
        ERC721 beraNFT = ERC721(cantoBeraContractAdd);
        require(!paused, "Game is paused!");
        require(beraNFT.balanceOf(msg.sender) > 0, "Grr! Only bera holders can play!");
        require(msg.value == cost, "flips cost 1 Canto!");
        require(address(this).balance > cost*2, "contract empty! :(");
        // Calls the flip function from the BinaryFlip library to generate a random number
        // Uses the lastFlipBlock and a minimum of 5 blocks between flips as input parameters
        uint nonce = uint(keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender, totalWins, totalLosses)));
        bytes32 hash = keccak256(abi.encodePacked(nonce, msg.sender, block.timestamp));
        uint minBlocksR = uint(hash) % 257;
        while (minBlocksR == 0 || minBlocksR < minBlocks) {
            hash = keccak256(abi.encodePacked(hash));
            minBlocksR = uint(hash) % 257;
        }
        uint256 randomNumber = BinaryFlip.flipBinary(lastFlipBlock, minBlocksR);
        lastFlipBlock = block.number - minBlocks;
        // Determines whether the player wins based on the random number
        bool win = (randomNumber == 1);
        // Increments the flipCount variable
        flipCount += 1;
        // If the player wins, increments the totalWins variable; otherwise, increments the totalLosses variable
        if (win) {
            totalWins += 1;
            pot -= msg.value;
            payable(address(msg.sender)).transfer(cost*2);
            if(honeyContract.balanceOf(address(this)) > 10 ether){
                honeyContract.transfer(msg.sender, 10 ether);
            }
        } else {
            totalLosses += 1;
            pot += msg.value;
            if(honeyContract.balanceOf(address(this)) > 1 ether){
                honeyContract.transfer(msg.sender, 1 ether);
            }
        }
        // Updates the lastFlipBlock variable to the current block number
        lastFlipBlock = block.number;
        // Emits the NewFlip event with the player's address, win status, block number, and random number
        emit NewFlip(msg.sender, win, block.number, randomNumber);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not the owner! Grrr!");
        _;
    }
    
    // Defines a function that allows users to retrieve the contract statistics
    function getStats() public view returns (uint256, uint256, uint256, uint256) {
        // Returns a tuple containing the lastFlipBlock, flipCount, totalWins, and totalLosses variables
        return (lastFlipBlock, flipCount, totalWins, totalLosses);
    }

    function changeCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function changeMinBlocks(uint256 newMin) public onlyOwner {
        minBlocks = newMin;
    }

    function togglePause() public onlyOwner {
        if(paused){
            paused = false;
        } else {
            paused = true;
        }
    }
    
}
