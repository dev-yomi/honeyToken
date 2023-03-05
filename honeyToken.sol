pragma solidity ^0.8.0;

//import relevant contracts
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract HoneyToken is ERC20, Ownable {

    //mints 100m tokens to dev on deployment - to be used to faciliate liquidity against ~20%+ of mint proceeds at mint-out stage
    constructor() ERC20("HONEY","HONEY") {
        _mint(msg.sender, 100000000 ether);
    }

    //sets BURN_RATE to 25 (2.5%)
    uint256 public constant BURN_RATE = 25;
    uint public MIN_WAIT = 14400; //1 day at 6 second blocktime.

    //import bera NFT contract address and new ERC721 with that address
    address public beraAddress = 0xbA7a1696F459430b9040541260e24332F402e980;
    ERC721 beraNFT = ERC721(beraAddress);

    //mapping to check if a specific beraNFT has claimed (each bera can only claim once)
    //mapping defaults to false
    mapping (uint256 => bool) public beraClaimStatus;
    mapping (uint256 => uint256) public beraLastClaimBlock;
    mapping (uint256 => uint256) public beraLeftToClaim;

    //declare and set paused status of contract
    bool public claimPaused = true;
    
    //unpase and pause, respectively. onlyOwner restricted for obvious reasons
    function unpause() public onlyOwner {
        claimPaused = false;
    }

    function pause() public onlyOwner {
        claimPaused = true;
    }
    
    //main function for beras to claim with, passing ID of bera they want to claim with
    function claimHoney(uint256 tokenId) public {
        require(claimPaused == false, "Claim is paused!");//require contract to be unpaused
        require(beraNFT.ownerOf(tokenId) == msg.sender, "You don't own that bera!");//require that msg.sender owns the bera they are claiming for
        require(beraLeftToClaim[tokenId] > 0);
        require(block.number - beraLastClaimBlock[tokenId] >= MIN_WAIT, "This bera already claimed their honey for today!");//require that the bera hasn't claimed already
        if(beraClaimStatus[tokenId] == false){
            beraClaimStatus[tokenId] = true;
            beraLeftToClaim[tokenId] = 30000 ether;
        }
        beraLastClaimBlock[tokenId] = block.number;//set that bera ID's lastClaimBlock to current block
        beraLeftToClaim[tokenId] -= 300 ether;
        _mint(msg.sender, 300 ether);//mint 300 tokens to msg.sender - doing this AFTER setting the claimState to true to prevent reentrancy attacks minting multiple times from same bera
        //beras can only claim 300 honey per day
    }


    // Override the _transferFrom function to implement the burn
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender(); //_msgSender() is used as it returns msg.sender, as well as end user
        uint256 burnAmount = (amount * BURN_RATE) / 1000; //burn rate calculation to land at 2.5% of tokens sent
        _spendAllowance(from, spender, amount); //update allowances
        _transfer(from, to, amount-burnAmount); //call _transfer() but for Amount-burnAmount
        _burn(spender, burnAmount); //burn burnAmount from sender
        return true;
    }
    // Override the _transfer function to implement the burn
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        uint256 burnAmount = (amount * BURN_RATE) / 1000; 
        _transfer(msg.sender, to, amount-burnAmount); 
        _burn(msg.sender, burnAmount);
        return true;
    }

}
