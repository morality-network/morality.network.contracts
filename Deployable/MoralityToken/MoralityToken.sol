pragma solidity ^0.5.11;

library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
    
  address payable public owner;
  address payable public potentialNewOwner;
 
  event OwnershipTransferred(address payable indexed from, address payable indexed to);

  constructor() internal {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address payable _newOwner) external onlyOwner {
    potentialNewOwner = _newOwner;
  }
  function acceptOwnership() external {
    require(msg.sender == potentialNewOwner);
    emit OwnershipTransferred(owner, potentialNewOwner);
    owner = potentialNewOwner;
  }
}

contract CircuitBreaker is Ownable {
    
    bool private isApplicationLockedDown;
    // External contract payment via collection
    bool private isECPVCLockedDown;
    // External contract payment
    bool private isECPLockedDown;

    constructor () internal {
        isApplicationLockedDown = false;
        isECPVCLockedDown = false;
        isECPLockedDown = false;
    }
    modifier applicationLockdown() {
        require(isApplicationLockedDown == false);
        _;
    }
    modifier ecpvcLockdown() {
        require(isECPVCLockedDown == false);
        _;
    }
    modifier ecpLockdown() {
        require(isECPVCLockedDown == false);
        _;
    }
    function updateApplicationLockdownState(bool state) public onlyOwner{
       isApplicationLockedDown = state;
    }
    function updateECPCVLockdownState(bool state) public onlyOwner{
        isECPVCLockedDown = state;
    }
    function updateECPLockdownState(bool state) public onlyOwner{
        isECPLockedDown = state;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  mapping (address => mapping (address => uint256)) private allowed;

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract MintableToken is ERC20, Ownable{
    
  event Minted(address target, uint mintedAmount, uint time);
  
  function mintToken(address target, uint256 mintedAmount) public onlyOwner returns(bool){
	balances[target] = balances[target].add(mintedAmount);
	totalSupply = totalSupply.add(mintedAmount);
	emit Transfer(address(0), address(this), mintedAmount);
	emit Transfer(address(this), target, mintedAmount);
	emit Minted(target, mintedAmount, now);
	return true;
  }
}

contract RecoverableToken is ERC20, Ownable {
   
  event RecoveredTokens(address token, address owner, uint tokens, uint time);
  
  function recoverTokens(ERC20 token) public onlyOwner {
    uint tokens = tokensToBeReturned(token);
    require(token.transfer(owner, tokens) == true);
    emit RecoveredTokens(address(token), owner,  tokens, now);
  }
  function tokensToBeReturned(ERC20 token) public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

contract BurnableToken is ERC20, Ownable {
    
  address public BURN_ADDRESS;

  event Burned(address burner, uint256 burnedAmount);
 
  function burn(uint256 burnAmount) public onlyOwner {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    emit Burned(burner, burnAmount);
    emit Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

contract WithdrawableToken is ERC20, Ownable {
    
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter);
  
  function withdraw(uint256 amount) public onlyOwner returns(bool){
	require(amount <= address(this).balance);
    address(owner).transfer(amount);
	emit WithdrawLog(address(owner).balance.sub(amount), amount, address(owner).balance);
    return true;
  } 
}

contract IPurchasableToken{
    function purchase(ERC20 tokenAddress, string memory collectionName, address buyer, uint256 value) public returns(bool);
}

contract ITradableToken{
    function purchase(address tokenAddress, address buyer, uint256 value) public returns (bool success);
}

contract ExternalContractInvocations is ERC20{
     
  enum ExternalPurchaseType{
      Item,
      Token
  }
  
  event ApprovedAndInvokedExternalPurchase(ExternalPurchaseType typeOfPurchase, address tokenAddress, string collectionName, address buyer, uint256 value, uint256 time);
  event ApprovedAndInvokedExternalPurchase(ExternalPurchaseType typeOfPurchase, address tokenAddress, address buyer, uint256 value, uint256 time);
     
  function approveAndInvokePurchase(address tokenAddress, string memory collectionName, uint256 value) public returns(bool){
    require(approve(tokenAddress, value) == true);
    require(IPurchasableToken(tokenAddress).purchase(this, collectionName, msg.sender, value) == true);
    emit ApprovedAndInvokedExternalPurchase(ExternalPurchaseType.Item, tokenAddress, collectionName, msg.sender, value, now);
    return true;
  }
  
  function approveAndInvokePurchase(address tokenAddress, uint256 value) public returns(bool){
    require(approve(tokenAddress, value) == true);
    require(ITradableToken(tokenAddress).purchase(address(this), msg.sender, value) == true);
    emit ApprovedAndInvokedExternalPurchase(ExternalPurchaseType.Token, tokenAddress, msg.sender, value, now);
    return true;
  }
}

contract Morality is RecoverableToken, BurnableToken, MintableToken, WithdrawableToken, 
  ExternalContractInvocations, CircuitBreaker { 
      
  string public name;
  string public symbol;
  uint256 public decimals;
  address payable public creator;
  
  event LogFundsReceived(address sender, uint amount);
  event UpdatedTokenInformation(string newName, string newSymbol);

  constructor(uint256 _totalTokensToMint) payable public {
    name = "Morality";
    symbol = "MO";
    totalSupply = _totalTokensToMint;
    decimals = 18;
    balances[msg.sender] = totalSupply;
    creator = msg.sender;
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function() payable external applicationLockdown {
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function transfer(address _to, uint256 _value) public applicationLockdown returns (bool success){
    return super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public applicationLockdown returns (bool success){
    return super.transferFrom(_from, _to, _value);
  }
  
  function multipleTransfer(address[] calldata _toAddresses, uint256[] calldata _toValues) external applicationLockdown returns (bool) {
    require(_toAddresses.length == _toValues.length);
    for(uint256 i = 0;i<_toAddresses.length;i++){
       require(super.transfer(_toAddresses[i], _toValues[i]) == true);
    }
    return true;
  }
  
  function approve(address _spender, uint256 _value) public applicationLockdown returns (bool) {
    return super.approve(_spender, _value);
  }
  
  function approveAndInvokePurchase(address tokenAddress, string memory collectionName, uint256 value) public ecpvcLockdown applicationLockdown returns(bool){
    return super.approveAndInvokePurchase(tokenAddress, collectionName, value);
  }
  
  function approveAndInvokePurchase(address tokenAddress, uint256 value) public ecpLockdown applicationLockdown returns(bool){
    return super.approveAndInvokePurchase(tokenAddress, value);
  }
  
  function setTokenInformation(string calldata _name, string calldata _symbol) onlyOwner external {
    require(msg.sender != creator);
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }
  
  function withdraw(uint256 _amount) onlyOwner public returns(bool){
	return super.withdraw(_amount);
  }

  function mintToken(address _target, uint256 _mintedAmount) onlyOwner public returns (bool){
	return super.mintToken(_target, _mintedAmount);
  }
  
  function burn(uint256 _burnAmount) onlyOwner public{
    return super.burn(_burnAmount);
  }
  
  function updateApplicationLockdownState(bool _state) onlyOwner public{
    super.updateApplicationLockdownState(_state);
  }
  
  function updateECPLockdownState(bool _state) onlyOwner public{
    super.updateECPLockdownState(_state);
  }
  
  function updateECPVCLockdownState(bool _state) onlyOwner public{
    super.updateECPCVLockdownState(_state);
  }
  
  function recoverTokens(ERC20 _token) onlyOwner public{
     super.recoverTokens(_token);
  }
  
  function isToken() public pure returns (bool _weAre) {
    return true;
  }

  function deprecateContract() onlyOwner external{
    selfdestruct(creator);
  }
}
