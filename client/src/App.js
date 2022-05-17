import React, { Component } from "react";
import AuctionContract from "./contracts/SimpleAuction.json";
import AuctionMakerContract from "./contracts/AuctionMaker.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { web3: null, accounts: null, auctionMakerInstance: null, auctionData: [], timestamp: null };

  _inputBiddingTime = null;
  _inputTTP = null;
  _inputBid = null;

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      console.log(web3.givenProvider);

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();
      //console.log(accounts);

      const networkId = await web3.eth.net.getId();
      const deployedNetwork = AuctionMakerContract.networks[networkId];
      const instance = new web3.eth.Contract(
        AuctionMakerContract.abi,
        "0x092d26fda83e4071ce2C7918241127856213df5a"
      );

      console.log(instance);

      // Set web3 and accounts to the state, and call example
      this.setState({ web3, accounts, auctionMakerInstance: instance });
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  // Function to start a new auction
  newAuction = async () => {

    const biddingTime = this._inputBiddingTime.value;
    const ttp = this._inputTTP.value;

    console.log(biddingTime);
    console.log(ttp);

    const instance = this.state.auctionMakerInstance;
    const accounts = this.state.accounts;

    await instance.methods.createAuction(biddingTime, ttp, accounts[0]).send({ from: accounts[0] });
    await this.getAuctions();

  }

  cancelAuction = async (address) => {

  }

  signAuction = async (address) => {

  }

  endAuction = async (address) => {

  }

  bid = async (address) => {
    
  }

  // Updates the data concerning the current auctions
  getAuctions = async () => {

    const instance = this.state.auctionMakerInstance;
    const web3 = this.state.web3;
    let data = []
    let addresses = [];

    addresses = await instance.methods.getAuction().call();
    //console.log(addresses);

    const block = await web3.eth.getBlock("latest");
    const timestamp = block.timestamp;

    for (const address of addresses) {

      const auction = new web3.eth.Contract(
        AuctionContract.abi,
        String(address)
      );

      const beneficiary = await auction.methods.beneficiary().call();
      const ttp = await auction.methods.ttp().call();
      const highestBidder = await auction.methods.highestBidder().call();
      const highestBid = await auction.methods.highestBid().call();
      const endTime = await auction.methods.auctionEndTime().call();
      const sigCount = await auction.methods.sigCount().call();
      const cancelled = await auction.methods.cancelled().call();
      const ended = await auction.methods.ended().call();

      const timeRemaining = endTime - timestamp;
      const cancelable = (timeRemaining > 0 && cancelled === false);

      if (!cancelled && !ended) {
        data.push({ address, beneficiary, ttp, highestBid, highestBidder, endTime, timeRemaining, sigCount, cancelable });
      }

    }

    this.setState({ auctionData: data, timestamp });

  };

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contracts...</div>;
    }

    this.getAuctions();

    const auctions = this.state.auctionData;
    //console.log(auctions);

    return (
      <div className="App">

        <h1>Auctions</h1>

        <h2>Current Block Timestamp: {this.state.timestamp}</h2>

        <div className="form-create-auction">
          <h2>Create Auction</h2>
          <div>
            Bidding Time <input type="text" ref={x => this._inputBiddingTime = x} defaultValue={60} />
          </div>
          <div>
            TTP Address <input type="text" ref={x => this._inputTTP = x} defaultValue={'0x0000000000000000000000000000000000000000'} />
          </div>
          <button onClick={this.newAuction}>Create Auction</button>
        </div>

        <div>
          <table>
            <thead>
              <tr>
                <td>Address</td>
                <td>Beneficiary Address</td>
                <td>TTP Address</td>
                <td>Highest Bid</td>
                <td>Highest Bidder Address</td>
                <td>End Time</td>
                <td>Time Remaining (seconds)</td>
                {auction.timeRemaining <= 0 ? <td>Signature Count</td> : ""}
                <td>Actions</td>
                
              </tr>
            </thead>
            <tbody>
              {auctions.map(auction => {
                return (
                  <tr key={auction.address}>
                    <td>{auction.address.substr(0, 10)}</td>
                    <td>{auction.beneficiary.substr(0, 10)}</td>
                    <td>{auction.ttp}</td>
                    <td>{auction.highestBid}</td>
                    <td>{auction.highestBidder.substr(0, 10)}</td>
                    <td>{auction.endTime}</td>
                    <td>{auction.timeRemaining > 0 ? auction.timeRemaining : "Ended"}</td>
                    {auction.timeRemaining <= 0 ? <td>{auction.sigCount}</td> : ""}
                    <td>
                      {(auction.beneficiary != this.state.accounts[0]) && (auction.timeRemaining > 0) ? 
                      <div>Bid Amount: <input type="text" ref={x => this._inputBid = x} defaultValue={0} />
                      <button onClick={() => this.bid(auction.address)}>Place Bid</button></div> : ""}

                      {(auction.beneficiary == this.state.accounts[0]) && (auction.cancelable) ? 
                      <button onClick={() => this.cancelAuction(auction.address)}>Cancel</button> : ""}

                      {(((auction.beneficiary == this.state.accounts[0]) || (auction.highestBidder == this.state.accounts[0]) || (auction.ttp == this.accounts[0])) &&
                      auction.timeRemaining <= 0) ? <button onClick={() => this.signAuction(auction.address)}>Sign Auction</button> : ""}

                      {auction.sigCount >= 2 ? <button onClick={() => this.endAuction(auction.address)}>End Auction</button>: ""}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    );
  }
}

export default App;
