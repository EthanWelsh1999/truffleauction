// This code comes from the Solidity Documentation website (https://docs.soliditylang.org/en/v0.5.11/solidity-by-example.html#blind-auction)
// It is suitable for the purpose of this website

// The modifications I have made primarily concern the transfer of physical goods, which this auction site is designed for.
// The contract requires a trusted third-party to verify that the parties involved are behaving correctly.

// The beneficiary signs the auction when they have sent the good.
// The winner signs the auction when they confirm they have received the good.
// The TTP signs when they confirm that the beneficiary has sent the good.

// Money will only be transferred once 2/3 of the involved parties and the TTP have signed the auction.
// Assuming no foul play, the TTP will not need to even get involved.
// The TTP is chosen by the beneficiary of the auction.
// The contract also assumes that the TTP will act fairly between the two parties. In the site's front-end, when placing a bid you will ask to confirm that you trust the TPP.

// The auction can now also be cancelled, resulting in no transfer of money.
// The beneficiary can cancel up until the point someone signs the auction.

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

    // ***MODIFIED HERE***
    // Address of the TTP, used to verify the auction.
    address public ttp;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // ***MODIFIED HERE***
    // This map will contain all of the parties who have verified the transaction. 2/3 are needed to end the auction
    mapping(address => bool) signed;
    // Counts the number of signatures.
    uint sigCount;

    // This variable is set to true when the auction is cancelled
    bool cancelled;
    // This event fires when the auction is cancelled
    event AuctionCancelled();
    // This event fires when the auction is over.
    event AuctionEnded();

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
        address payable _beneficiary,
        address _ttp
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
        ttp = _ttp;
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

            // cast to payable
            address payable caller = msg.sender;

            if (!caller.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // ***MODIFIED HERE***
    // Once the auction time has run out, the involved parties need to sign off on the auction. Once 2/3 have signed it, then the auction can end and money can be transferred.
    function sign() public {
        require(msg.sender == beneficiary || msg.sender == highestBidder || msg.sender == ttp, "Only the involved parties can call this function.");
        require(!cancelled, "Auction has already been cancelled.");
        require(block.timestamp >= auctionEndTime, "Cannot sign before auction is over");
        require(signed[msg.sender] != true, "Cannot sign more than once.");

        // 2. Effects
        signed[msg.sender] = true;
        sigCount++;
        emit AuctionWon(highestBidder, highestBid);

        // Once there have been 2/3 signatures, end the auction and transfer the money
        if (sigCount >= 2) {
            emit AuctionEnded();
            ended = true;
            beneficiary.transfer(highestBid);
        }
        
    }


    // This function will cancel the auction before anyone has signed it.
    function cancelAuction() public {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function.");
        require(signed[beneficiary] != true, "Auction has already been signed");
        require(signed[highestBidder] != true, "Auction has already been signed");
        require(signed[ttp] != true, "Auction has already been signed");
        require(!cancelled, "Auction has already been cancelled.");

        cancelled = true;
        emit AuctionCancelled();

        // Put the current highest bid in the pending withdrawals queue
        pendingReturns[highestBidder] += highestBid;
    }

}