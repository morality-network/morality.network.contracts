pragma solidity ^0.5.7;

// ------------------------------------------------------------------------
// Math library
// ------------------------------------------------------------------------
library SafeMath
{
  function mul(uint256 _factor1, uint256 _factor2) internal pure returns (uint256 product)
  {
    if (_factor1 == 0) { return 0; }
    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2);
  }

  function div(uint256 _dividend, uint256 _divisor) internal pure returns (uint256 quotient)
  {
    require(_divisor > 0);
    quotient = _dividend / _divisor;
    assert(_dividend == _divisor * quotient + _dividend % _divisor); 
  }

  function sub(uint256 _minuend, uint256 _subtrahend) internal pure returns (uint256 difference)
  {
    require(_subtrahend <= _minuend);
    difference = _minuend - _subtrahend;
  }
  
  function add(uint256 _addend1, uint256 _addend2) internal pure returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1);
  }

  function mod(uint256 _dividend, uint256 _divisor) internal pure returns (uint256 remainder) 
  {
    require(_divisor != 0);
    remainder = _dividend % _divisor;
  }
}

// ------------------------------------------------------------------------
// Address library - shows if the address is a contract
// ------------------------------------------------------------------------
library AddressUtils
{
  function isContract(address _addr) internal view returns (bool addressCheck)
  {
    uint256 size;
    assembly { size := extcodesize(_addr) } // solhint-disable-line
    addressCheck = size > 0;
  }
}

