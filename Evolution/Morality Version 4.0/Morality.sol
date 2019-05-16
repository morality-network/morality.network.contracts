pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

// ------------------------------------------------------------------------
// Math library
// ------------------------------------------------------------------------
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

// ------------------------------------------------------------------------
// Basic token interface
// ------------------------------------------------------------------------
contract IERC20 {
    
  uint256 public totalSupply;
  address public burnAddress = 0x0000000000000000000000000000000000000000;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Minted(address target, uint256 mintedAmount);
  event Burned(address burner, uint256 burnedAmount);
  
}

// ------------------------------------------------------------------------
// Implementation of basic token interface
// ------------------------------------------------------------------------
contract ERC20 is IERC20 {
    
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  // ------------------------------------------------------------------------
  // Get balance of user
  // ------------------------------------------------------------------------
  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
  
  // ------------------------------------------------------------------------
  // Transfer tokens
  // ------------------------------------------------------------------------
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  // ------------------------------------------------------------------------
  // Create tokens by adding to total supply and crediting the admin/owner
  // ------------------------------------------------------------------------
  function mintToken(address _target, uint256 _mintedAmount) public returns(bool){
	balances[_target] = balances[_target].add(_mintedAmount);
	totalSupply = totalSupply.add(_mintedAmount);
	emit Minted(_target, _mintedAmount);
	emit Transfer(address(0), address(this), _mintedAmount);
	emit Transfer(address(this), _target, _mintedAmount);
	return true;
  }
  
  // ------------------------------------------------------------------------
  // Burn token by sending to to burn address & removing it from total supply
  // ------------------------------------------------------------------------
  function burn(uint256 _burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_burnAmount);
    totalSupply = totalSupply.sub(_burnAmount);
    emit Burned(burner, _burnAmount);
    emit Transfer(burner, burnAddress, _burnAmount);
  }

}

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
// Content moderatable contract definition
// This is to allow for moderator specific functions
// ------------------------------------------------------------------------
contract Moderatable is Ownable{
    
  mapping(address => bool) public moderators;
  
  event ModeratorAdded(address indexed _moderator);
  event ModeratorRemoved(address indexed _moderator);
  
  // ------------------------------------------------------------------------
  // Upon creation we set the first moderator as the owner
  // ------------------------------------------------------------------------
  constructor() public {
    addModerator(owner);
  }
  
  // ------------------------------------------------------------------------
  // Set up the modifier to only allow moderators to pass through the condition
  // ------------------------------------------------------------------------
  modifier onlyModerators() {
    require(moderators[msg.sender] == true);
    _;
  }
  
  // ------------------------------------------------------------------------
  // Add a moderator
  // ------------------------------------------------------------------------
  function addModerator(address _newModerator) public onlyOwner {
    moderators[_newModerator] = true;
    emit ModeratorAdded(_newModerator);
  }
  
  // ------------------------------------------------------------------------
  // Remove a moderator
  // ------------------------------------------------------------------------
  function removeModerator(address _moderator) public onlyOwner {
     moderators[_moderator] = false;
     emit ModeratorRemoved(_moderator);
  }
  
}

