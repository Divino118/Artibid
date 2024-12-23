# Artibid - NFT Auction Smart Contract

Artibid is a decentralized NFT auction platform implemented as a smart contract on the Stacks blockchain. It enables users to create and participate in time-based auctions for NFTs, with secure handling of bids and automatic settlement of transactions.

## Features

- Create time-bounded NFT auctions
- Place bids with automatic refunds of previous bids
- Secure transfer of NFTs and STX tokens
- Auction tracking and management
- Comprehensive auction and bid history
- Support for any NFT implementing the standard NFT trait

## Contract Functions

### Administrative Functions

- `update-global-time`: Updates the contract's global timestamp (admin only)

### Core Auction Functions

- `initiate-auction`: Create a new NFT auction
- `place-bid`: Place a bid on an active auction
- `finalize-auction`: Complete an auction and transfer assets

### Read-Only Functions

- `get-auction-details`: Get details of a specific auction
- `get-bid-details`: Get bid history for a specific auction and bidder
- `get-current-timestamp`: Get the current contract timestamp
- `get-all-auctions`: Get a list of all auction IDs
- `get-open-auctions`: Get a list of currently open auctions
- `get-auctions-by-creator`: Get auctions created by a specific address
- `get-auctions-by-closing-time`: Get auctions closing before a specific time
- `get-auction-count`: Get total number of auctions
- `get-open-auction-count`: Get number of open auctions

## Technical Details

### NFT Standard Trait

The contract expects NFTs to implement the following trait:
```clarity
(define-trait nft-standard
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response principal uint))
    )
)
```

### Error Codes

- `u100`: Not authorized
- `u101`: Auction not found
- `u102`: Auction closed
- `u103`: Insufficient bid
- `u104`: Auction in progress
- `u105`: Invalid NFT contract
- `u106`: Transfer failed
- `u107`: Invalid time
- `u108`: Invalid token ID
- `u109`: Invalid price
- `u110`: Invalid duration
- `u111`: Invalid auction ID
- `u112`: List full

### Storage

- Auctions are stored in `auction-records` map
- Bid history is stored in `bid-history` map
- Active auction IDs are tracked in `auction-list` (limited to 1000 entries)

## Usage Examples

### Creating an Auction

```clarity
(contract-call? .artibid initiate-auction .my-nft u123 u1000000 u86400)
```
This creates an auction for token #123 from the my-nft contract with a minimum bid of 1 STX and duration of 24 hours.

### Placing a Bid

```clarity
(contract-call? .artibid place-bid u1 u1500000)
```
This places a bid of 1.5 STX on auction #1.

### Finalizing an Auction

```clarity
(contract-call? .artibid finalize-auction u1 .my-nft)
```
This finalizes auction #1 and transfers the NFT and STX to the appropriate parties.

## Limitations

- Maximum of 1000 tracked auctions
- No partial refunds (bids must be higher than current highest bid)
- Time-based mechanics rely on manual timestamp updates

## Security Considerations

- NFTs are held in escrow by the contract during auctions
- Automatic refund of outbid amounts
- Only auction creator can finalize auction
- Timestamps must be updated by contract owner
- Reserve price enforcement
- Proper validation of all inputs

## Contract Dependencies

- Stacks blockchain
- NFT contract implementing the standard NFT trait