# NFT Smart Contract Starter

## Requirements
- NodeJS & npm installed
- Create a .env in the root folder and add your private key and your block explorer api key

PRIVATE_KEY=YOUR_WALLET_PRIVATE_KEY

API_KEY=YOUR_EXPLORER_API_KEY

## Setup
- Run `npm install` for installing all dependencies

## Useful tips
- Don't forget to create an .env file with keys `PRIVATE_KEY` (your wallet private key) and `API_KEY` (your block explorer api key for verifying contracts)
- `truffle test` for testing smart contracts
- `npm run-script compile` for avoiding cache while compiling with truffle
- `npm run-script verify` for verifying your smart contract once they're deployed. Replace `CONTRACT_ADDRESS` and `NETWORK` by corresponding values

## More infos
This repo contains 2 contracts
- A basic ERC721 contract
- An ERC721 contract with mint reward features (each mint, x % are reflected to previous minters)
