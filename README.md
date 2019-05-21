<p align="center">
  <img width="180" height="160" src="https://i.postimg.cc/J0mKhXCD/mo.png">
</p>

# Contracts
Test & Deployable ERC20 & ERC721 Contracts (As Deployed on Rinkeby)

## Bug Bounty :bug:

If you can find bugs or can identify major security issues of contracts in the "Deployable" folder, you will be given the equivalence of $25 in Eth and 3000MO tokens (the tokens will be given when the token contract is released onto MainNet). 
You can email any suggestions/changes to: info@morality.network.

User and identified issues:
NONE

## Morality Contracts Index :bookmark_tabs:

**Description:** This is a contract that will point to all the latest versions of morality.networks working contracts. <br>
**Address:** 0x39c5b1728779ab4385f99e9338f8f5b55bfe90a6 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x39c5b1728779ab4385f99e9338f8f5b55bfe90a6

## Morality Token Contract :moneybag:

**Description:** This contract is the morality.network utility token. It will be used both in the crowdsale and the main application as a token of utility representing work done in our network. <br>
**Address:** 0x0CD2394671dc9917f83133D655ba349B588A3b04 <br>
**Constructor Arguments (decoded):** 1000000000000000000000000000 <br>
**Constructor Arguments (encoded):** 0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x0CD2394671dc9917f83133D655ba349B588A3b04

## Morality Crowdsale Contract :family:

**Description:** This contract is the point of call during the morality.network crowdsale. Tokens are allocated to this contract which are available for the public to purchase. If wei is transferred to the contract, a mapped amount of mo (the utility token) is sent back willing that the contract holds enough to honor the payment. <br>
**Address:** 0x96572594Ac71080c0D3839AB4DF38cCA1a7fa8B0 <br>
**Constructor Arguments (decoded):** 2381,"0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0","0x0CD2394671dc9917f83133D655ba349B588A3b04" <br>
**Constructor Arguments (encoded):** 000000000000000000000000000000000000000000000000000000000000094d0000000000000000000000005c9d8ed10c263f1bb02404145e7ce49cec0d87f00000000000000000000000000cd2394671dc9917f83133d655ba349b588a3b04 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x96572594Ac71080c0D3839AB4DF38cCA1a7fa8B0

## Morality Storage Contract :newspaper:

**Description:** This contract is where we store our data for the content persistence. More about this can be found in our (morality.network) whitepaper. It essentially allows data to be persisted on the blockchain so it cannot be removed. <br>
**Address:** 0x05B8593d229e79f0505879d0bAe990ad067C6df3 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x05B8593d229e79f0505879d0bAe990ad067C6df3

## Morality Players Contract :running:

**Description:** This contract is for the in-game collectibles. It is the only form of advertising that we will allow on our network and it isn't really advertising at that. It is a collection of limited supply collections that can be produced by anyone through our network and sold on in the app store. The creator can add any name to the collection, name to the items and each of them have a description. Tokens can be purchased in sets and have a finite number ie. 1 of 7. <br>
**Address:** 0x56a7ACaFf4472d541cF56BE6148E1C23dD98cD07 <br>
**Constructor Arguments (encoded):** 0000000000000000000000000cd2394671dc9917f83133d655ba349b588a3b04000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000005c9d8ed10c263f1bb02404145e7ce49cec0d87f0000000000000000000000000000000000000000000000000000000000000000f4d6f72616c697479506c6179657273000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034d4f500000000000000000000000000000000000000000000000000000000000 <br>
**Constructor Arguments (decoded):** 0x0CD2394671dc9917f83133D655ba349B588A3b04,"MoralityPlayers","MOP",0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x56a7ACaFf4472d541cF56BE6148E1C23dD98cD07

## Admin

**Address:** 0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0 
