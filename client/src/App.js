import React, { Component } from "react";
import AuctionContract from "./contracts/SimpleAuction.json";
import AuctionMakerContract from "./contracts/AuctionMaker.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { web3: null, accounts: null, auctionMakerInstance: null, auctionData: [] };

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
  newAuction = async (biddingTime, ttp) => {

    const instance = this.state.auctionMakerInstance;
    const accounts = this.state.accounts;

    await instance.methods.createAuction(biddingTime, ttp).send({ from: accounts[0] });
    await this.getAuctions();

  }

  getAuctions = async () => {

    const instance = this.state.auctionMakerInstance;
    const web3 = this.state.web3;
    let data = []
    let addresses = [];

    addresses = await instance.methods.getAuction().call();
    //console.log(addresses);

    for (const address of addresses) {
      try {
        const auction = new web3.eth.Contract(
          AuctionContract.abi,
          String(address)
        );

        const beneficiary = await auction.methods.beneficiary().call();
        const ttp = await auction.methods.ttp().call();

        data.push({ address, beneficiary, ttp });
      } catch (error) {
      }
    }

    this.setState({ auctionData: data });

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
        
        <div className="form-create-auction">
          <h2>Create Auction</h2>
          <div>
            Bidding Time <input type="text" ref={x => this.biddingTime = x} defaultValue={60} />
          </div>
          <div>
            TTP Address <input type="text" ref={x => this.ttp = x} defaultValue={'0x0000000000000000000000000000000000000000'} />
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
              </tr>
            </thead>
            <tbody>
              {auctions.map(auction => {
                return (
                  <tr key={auction.address}>
                    <td>{auction.address.substr(0, 10)}</td>
                    <td>{auction.beneficiary.substr(0, 10)}</td>
                    <td>{auction.ttp}</td>
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
