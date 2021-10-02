//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMintRewards is Context, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdTracker;

    using SafeMath for uint256;

    // Constants
    uint constant public MAX_SUPPLY = 1200;
    uint public MINT_REWARD = 10; // 10% redistributed to previous minters
    uint256 public constant maxMintAmount = 20;
    uint256 public constant price = 0.01 ether;

    // Will enable minting
    uint256 public reflectionBalance;
    uint256 public totalDividend;
    bool public enableMint = false;

    string private _baseTokenURI;

    mapping(uint256 => uint256) public lastDividendAt;
    mapping(uint256 => address ) public minter;

    IERC721Enumerable public oldContract = IERC721Enumerable(0xc216Ea9A7be59313Cb93D8Fc266cacD368355775);

    event MintEvent(address indexed holder, uint256 tokenId);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        for(uint i = 0; i < 20; i++) {
            _mint(msg.sender, _tokenIdTracker.current());
            minter[_tokenIdTracker.current()] = msg.sender;
            lastDividendAt[_tokenIdTracker.current()] = 0;
            _tokenIdTracker.increment();
        }

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(uint amount) public payable {
        require(enableMint, 'NFT::Mint is not enabled');
        require(amount > 0, 'NFT::Cannot mint 0');
        require(amount <= maxMintAmount, 'NFT::Mint amount exceeded');
        require(msg.value >= price.mul(amount), "NFT::Sent price is lower than required price");
        require(_tokenIdTracker.current().add(amount) <= MAX_SUPPLY, "NFT::Not enough NFT left to mint amount");
        for(uint i = 0; i < amount; i++) {
            _mint(msg.sender, _tokenIdTracker.current());
            minter[_tokenIdTracker.current()] = msg.sender;
            lastDividendAt[_tokenIdTracker.current()] = totalDividend;
            _tokenIdTracker.increment();
            handleMintReward(msg.value/amount);
        }
    }

    function tokenMinter(uint256 tokenId) public view returns(address) {
        return minter[tokenId];
    }

    function currentRate() public view returns (uint256){
        if (totalSupply() == 0) return 0;
        return reflectionBalance / totalSupply();
    }

    function claimRewards() public {
        uint count = balanceOf(msg.sender);
        uint256 balance = 0;
        for(uint i = 0; i < count; i++){
            uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
            balance = balance.add(getReflectionBalance(tokenId));
            lastDividendAt[tokenId] = totalDividend;
        }
        payable(msg.sender).transfer(balance);
    }

    function getReflectionBalances(address forAddress) public view returns (uint256) {
        uint count = balanceOf(forAddress);
        uint256 total = 0;
        for(uint i = 0; i < count; i++){
            uint tokenId = tokenOfOwnerByIndex(forAddress, i);
            total = total.add(getReflectionBalance(tokenId));
        }
        return total;
    }

    function claimReward(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender(), "NFT: Only owner or approved can claim rewards");
        uint256 balance = getReflectionBalance(tokenId);
        payable(ownerOf(tokenId)).transfer(balance);
        lastDividendAt[tokenId] = totalDividend;
    }

    function getReflectionBalance(uint256 tokenId) public view returns (uint256) {
        return totalDividend.sub(lastDividendAt[tokenId]);
    }

    function handleMintReward(uint256 amount) private {
        uint256 mintShare = amount.div(MINT_REWARD);
        uint256 devShare = amount.sub(mintShare);
        reflectDividend(mintShare);
        payable(owner()).transfer(devShare);
    }

    function reflectDividend(uint256 amount) private {
        reflectionBalance = reflectionBalance.add(amount);
        totalDividend = totalDividend.add((amount.div(totalSupply())));
    }

    function reflectToOwners() public payable {
        reflectDividend(msg.value);
    }

    // Start the mint process
    function startMint() external onlyOwner {
        enableMint = true;
    }

    // Get owner token ids
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i = i.add(1)) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
}
