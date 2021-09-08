// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // Minting one token will cost 1.5 eth
    uint256 public constant price = 1.5 ether;

    // Maximum of mint will be 10000
    uint256 constant MAX_SUPPLY = 1000;

    // Will enable minting
    bool public enableMint = false;

    // Number of mint max per tx
    uint256 public maxMintAmount = 20;

    // The base URI
    string public baseURI;

    // The base extension
    string public baseExtension = ".json";

    constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {

        setBaseURI(_initBaseURI);

        // Mint 10 NFTs for the dev (used for marketing)
        for (uint256 i = 1; i <= 10; i = i.add(1)) {
            _safeMint(msg.sender, i);
        }
    }

    // Mint x NFT, up to maxMintAmount
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(enableMint, 'NFT::Mint is not enabled');
        require(_mintAmount > 0, 'NFT::Cannot mint 0');
        require(_mintAmount <= maxMintAmount, 'NFT::Mint amount exceeded');
        require(supply.add(_mintAmount) <= MAX_SUPPLY, 'NFT::Mint amount should exceed total');
        require(msg.value >= price * _mintAmount, 'NFT::ETH value sent too low');

        for (uint256 i = 1; i <= _mintAmount; i = i.add(1)) {
            _safeMint(_to, supply.add(i));
        }
    }

    // Withdraw the ETH balance of the contract
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // Set base uri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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

    // Set base extension
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Get token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // Start the mint process
    function startMint() external onlyOwner {
        enableMint = true;
    }

    // Fallback function for receiver eth
    receive() external payable {}
}
