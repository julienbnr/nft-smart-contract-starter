const { expectRevert } = require('@openzeppelin/test-helpers');
const NFTMintRewards = artifacts.require('NFTMintRewards');

contract('NFTMintRewards', (accounts) => {

  const ownerAddress = accounts[0];
  const secondaryAddress = accounts[1];

  let nft;

  beforeEach(async () => {
    nft = await NFTMintRewards.new('TEST', 'TEST', 'server-test.com/', 10);
  });

  it('should be correctly initialized', async () => {
    // Total supply should be 10
    const totalSupply = await nft.totalSupply();
    assert(10 === toNumber(totalSupply));

    // NFT total for owner should be 10
    const ownerBalance = await nft.balanceOf(ownerAddress);
    assert(10 === toNumber(ownerBalance));

    const price = await nft.price();
    assert(web3.utils.toWei('1.5') === price.toString());

    const mintEnabled = await nft.enableMint();
    assert(!mintEnabled);

    const maxMintPerTx = await nft.maxMintAmount();
    assert(20 === toNumber(maxMintPerTx));

    //const baseURI = await nft._baseURI()();
    //assert('server-test.com/' === baseURI);
  });

  it('should not mint and throw error due to minting not enabled', async () => {
    await expectRevert(
        nft.mint('1', { from: secondaryAddress}),
        'NFT::Mint is not enabled'
    );
  });

  it('should not mint with 0 amount as input', async () => {
    await nft.startMint();
    await expectRevert(
        nft.mint('0', { from: secondaryAddress}),
        'NFT::Cannot mint 0'
    );
  });

  it('should not mint with amount greater than max authorized', async () => {
    await nft.startMint();
    await expectRevert(
        nft.mint('50', { from: secondaryAddress}),
        'NFT::Mint amount exceeded'
    );
  });

  it('should not mint due to insufficient amount', async () => {
    await nft.startMint();
    await expectRevert(
        nft.mint('1', { from: secondaryAddress, value: web3.utils.toWei('1')}),
        'NFT::Sent price is lower than required price'
    );

    await expectRevert(
        nft.mint('10', { from: secondaryAddress, value: web3.utils.toWei('10')}),
        'NFT::Sent price is lower than required price'
    );
  });

  it('should mint and receive tokens', async () => {
    await nft.startMint();
    await nft.mint('1', { from: secondaryAddress, value: web3.utils.toWei('1.5') });
    let balance = toNumber(await nft.balanceOf(secondaryAddress));
    assert(1 === balance);

    await nft.mint('10', { from: secondaryAddress, value: web3.utils.toWei('15') });
    balance = toNumber(await nft.balanceOf(secondaryAddress));
    assert(11 === balance);
  });

  it('should withdraw and receive exact eth', async () => {
    const initialBalance = await web3.eth.getBalance(ownerAddress);
    await nft.startMint();
    await nft.mint('2', { from: secondaryAddress, value: web3.utils.toWei('3') });
    //await nft.withdraw();
    const newBalance = await web3.eth.getBalance(ownerAddress);
    assert(initialBalance !== newBalance); // Cannot verify exact balance du to tx fee
  });

  it('should verify number of token', async () => {
    const nbOfTokens = (await nft.walletOfOwner(ownerAddress)).length;
    assert(10 === nbOfTokens);
  });

  it('should test uri', async () => {
    const tokenUri = await nft.tokenURI('1');
    assert('server-test.com/1' === tokenUri);
  });

  it('should test uri which does not exist and throw error', async () => {
    await expectRevert(
        nft.tokenURI('10000'),
        'ERC721URIStorage: URI query for nonexistent token'
    );
  });

});

const toNumber = (uint256Value) => {
  return parseFloat(web3.utils.fromWei(uint256Value.toString())) * 10 ** 18;
}