// ------------------------------------------------------------------------
// Storage token definition
// ------------------------------------------------------------------------
contract StorageToken is Moderatable{
    
    struct Content{
        address contentCreator;
        uint256 articleId;
        uint256 subArticleId;
        uint256 contentId; 
        uint256 timestamp; 
        string data;
    }
    
    Content[] private allContents;
    
    event ContentAdded(address contentCreator, uint256 indexed articleId, uint256 indexed subArticleId, uint256 indexed contentId, uint256 timestamp);
    event ContentAddedViaEvent(address contentCreator, uint256 indexed articleId, uint256 indexed subArticleId, uint256 indexed contentId, uint256 timestamp, string data);
    
    // ------------------------------------------------------------------------
    // Add content to event for content persistance.
    // By storing the content in an event (compared to the experiment contract)
    // we get very cheap storage
    // ------------------------------------------------------------------------
    function addContentViaEvent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
       emit ContentAddedViaEvent(contentCreator, articleId, subArticleId, contentId, timestamp, data);
    }
    
    // ------------------------------------------------------------------------
    // Add content to struct for content persistance
    // ------------------------------------------------------------------------
    function addContent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
       require(!contentExists(contentId));
       allContents.push(Content(contentCreator, articleId, subArticleId, contentId, timestamp, data));
       emit ContentAdded(contentCreator, articleId, subArticleId, contentId, timestamp);
    }
    
    // ------------------------------------------------------------------------
    // Does contentId already exist
    // ------------------------------------------------------------------------
    function contentExists(uint256 contentId) internal view returns(bool exists) {
        exists = false;
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.contentId == contentId){
                exists = true;
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Get Content by contentId
    // ------------------------------------------------------------------------
    function getContentById(uint256 contentId) public view returns(Content memory contents) {
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.contentId == contentId){
                contents = c;
                i = allContents.length;
            }
        }
    }
      
    // ------------------------------------------------------------------------
    // Get all content ids
    // ------------------------------------------------------------------------
    function getAllContentIds() public view returns(uint256[] memory contentIds) {
        contentIds = new uint256[](allContents.length);
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            contentIds[i] = c.contentId;
        }
    }
    
    // ------------------------------------------------------------------------
    // Get all content ids for article
    // ------------------------------------------------------------------------
    function getAllContentForArticle(uint256 articleId) public view returns(Content[] memory content) {
        content = new Content[](countContentForArticle(articleId));
        uint counter = 0;
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.articleId == articleId){
                content[counter] = c; 
                counter++;
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Count content for article
    // ------------------------------------------------------------------------
    function countContentForArticle(uint256 articleId) public view returns(uint256 count) {
        count = 0;
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.articleId == articleId){
                count++;
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Get all content ids for sub-article
    // ------------------------------------------------------------------------
    function getAllContentForSubArticle(uint256 subArticleId) public view returns(Content[] memory content) {
        content = new Content[](countContentForSubArticle(subArticleId));
        uint counter = 0;
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.subArticleId == subArticleId){
                content[counter] = c; 
                counter++;
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Count content for sub-article
    // ------------------------------------------------------------------------
    function countContentForSubArticle(uint256 subArticleId) public view returns(uint256 count) {
        count = 0;
        for(uint i=0;i<allContents.length;i++) {
            Content memory c = allContents[i];
            if(c.subArticleId == subArticleId){
                count++;
            }
        }
    }
    
}

// ------------------------------------------------------------------------
// Morality token definition
// ------------------------------------------------------------------------
contract Morality is ERC20, StorageToken {
  
  string public name;
  string public symbol;
  uint256 public decimals;
  address payable public creator;
  
  event LogFundsReceived(address sender, uint amount);
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter);
  event UpdatedTokenInformation(string newName, string newSymbol);

  // ------------------------------------------------------------------------
  // Constructor to allow total tokens minted (upon creation) to be set
  // Name and Symbol can be changed via SetInfo (decided to remove from constructor)
  // ------------------------------------------------------------------------
  constructor(uint256 _totalTokensToMint) payable public {
    name = "Morality";
    symbol = "MO";
    totalSupply = _totalTokensToMint;
    decimals = 18;
    balances[msg.sender] = totalSupply;
    creator = msg.sender;
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  // ------------------------------------------------------------------------
  // Payable method allowing ether to be stored in the contract
  // ------------------------------------------------------------------------
  function() payable external {
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  // ------------------------------------------------------------------------
  // Transfer token (availabe to all)
  // ------------------------------------------------------------------------
  function transfer(address _to, uint256 _value) public returns (bool success){
    return super.transfer(_to, _value);
  }
  
  // ------------------------------------------------------------------------
  // Add content via event to event for content persistance (cheap)
  // ------------------------------------------------------------------------
  function addContentViaEvent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
      super.addContentViaEvent(contentCreator, articleId, subArticleId, contentId, timestamp, data);
  }
  
  // ------------------------------------------------------------------------
  // Add content for content persistance (expensive)
  // ------------------------------------------------------------------------
  function addContent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
      super.addContent(contentCreator, articleId, subArticleId, contentId, timestamp, data);
  }
  
  // ------------------------------------------------------------------------
  // Update token information
  // ------------------------------------------------------------------------
  function setTokenInformation(string memory _name, string memory _symbol) onlyOwner public {
    require(msg.sender != creator);
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }
  
  // ------------------------------------------------------------------------
  // Withdraw ether from the contract
  // ------------------------------------------------------------------------
  function withdraw(uint256 amount) onlyOwner public returns(bool){
	require(amount <= address(this).balance);
    address(owner).transfer(amount);
	emit WithdrawLog(address(owner).balance.sub(amount), amount, address(owner).balance);
    return true;
  }
  
  // ------------------------------------------------------------------------
  // Mint token
  // ------------------------------------------------------------------------
  function mintToken(address target, uint256 mintedAmount) onlyOwner public returns (bool){
	return super.mintToken(target, mintedAmount);
  }
  
  // ------------------------------------------------------------------------
  // Burn token (send to burn address)
  // ------------------------------------------------------------------------
  function burn(uint256 burnAmount) onlyOwner public{
    return super.burn(burnAmount);
  }

  // ------------------------------------------------------------------------
  // To remove contract from blockchain
  // ------------------------------------------------------------------------
  function deprecateContract() onlyOwner public{
    selfdestruct(creator);
  }
  
}