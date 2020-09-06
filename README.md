<p align="center">
  <img width="150" height="150" src="https://github.com/morality-network/design/blob/master/Network%20Logo%20(for%20light%20backgrounds%20only).gif">
</p>

# Contracts
Test & Deployable ERC20 & ERC721 Contracts (As Deployed on Rinkeby)

## Bug Bounty :bug:

If you can find bugs or can identify major security issues of contracts in the "Deployable" folder, you will be given the equivalence of $25 in Eth and 3000MO tokens (the tokens will be given when the token contract is released onto MainNet). 
You can email any suggestions/changes to: info@morality.network.

User and identified issues:
NONE

## Morality Contracts Index :bookmark_tabs:

**Description:** This is a contract that will point to all the latest versions of morality.networks working contracts. <br><br>
**Address:** 0xb8f44da02ae0553792f71dfacf9233fdc83a841c <br>
**Link to Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0xb8f44da02ae0553792f71dfacf9233fdc83a841c

## Morality Token Contract :moneybag:

**Description:** This contract is the morality.network utility token known as Morality (MO). MO is used both in the crowdsale and the main application as a token of utility representing work done in the network. <br><br>
**Address:** 0x4fD5b9B5dcc9a5D5931d007ba4aE573e760d9B64 <br>
<strong>Link to Etherscan:</strong> https://etherscan.io/token/0x4fD5b9B5dcc9a5D5931d007ba4aE573e760d9B64 <br>
**Constructor Arguments (decoded):** 1750000000000000000000000000,235294117647058800000,1 <br>
**Constructor Arguments (encoded):** 000000000000000000000000000000000000000005a790ea17ace06a9600000000000000000000000000000000000000000000000000000cc15ca15bbbe90d800000000000000000000000000000000000000000000000000000000000000001 <br>
**Link on Etherscan:** https://etherscan.io/token/0x4fD5b9B5dcc9a5D5931d007ba4aE573e760d9B64 <br>

Legacy (test network): <br>
**Constructor Arguments (decoded):** 1700000000000000000000000000 <br>
**Constructor Arguments (encoded):** 0000000000000000000000000000000000000000057e3500a948da0124000000 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x7dd454d6269b4ebd5807cb38284a7636d25e118f <br>
**Test Suite Results (Ropsten):** https://testsuite.net/report.html?token=0xd1B5cB3A6EA812C8c444E8D7D5692905Df097c0E <br>
**Link on Ropsten.Etherscan:** https://ropsten.etherscan.io/address/0xd1b5cb3a6ea812c8c444e8d7d5692905df097c0e <br>

## Morality Crowdsale Contract :family:

**Description:** This contract is the point of call during the morality.network crowdsale. Tokens are allocated to this contract which are available for the public to purchase. If wei is transferred to the contract, a mapped amount of mo (the utility token) is sent back willing that the contract holds enough to honor the payment. <br><br>
**Address:** 0x7dd454d6269b4ebd5807cb38284a7636d25e118f <br>
**Constructor Arguments (decoded):** 0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0,1,0xcE4C3fA41B696509fb77FBC3FDd2b74Cac37535B <br>
**Constructor Arguments (encoded):** 0000000000000000000000005c9d8ed10c263f1bb02404145e7ce49cec0d87f00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000ce4c3fa41b696509fb77fbc3fdd2b74cac37535b <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0,1,0xcE4C3fA41B696509fb77FBC3FDd2b74Cac37535B

## Morality Storage Contract :newspaper:

**Description:** This contract is where we store our data for the content persistence. More about this can be found in our (morality.network) whitepaper. It essentially allows data to be persisted on the blockchain so it cannot be removed. <br>
**Address:** 0x05B8593d229e79f0505879d0bAe990ad067C6df3 <br><br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x05B8593d229e79f0505879d0bAe990ad067C6df3

## Morality Assets Contract :running:

**Description:** This contract is for the in-game collectibles. It is the only form of advertising that we will allow on our network and it isn't really advertising at that. It is a collection of limited supply collections that can be produced by anyone through our network and sold on in the app store. The creator can add any name to the collection, name to the items and each of them have a description. Tokens can be purchased in sets and have a finite number ie. 1 of 7. Assets tokens can be purchased either through sending Ether (correct amount) to the buyToken function or by sending the Morality token to the approveTokenPurchase function via the Morality token contract (using the address of this contract as a parameter). The Assets token can also be purchased directly via the buyTokenWithMorality function in this contract but you will need to approve the purchase with the Morality token contract beforehand. <br><br>
**Address:** 0x89637DC6A167126D91bbc88Bf7d478fA2ceAD6B9 <br>
**Constructor Arguments (encoded):** 0x0CD2394671dc9917f83133D655ba349B588A3b04,"MoralityAssets","MOAS",0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0 <br>
**Constructor Arguments (decoded):** 0000000000000000000000000cd2394671dc9917f83133d655ba349b588a3b04000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000005c9d8ed10c263f1bb02404145e7ce49cec0d87f0000000000000000000000000000000000000000000000000000000000000000e4d6f72616c69747941737365747300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044d4f415300000000000000000000000000000000000000000000000000000000 <br>
**Link on Rinkby.Etherscan:** https://rinkeby.etherscan.io/address/0x89637DC6A167126D91bbc88Bf7d478fA2ceAD6B9

## Admin :gem:

**Address:** 0x5c9D8ed10c263F1bB02404145E7cE49CEC0D87F0 
