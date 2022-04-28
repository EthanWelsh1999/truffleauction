// This code comes from the Solidity Documentation website (https://docs.soliditylang.org/en/v0.5.11/solidity-by-example.html#blind-auction)
// It is suitable for the purpose of this website

// The modifications I have made primarily concern the transfer of physical goods, which this auction site is designed for.
// Before the auction ends and money is transferred, the beneficiary must confirm that they have sent the requested good and the highest bidder must confirm they have received it.

// The auction can now also be cancelled, resulting in no transfer of money.
// The beneficiary can cancel up until the point they confirm they have sent the good.

// Sections I have modified will be denoted by ***MODIFIED HERE***

pragma solidity >=0.4.22 <0.9.0;

contract SimpleAuction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address payable public beneficiary;
    uint public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // ***MODIFIED HERE***
    // This variable is to confirm the beneficiary has sent the good they are selling
    bool goodSent;

    // This variable is set to true when the winner of the auction confirms that they have received the good they have paid for
    bool goodReceived;

    // This variable is set to true when the auction is cancelled
    bool cancelled;
    // This event fires when the auction is cancelled
    event AuctionCancelled();
    // This event fires when the auction is over and the good has been confirmed sent.
    event AuctionEnded();
    // This event fires when the good is confirmed received
    event GoodReceived();

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionWon(address winner, uint amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.

        // Revert the call if the bidding
        // period is over.
        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );

        // If the bid is not higher, send the
        // money back.
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        // ***MODIFIED HERE***
        // Require that the auction has not been cancelled
        require(!cancelled, "Auction has been cancelled");

        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // ***MODIFIED HERE***
    // Once the auction time has run out, the beneficiary can call this to confirm they have sent the good. Money is transferred here.
    function sendGood() public {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function.");
        require(!cancelled, "Auction has already been cancelled.");

        require(block.timestamp >= auctionEndTime, "Auction is still ongoing.");
        require(!goodSent, "sendGood has already been called.");

        // 2. Effects
        goodSent = true;
        emit AuctionWon(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }

    // Function called by the winner when they have received the good.
    function receiveGood() public {
        require(msg.sender == highestBidder, "Only the winner of the auction can call this.");
        require(goodSent, "Good has not been confirmed sent yet");
        require(!goodReceived, "goodReceived has already been called.");
        require(!cancelled, "Auction has already been cancelled.");

        goodReceived = true;
        emit GoodReceived();

    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions

        // ***MODIFIED HERE***
        // Added conditions so that the auction only ends when reception of good is confirmed, and that the auction is not cancelled.
        require(goodReceived, "The highest bidder has not yet confirmed the reception of their good.");
        require(!cancelled, "Auction has already been cancelled.");

        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;
        emit AuctionEnded();

    }

    // This function will cancel the auction before the money has been transferred and the good has been sent.
    function cancelAuction() public {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function.");
        require(!goodSent, "sendGood has already been called.");
        require(!cancelled, "Auction has already been cancelled.");

        cancelled = true;
        emit AuctionCancelled();

        // Put the current highest bid in the pending withdrawals queue
        pendingReturns[highestBidder] += highestBid;
    }

}