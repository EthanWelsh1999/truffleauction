import React, { Component } from "react";
import AuctionContract from "./contracts/SimpleAuction.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { web3: null, accounts: null, auctions: null, currentAccount: null };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Set web3 and accounts to the state, and call example
      this.setState({ web3, accounts, currentAccount: accounts[0] }, this.createAuction(120, accounts[1]));
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  // Function to start a new auction
  createAuction = async(biddingTime, ttp) => {

    // Create new contract instance.
    const networkId = await web3.eth.net.getId();
    const deployedNetwork = AuctionContract.networks[networkId];
    const instance = new web3.eth.Contract(
      AuctionContract.abi,
      deployedNetwork && deployedNetwork.address, {from: currentAccount, data: biddingTime, ttp}
    );

    // Create a copy of the state add the new auction.
    const stateCopy = [...this.state.auctions];
    stateCopy.push(instance);

    // Modify the state
    this.setState({auctions: stateCopy});
  }

  getAuctions = async() => {
    const auctions = this.state.auctions;
    let data = [];

    for (const auction in auctions) {
      const address  = await auction.options.address;
      const beneficiary  = await auction.methods.beneficiary().call();
      const ttp = await auction.methods.ttp.call();
      data.push({address, beneficiary});
    }

    return data;
  }

  /*
  runExample = async () => {
    const { accounts, contract } = this.state;

    // Stores a given value, 5 by default.
    await contract.methods.set(5).send({ from: accounts[0] });

    // Get the value from the contract to prove it worked.
    const response = await contract.methods.get().call();

    // Update state with the result.
    this.setState({ storageValue: response });
  }; */

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contracts...</div>;
    }
    return (
      <div className="App">
        <h1>Good to Go!</h1>
        <p>Your Truffle Box is installed and ready.</p>
        <h2>Smart Contract Example</h2>
        <p>
          If your contracts compiled and migrated successfully, below will show
          a stored value of 5 (by default).
        </p>
        <p>
          Try changing the value stored on <strong>line 42</strong> of App.js.
        </p>
        
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
              {this.getAuctions().map(auction => {
                return (
                  <tr key={auction.address}>
                    <td>{auction.address}</td>
                    <td>{auction.beneficiary}</td>
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