// ------------------------------------------------------------------------
// ERC165 Interface
// ------------------------------------------------------------------------
interface ERC165
{
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// ------------------------------------------------------------------------
// ERC721TokenReceiver Interface
// ------------------------------------------------------------------------
interface ERC721TokenReceiver
{
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// ------------------------------------------------------------------------
// ERC721 Interface
// ------------------------------------------------------------------------
interface ERC721
{
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFromWithData(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function approve(address _approved, uint256 _tokenId) external;
  function setApprovalForAll(address _operator, bool _approved) external;
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// ------------------------------------------------------------------------
// Implementation of ERC165
// ------------------------------------------------------------------------
contract SupportsInterface is ERC165
{
  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor() public 
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }
}

// ------------------------------------------------------------------------
// Ownable contract definition
// This is to allow for admin specific functions
// ------------------------------------------------------------------------
contract Ownable {
    
  address payable public owner;
  address payable internal potentialNewOwner;
  
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
// Breaker
// ------------------------------------------------------------------------
contract Breaker is Ownable {
    bool public inLockdown;

    constructor () internal {
        inLockdown = false;
    }

    modifier outOfLockdown() {
        require(inLockdown == false);
        _;
    }
    
    function updateLockdownState(bool state) external onlyOwner{
        inLockdown = state;
    }
}

// ------------------------------------------------------------------------
// Base contract for the ERC721
// ------------------------------------------------------------------------
contract NFToken is ERC721,
  SupportsInterface,
  Breaker
{
  using SafeMath for uint256;
  using AddressUtils for address;

  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApproval;
  mapping (address => uint256) private ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  modifier canOperate(uint256 _tokenId) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

  modifier canTransfer(uint256 _tokenId) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

  modifier validNFToken(uint256 _tokenId)
  {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  constructor() public
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  function safeTransferFromWithData(address _from, address _to, uint256 _tokenId, bytes calldata _data) external outOfLockdown
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external outOfLockdown
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) outOfLockdown
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) outOfLockdown
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external outOfLockdown
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(address _owner) public view returns (uint256)
  {
    require(_owner != address(0));
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address)
  {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(address _to, uint256 _tokenId) internal  outOfLockdown
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }
 
  function _mint(address _to, uint256 _tokenId) internal 
  {
    require(_to != address(0));
    require(idToOwner[_tokenId] == address(0));

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) internal validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  function _removeNFToken(address _from, uint256 _tokenId) internal
  {
    require(idToOwner[_tokenId] == _from);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(address _to, uint256 _tokenId) internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

  function _getOwnerNFTCount(address _owner) internal view returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) 
    private canTransfer(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) 
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

  function _clearApproval(uint256 _tokenId) private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }
}

// ------------------------------------------------------------------------
// Token meta data (name, symbol and total in existance (owned)
// ------------------------------------------------------------------------
contract TokenMetaData{
    
  string public name;
  string public symbol;
  
  // ------------------------------------------------------------------------
  // Set name and token upon creation
  // ------------------------------------------------------------------------
  constructor(string memory _tokenName, string memory _tokenSymbol) public {
     name = _tokenName;
     symbol = _tokenSymbol;
  }    
 
}

// ------------------------------------------------------------------------
// To stop reentrant attacks
// ------------------------------------------------------------------------
contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// ------------------------------------------------------------------------
// Player contract
// ------------------------------------------------------------------------
contract MoralityPlayers is NFToken, TokenMetaData, ReentrancyGuard{
    
	// ------------------------------------------------------------------------
    // Player
    // ------------------------------------------------------------------------
    struct MoralityPlayer{
        uint256 id;
        string name; 
        string description; 
        string collectionName;
        uint itemNumber;
        uint totalInExistance; 
        uint256 tokenPrice;
    }
    
    // ------------------------------------------------------------------------
    // Require responses
    // ------------------------------------------------------------------------
    string constant NO_TOKENS = "No tokens left in this collection";
    string constant COLLECT_EXISTS = "Collection name already exists";
    string constant COLLECT_DOESNT_EXIST = "Collection doesn't exist";
    string constant DOESNT_OWN = "The contract does not own the token";
    string constant PRICE_TOO_LOW = "Token price is higher than provided";
    
    // ------------------------------------------------------------------------
    // All tokens owned by users
    // ------------------------------------------------------------------------
    MoralityPlayer[] public allPlayers; 
    
    // ------------------------------------------------------------------------
    // Mappings for quick searches (by collectionName)
    // These also serve as the holders for unminted tokens
    // The tokens are created when purchased and collectionRunningCount -
    // - incremented. The collectionTotal mapping is the limit
    // ------------------------------------------------------------------------
    mapping(string => bool) public collectionNamesUsed;
    mapping(string => uint256) public collectionRunningCount;
    mapping(string => uint256) public collectionTotal;
    mapping(string => uint256) public collectionPricePerUnit;
    mapping(string => string) public collectionItemName;
    mapping(string => string) public collectionItemDescription;
    mapping(string => uint256) public collectionTotalRaised;

    // ------------------------------------------------------------------------
    // All collection names
    // ------------------------------------------------------------------------
    string[] public allCollectionNames;
    
    // ------------------------------------------------------------------------
    // Wallet to recieve funds when a token is purchased
    // ------------------------------------------------------------------------
    address payable public moralityWallet;
    
    // ------------------------------------------------------------------------
    // Total tokens & wei used to purchase them
    // ------------------------------------------------------------------------
    uint256 public totalTokens = 0;
    uint256 public totalWeiUsed = 0;
    
    event UpdatedWallet(address indexed updatedBy, address indexed oldWallet, address indexed newWallet);
    event CollectionCreated(address indexed collectionOwner, string indexed name, string indexed collectionName, uint256 totalToMint, uint256 pricePerUnit);
    event UpdateTokenPrice(string indexed collectionName, uint256 oldPrice, uint256 newTokenPrice);
    
    // ------------------------------------------------------------------------
    // On creation the wallet, token name and symbol are set
    // ------------------------------------------------------------------------
    constructor(address payable _moralityWallet, string memory _tokenName, string memory _tokenSymbol) 
        TokenMetaData(_tokenName,  _tokenSymbol) public {
        moralityWallet = _moralityWallet;
    }
    
    // ------------------------------------------------------------------------
    // If a collection of tokens needs to be created then 
    // ------------------------------------------------------------------------
    function createCollection(string calldata _name, string calldata _description, string calldata _collectionName, address _collectionOwner, uint256 _totalToMint, uint256 _tokenPrice) onlyOwner outOfLockdown external{
        require(collectionNamesUsed[_collectionName] == false, COLLECT_EXISTS);
        collectionNamesUsed[_collectionName] = true;
        collectionRunningCount[_collectionName] = 0;
        collectionTotal[_collectionName] = _totalToMint;
        collectionPricePerUnit[_collectionName] = _tokenPrice;
        collectionItemName[_collectionName] = _name;
        collectionItemDescription[_collectionName] = _description;
        collectionTotalRaised[_collectionName] = 0;
        allCollectionNames.push(_collectionName);
        emit CollectionCreated(_collectionOwner, _name, _collectionName, _totalToMint, _tokenPrice);
    }
   
    // ------------------------------------------------------------------------
    // Buy tokens. The tokens in a created collection are minted here.
    // The token is added to the allPlayers array when minted 
    // ------------------------------------------------------------------------
    function buyToken(string calldata _collectionName) payable external outOfLockdown nonReentrant{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        require(collectionRunningCount[_collectionName] < collectionTotal[_collectionName], NO_TOKENS);
        require(collectionPricePerUnit[_collectionName] >= msg.value, PRICE_TOO_LOW);
        uint256 id = allPlayers.length;
        uint256 nextItemNumber = collectionRunningCount[_collectionName].add(1);
        allPlayers.push(MoralityPlayer(id, collectionItemName[_collectionName], collectionItemDescription[_collectionName], 
            _collectionName, nextItemNumber, collectionTotal[_collectionName], collectionPricePerUnit[_collectionName]));
        collectionRunningCount[_collectionName] = nextItemNumber;
        _mint(msg.sender,id); 
        collectionTotalRaised[_collectionName] = collectionTotalRaised[_collectionName].add(msg.value);
        totalTokens = totalTokens.add(1);
        totalWeiUsed = totalWeiUsed.add(msg.value);
        _forwardFunds();
    }
    
    // ------------------------------------------------------------------------
    // Get token by id
    // ------------------------------------------------------------------------
    function getTokenById(uint256 id) external view returns(uint256, string memory, string memory, string memory, uint256, uint256, uint256){
        MoralityPlayer memory player = allPlayers[id];
        return(player.id, player.name, player.description, player.collectionName, player.itemNumber, player.totalInExistance, player.tokenPrice);
    }

    // ------------------------------------------------------------------------
    // Returns how many tokens are left in a collection for purchase
    // ------------------------------------------------------------------------
    function tokensLeft(string calldata _collectionName) external view returns(uint256){
        if(collectionNamesUsed[_collectionName] == false){ return 0; }
        return collectionTotal[_collectionName].sub(collectionRunningCount[_collectionName]);
    }
    
    // ------------------------------------------------------------------------
    // Owner can update the price of any outstanding tokens 
    // ------------------------------------------------------------------------
    function updateCollectionItemPrice(string calldata _collectionName, uint256 newTokenPrice) onlyOwner external{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        uint256 oldPrice = collectionPricePerUnit[_collectionName];
        collectionPricePerUnit[_collectionName] = newTokenPrice;
        emit UpdateTokenPrice(_collectionName, oldPrice, newTokenPrice);
    }
    
    // ------------------------------------------------------------------------
    // Removes tokens from availability 
    // ------------------------------------------------------------------------
    function stopAnyMoreOfCollectionBeingSold(string calldata _collectionName) onlyOwner external{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        collectionTotal[_collectionName] = collectionRunningCount[_collectionName];
    }
    
    // ------------------------------------------------------------------------
    // Removes N tokens from availability 
    // ------------------------------------------------------------------------
    function removeNTokensFromCollection(string calldata _collectionName, uint256 _n) onlyOwner  external{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        require(collectionTotal[_collectionName].sub(_n) >= collectionRunningCount[_collectionName]);
        collectionTotal[_collectionName] = collectionTotal[_collectionName].sub(_n);
    }
    
    // ------------------------------------------------------------------------
    // Returns all tokens owned by a user
    // ------------------------------------------------------------------------
    function getAllTokenIdsForAddress(address _owner) external view returns(uint256[] memory ids){
    	ids = new uint256[](balanceOf(_owner));
    	for(uint256 i = 0;i<allPlayers.length;i++){
    		MoralityPlayer memory player = allPlayers[i];
    		if(ownerOf(player.id) == _owner){
    			ids[i] = player.id;
    		}
    	}
    	return ids;
    }
    
    // ------------------------------------------------------------------------
    // Count all unique collection names
    // ------------------------------------------------------------------------
    function getAllCollectionNamesCount() external view returns(uint256){
        return allCollectionNames.length;
    }
    
    // ------------------------------------------------------------------------
    // Owner can update wallet where funds are transferred to
    // ------------------------------------------------------------------------
    function updateMoralityWallet(address payable newWallet) onlyOwner external returns(bool){
        emit UpdatedWallet(msg.sender, moralityWallet, newWallet);
        moralityWallet = newWallet;
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer funds to admin
    // ------------------------------------------------------------------------
    function _forwardFunds() private {
        moralityWallet.transfer(msg.value);
    }
    
    // ------------------------------------------------------------------------
    // To remove contract from blockchain
    // ------------------------------------------------------------------------
    function deprecateContract() onlyOwner external{
        selfdestruct(owner);
    }
}