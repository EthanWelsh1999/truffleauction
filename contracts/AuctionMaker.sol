// This contract is used to create a new auction.

// This code is adapted from https://github.com/brynbellomy/solidity-auction/blob/master/contracts/AuctionFactory.sol

pragma solidity >=0.4.22 <0.9.0;

import { SimpleAuction } from './SimpleAuction.sol';

contract AuctionMaker {

    // The list of created auctions
    address[] public auctions;

    // Event that fires when an auction is created
    event AuctionCreated(address auction, address beneficiary, address ttp, uint biddingTime);

    // Function to create a new auction with the assigned bidding time
    function createAuction(uint biddingTime, address ttp) public {
        address payable beneficiary = msg.sender;
        SimpleAuction auction = new SimpleAuction(biddingTime, beneficiary, ttp);

        auctions.push(address(auction));

        emit AuctionCreated(address(auction), msg.sender, ttp, biddingTime);
    }

    // Function to get the list of auctions
    function getAuction() public view returns (address[] memory) {
        return auctions;
    }

}