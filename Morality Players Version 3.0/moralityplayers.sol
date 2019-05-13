pragma solidity ^0.5.7;

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

library AddressUtils
{
  function isContract(address _addr) internal view returns (bool addressCheck)
  {
    uint256 size;
    assembly { size := extcodesize(_addr) } // solhint-disable-line
    addressCheck = size > 0;
  }
}

interface ERC165
{
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver
{
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

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

contract Ownable
{
  string public constant NOT_OWNER = "018001";
  string public constant ZERO_ADDRESS = "018002";
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public
  {
    owner = msg.sender;
  }

  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_OWNER);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner
  {
    require(_newOwner != address(0), ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract NFToken is ERC721,
  SupportsInterface,
  Ownable
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

  function safeTransferFromWithData(address _from, address _to, uint256 _tokenId, bytes calldata _data) external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external
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

  function _transfer(address _to, uint256 _tokenId) internal
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

contract TokenMetaData{
    
  string tokenName;
  string tokenSymbol;
  uint256 totalTokens = 0;
  
  constructor(string memory _tokenName, string memory _tokenSymbol) public {
     tokenName = _tokenName;
     tokenSymbol = _tokenSymbol;
  }    
  
  function tokenCount() external view returns (uint256)
  {
    return totalTokens;
  }
    
  function name() external view returns (string memory)
  {
    return tokenName;
  }
  
  function symbol() external view returns (string memory)
  {
     return tokenSymbol;
  }
  
}

contract MoralityPlayers is NFToken, TokenMetaData{
    
    struct MoralityPlayer{
        uint256 id;
        string name; 
        string description; 
        string collectionName;
        uint itemNumber;
        uint totalInExistance; 
        uint256 tokenPrice;
    }
    
    string constant NO_TOKENS = "No tokens left in this collection";
    string constant COLLECT_EXISTS = "Collection name already exists";
    string constant COLLECT_DOESNT_EXIST = "Collection doesn't exist";
    string constant DOESNT_OWN = "The contract does not own the token";
    string constant PRICE_TOO_LOW = "Token price is higher than provided";
    MoralityPlayer[] public items; 
    mapping(string => bool) public collectionNamesUsed;
    mapping(string => uint256) public collectionRunningCount;
    mapping(string => uint256) public collectionTotal;
    mapping(string => uint256) public collectionPricePerUnit;
    mapping(string => string) public collectionItemName;
    mapping(string => string) public collectionItemDescription;
    mapping(string => uint256) public collectionTotalRaised;
    string[] public allCollectionNames;
    address payable public moralityWallet;
    uint256 public totalWeiRaised;
    
    event UpdatedWallet(address indexed updatedBy, address indexed oldWallet, address indexed newWallet);
    event CollectionCreated(address indexed collectionOwner, string indexed name, string indexed collectionName, uint256 totalToMint, uint256 pricePerUnit);
    event UpdateTokenPrice(string indexed collectionName, uint256 oldPrice, uint256 newTokenPrice);
    
    constructor(address payable _moralityWallet, string memory _tokenName, string memory _tokenSymbol) 
        TokenMetaData(_tokenName,  _tokenSymbol) public {
        moralityWallet = _moralityWallet;
    }
    
    function createCollection(string memory _name, string memory _description, string memory _collectionName, address _collectionOwner, uint256 _totalToMint, uint256 _tokenPrice) onlyOwner public{
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
   
    function buyToken(string memory _collectionName) payable public{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        require(collectionRunningCount[_collectionName] < collectionTotal[_collectionName], NO_TOKENS);
        require(collectionPricePerUnit[_collectionName] >= msg.value, PRICE_TOO_LOW);
        uint256 id = items.length;
        uint256 nextItemNumber = collectionRunningCount[_collectionName].add(1);
        items.push(MoralityPlayer(id, collectionItemName[_collectionName], collectionItemDescription[_collectionName], 
            _collectionName, nextItemNumber, collectionTotal[_collectionName], collectionPricePerUnit[_collectionName]));
        collectionRunningCount[_collectionName] = nextItemNumber;
        _mint(msg.sender,id); 
        totalWeiRaised = totalWeiRaised.add(msg.value);
        collectionTotalRaised[_collectionName] = collectionTotalRaised[_collectionName].add(msg.value);
        totalTokens++;
        _forwardFunds();
    }

    function tokensLeft(string memory _collectionName) public view returns(uint256){
        if(collectionNamesUsed[_collectionName] == false){ return 0; }
        return collectionTotal[_collectionName].sub(collectionRunningCount[_collectionName]);
    }
    
    function updateCollectionItemPrice(string memory _collectionName, uint256 newTokenPrice) onlyOwner public{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        uint256 oldPrice = collectionPricePerUnit[_collectionName];
        collectionPricePerUnit[_collectionName] = newTokenPrice;
        emit UpdateTokenPrice(_collectionName, oldPrice, newTokenPrice);
    }
    
    function stopAnyMoreOfCollectionBeingSold(string memory _collectionName) onlyOwner public{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        collectionTotal[_collectionName] = collectionRunningCount[_collectionName];
    }
    
    function removeNTokensFromCollection(string memory _collectionName, uint256 _n) onlyOwner public{
        require(collectionNamesUsed[_collectionName] == true, COLLECT_DOESNT_EXIST);
        require(collectionTotal[_collectionName].sub(_n) >= collectionRunningCount[_collectionName]);
        collectionTotal[_collectionName] = collectionTotal[_collectionName].sub(_n);
    }
    
    function getAllTokenIdsForAddress(address _owner) public view returns(uint256[] memory ids){
    	ids = new uint256[](balanceOf(_owner));
    	for(uint256 i = 0;i<items.length;i++){
    		MoralityPlayer memory item = items[i];
    		if(ownerOf(item.id) == _owner){
    			ids[i] = item.id;
    		}
    	}
    	return ids;
    }
    
    function getAllCollectionNamesCount() public view returns(uint256){
        return allCollectionNames.length;
    }
    
    function updateMoralityWallet(address payable newWallet) onlyOwner public returns(bool){
        emit UpdatedWallet(msg.sender, moralityWallet, newWallet);
        moralityWallet = newWallet;
        return true;
    }
    
    function _forwardFunds() internal {
        moralityWallet.transfer(msg.value);
    }
}