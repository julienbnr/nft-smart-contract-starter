const NFTMintRewards = artifacts.require('NFTMintRewards.sol');

module.exports = async function (deployer, network) {
  const BASE_URL = 'https://storageapi.fleek.co/1973d79e-96f0-4cae-b56b-5b4c96b6284c-bucket/Avapepe/metadata/';
  await deployer.deploy(NFTMintRewards, 'Test', 'TEST', BASE_URL);
};
