var SimpleAuction = artifacts.require("SimpleAuction.sol");
var AuctionMaker = artifacts.require("AuctionMaker.sol");

module.exports = function (deployer) {
  deployer.deploy(AuctionMaker);
};