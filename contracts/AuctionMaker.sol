// This contract is used to create a new auction.

// This code is adapted from https://github.com/brynbellomy/solidity-auction/blob/master/contracts/AuctionFactory.sol

pragma solidity >=0.4.22 <0.9.0;

import { SimpleAuction } from './SimpleAuction.sol';

contract AuctionMaker {

    // The list of created auctions
    SimpleAuction[] public auctions;

    // Event that fires when an auction is created
    event AuctionCreated(SimpleAuction auction, address beneficiary, uint biddingTime);

    // Function to create a new auction with the assigned bidding time
    function createAuction(uint biddingTime) public {
        SimpleAuction auction = new SimpleAuction(biddingTime, payable(msg.sender));

        auctions.push(auction);

        emit AuctionCreated(auction, msg.sender, biddingTime);
    }

    // Function to get the list of auctions
    function getAuction() public view returns (SimpleAuction[] memory) {
        return auctions;
    }

}