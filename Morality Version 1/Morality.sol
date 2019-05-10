pragma solidity ^0.4.25;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
  
  function mintToken(address target, uint256 mintedAmount) public returns(bool){
	balances[target] = balances[target].add(mintedAmount);
	totalSupply = totalSupply.add(mintedAmount);
	emit Transfer(0, this, mintedAmount);
	emit Transfer(this, target, mintedAmount);
	return true;
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view public returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Recoverable is Ownable {

  constructor() public {
  }

  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

  function tokensToBeReturned(ERC20Basic token) public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

contract StandardTokenExt is Recoverable, StandardToken {

  function isToken() public pure returns (bool weAre) {
    return true;
  }
}

contract BurnableToken is StandardTokenExt {

  address public BURN_ADDRESS = 0x0000000000000000000000000000000000000000;

  event Burned(address burner, uint256 burnedAmount);

  function burn(uint256 burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    emit Burned(burner, burnAmount);
    emit Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

contract MoralityAI is BurnableToken {
  
  string public name;
  string public symbol;
  uint256 public decimals;
  address public creator;

  event UpdatedTokenInformation(string newName, string newSymbol);
  event LogFundsReceived(address sender, uint amount);
  event LogFundsSent(address receiver, uint amount);
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter);

  constructor() payable public {
    name = "MoralityAI";
    symbol = "MO";
    totalSupply = 1000000000000000000000000000;
	
    decimals = 18;
    balances[msg.sender] = totalSupply;
    creator = msg.sender;
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function() payable external {
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function withdraw(uint256 amount) onlyOwner public returns(bool){
	require(amount <= address(this).balance);
    address(owner).transfer(amount);
    return true;
  }

  function kill() onlyOwner public{
    selfdestruct(creator);
  }

  function send(address target, uint256 amount) public{
    require(target.send(amount));
    emit LogFundsSent(target, amount);
  }
 
  function setTokenInformation(string memory _name, string memory _symbol) public{
    require(msg.sender == upgradeMaster);
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }

  function transfer(address _to, uint256 _value) public returns (bool success){
    return super.transfer(_to, _value);
  }
  
  function mintToken(address target, uint256 mintedAmount) onlyOwner public returns (bool){
	return super.mintToken(target, mintedAmount);
  }
  
}