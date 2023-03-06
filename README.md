# HoneyToken and BeraFlip

These 2 contracts work somehwat in tandem.

## HONEY, I burned the tokens!

HONEY is a basic ERC20 token that acts as an illiquid meme reward for holders of the Canto Beras NFT. It features;

- A 2.5% burn on every transaction
- A "stakeless" staking system that allows each bera NFT to claim a specific amount of HONEY each day, until distribution is accomplished, without the need to stake.

## BeraFlip!

The BeraFlip contract is a rudimentary coin-flip game I built using the BinaryFlip library found on my github.
The game is restricted to only allow holders of the Canto Beras NFT to play, and it costs 1 Canto each time.
The game rewards HONEY tokens, whether or not the player wins! 10 for a win, 1 for a loss.

### Issues with BeraFlip

While the game allows a max win amount of 1 Canto, which is not very much financially speaking, and will likely not attract any malicious intent...

THE RANDOM NUMBER GENERATION IS STILL TECHNCIALLY ABLE TO BE MANIPULATED

It relies on a blockhash in the past (predictable, though obfuscated a BIT with further hashing and use of minBlocksR).

My understanding is that it would be a tricky and expensive task to manipulate the RNG of the contract.
The low reward should hopefully result in any attack being a net negative financially, though I'm always happy to see someone prove me wrong!
(so if you CAN break it, please do! But also please show me how!)
