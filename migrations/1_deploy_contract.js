const NFT = artifacts.require('NFT.sol');

module.exports = async function (deployer) {

  const BASE_URL = 'http://nft-test-01.s3-website.eu-west-3.amazonaws.com/';
  await deployer.deploy(NFT, 'TEST', 'TEST', BASE_URL);

};
