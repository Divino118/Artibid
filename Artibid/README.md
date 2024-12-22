# Artibid NFT Auction Smart Contract

## Overview
Artibid is a decentralized NFT auction platform built on Stacks blockchain using Clarity smart contracts. It enables users to create, participate in, and manage NFT auctions with secure handling of both NFT transfers and STX payments.

## Features
- Create NFT auctions with customizable duration and reserve price
- Place bids with automatic refund handling for outbid participants
- Automatic auction finalization with secure transfer of NFTs and funds
- Complete bid history tracking
- Time-based auction mechanics with customizable timestamps
- Support for any NFT implementing the standard NFT trait

## Contract Details

### Constants
- `contract-owner`: The deploying address of the contract
- `base-bid`: Minimum bid amount in microSTX (default: 1,000,000 microSTX = 1 STX)

### Error Codes
- `err-not-authorized (u100)`: Caller not authorized for the operation
- `err-auction-not-found (u101)`: Specified auction does not exist
- `err-auction-closed (u102)`: Auction has already ended
- `err-insufficient-bid (u103)`: Bid amount too low
- `err-auction-in-progress (u104)`: Auction still in progress
- `err-invalid-nft-contract (u105)`: Invalid NFT contract address
- `err-transfer-failed (u106)`: STX or NFT transfer failed

## Public Functions

### `initiate-auction`
Creates a new auction for an NFT.

Parameters:
- `nft-contract`: NFT contract implementing the nft-standard trait
- `token-id`: ID of the NFT to auction
- `min-price`: Minimum acceptable bid in microSTX
- `duration`: Auction duration in block height units

Returns: Auction ID (uint)

### `place-bid`
Places a bid on an active auction.

Parameters:
- `auction-id`: ID of the target auction
- `bid-amount`: Bid amount in microSTX

Returns: Boolean indicating success

### `finalize-auction`
Concludes an auction after its closing time.

Parameters:
- `auction-id`: ID of the auction to finalize
- `nft-contract`: NFT contract address for verification

Returns: Boolean indicating success

### `update-global-time`
Updates the contract's global timestamp (admin only).

Parameters:
- `new-time`: New timestamp value

Returns: Boolean indicating success

## Read-Only Functions

### `get-auction-details`
Retrieves details of a specific auction.

Parameters:
- `auction-id`: ID of the auction

Returns: Auction record or none

### `get-bid-details`
Retrieves bid history for a specific participant in an auction.

Parameters:
- `auction-id`: ID of the auction
- `bidder`: Principal address of the bidder

Returns: Bid record or none

### `get-current-timestamp`
Returns the current global timestamp.

Returns: Current timestamp (uint)

```

## Testing

Create test scenarios in the `tests` directory covering:
- Auction creation
- Bid placement
- Auction finalization
- Error conditions
- NFT and STX transfers

## Usage Example

```clarity
;; Create new auction
(contract-call? .artibid initiate-auction .my-nft u1 u1000000 u100)

;; Place bid
(contract-call? .artibid place-bid u1 u1500000)

;; Finalize auction
(contract-call? .artibid finalize-auction u1 .my-nft)
```

## Security Considerations

1. Always verify NFT ownership before initiating auctions
2. Ensure sufficient STX balance before placing bids
3. Monitor auction closing times
4. Verify NFT contract addresses during finalization
5. Handle all error cases in client implementations
