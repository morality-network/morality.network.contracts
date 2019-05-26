pragma solidity ^0.5.7;

// ------------------------------------------------------------------------
// Ownable contract definition
// This is to allow for admin specific functions
// ------------------------------------------------------------------------
contract Ownable {
    
  address payable public owner;
  address payable public potentialNewOwner;
  
  event OwnershipTransferred(address payable indexed _from, address payable indexed _to);

  // ------------------------------------------------------------------------
  // Upon creation we set the creator as the owner
  // ------------------------------------------------------------------------
  constructor() public {
    owner = msg.sender;
  }

  // ------------------------------------------------------------------------
  // Set up the modifier to only allow the owner to pass through the condition
  // ------------------------------------------------------------------------
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // ------------------------------------------------------------------------
  // Transfer ownership to another user
  // ------------------------------------------------------------------------
  function transferOwnership(address payable _newOwner) public onlyOwner {
    potentialNewOwner = _newOwner;
  }
  
  // ------------------------------------------------------------------------
  // To ensure correct transfer, the new owner has to confirm new ownership
  // ------------------------------------------------------------------------
  function acceptOwnership() public {
    require(msg.sender == potentialNewOwner);
    emit OwnershipTransferred(owner, potentialNewOwner);
    owner = potentialNewOwner;
  }

}

// ------------------------------------------------------------------------
// MoralityIndexer contract definition
// This is to allow for admin specific functions
// ------------------------------------------------------------------------
contract MoralityIndexer is Ownable{

    address private currentMoralityTokenAddress = address(0);
    address private currentMoralityCrowdsaleAddress = address(0);
    address private currentMoralityStorageAddress = address(0);
    address private currentMoralityAssetsAddress = address(0);
    
    enum AddressType { Token, Crowdsale, Storage, Players }
    
    event UpdatedAddress(AddressType typeOfAddress, address oldAddress, address newAddress, uint256 timestamp);
    
    // ------------------------------------------------------------------------
    // Get the token address
    // ------------------------------------------------------------------------
    function getMoralityTokenAddress() external view returns(address){
        require(currentMoralityTokenAddress != address(0));
        return currentMoralityTokenAddress;
    }
    
    // ------------------------------------------------------------------------
    // Get the crowdsale address
    // ------------------------------------------------------------------------
    function getMoralityCrowdsaleAddress() external view returns(address){
        require(currentMoralityCrowdsaleAddress != address(0));
        return currentMoralityCrowdsaleAddress;
    }
    
    // ------------------------------------------------------------------------
    // Get the storage address
    // ------------------------------------------------------------------------
    function getMoralityStorageAddress() external view returns(address){
        require(currentMoralityStorageAddress != address(0));
        return currentMoralityStorageAddress;
    }
    
    // ------------------------------------------------------------------------
    // Get the players address
    // ------------------------------------------------------------------------
    function getMoralityAssetsAddress() external view returns(address){
        require(currentMoralityAssetsAddress != address(0));
        return currentMoralityAssetsAddress;
    }
    
    // ------------------------------------------------------------------------
    // Update the token address
    // ------------------------------------------------------------------------
    function updateMoralityTokenAddress(address _tokenAddress) external onlyOwner{
        address oldAddress = currentMoralityTokenAddress;
        currentMoralityTokenAddress = _tokenAddress;
        emit UpdatedAddress(AddressType.Token, oldAddress, _tokenAddress, now);
    }
    
    // ------------------------------------------------------------------------
    // Update the crowdsale address
    // ------------------------------------------------------------------------
    function updateMoralityCrowdsaleAddress(address _crowdAddress) external onlyOwner{
        address oldAddress = currentMoralityCrowdsaleAddress;
        currentMoralityCrowdsaleAddress = _crowdAddress;
        emit UpdatedAddress(AddressType.Crowdsale, oldAddress, _crowdAddress, now);
    }
    
    // ------------------------------------------------------------------------
    // Update the storage address
    // ------------------------------------------------------------------------
    function updateMoralityStorageAddress(address _storageAddress) external onlyOwner{
        address oldAddress = currentMoralityStorageAddress;
        currentMoralityStorageAddress = _storageAddress;
        emit UpdatedAddress(AddressType.Storage, oldAddress, _storageAddress, now);
    }
    
    // ------------------------------------------------------------------------
    // Update the players address
    // ------------------------------------------------------------------------
    function updateMoralityAssetsAddress(address _playersAddress) external onlyOwner{
        address oldAddress = currentMoralityAssetsAddress;
        currentMoralityAssetsAddress = _playersAddress;
        emit UpdatedAddress(AddressType.Players, oldAddress, _playersAddress, now);
    }
    
    // ------------------------------------------------------------------------
    // To remove indexer contract from blockchain
    // ------------------------------------------------------------------------
    function deprecateContract() onlyOwner public{
        selfdestruct(owner);
    }  
}