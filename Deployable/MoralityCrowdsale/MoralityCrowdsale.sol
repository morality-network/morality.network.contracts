pragma solidity ^0.5.7;

// ------------------------------------------------------------------------
// Interface that the crowdsale uses (taken from token)
// ------------------------------------------------------------------------
contract IERC20 {
    
  uint256 public totalSupply;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Minted(address target, uint256 mintedAmount);
  event Burned(address burner, uint256 burnedAmount);
  
}

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
// Safe transfer function contract to provide mo
// ------------------------------------------------------------------------
library SafeERC20 {
    using SafeMath for uint256;

    // ------------------------------------------------------------------------
    // Create the safe transfer function contract to provide mo
    // ------------------------------------------------------------------------
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
    
}

// ------------------------------------------------------------------------
// Create non ReentrancyGuard contract for buy tokens
// ------------------------------------------------------------------------
contract ReentrancyGuard {
    
    uint256 private _guardCounter;

    // ------------------------------------------------------------------------
    // Constructor to start counter
    // ------------------------------------------------------------------------
    constructor () internal {
        _guardCounter = 1;
    }

    // ------------------------------------------------------------------------
    // Set the nonReentrant modifier to stop re-entry of function
    // ------------------------------------------------------------------------
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
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
  function transferOwnership(address payable _newOwner) external onlyOwner {
    potentialNewOwner = _newOwner;
  }
  
  // ------------------------------------------------------------------------
  // To ensure correct transfer, the new owner has to confirm new ownership
  // ------------------------------------------------------------------------
  function acceptOwnership() external {
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
// Crowdsale wrapper contract
// ------------------------------------------------------------------------
contract Crowdsale is Breaker, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ------------------------------------------------------------------------
    // Token the crowdsale sells
    // ------------------------------------------------------------------------
    IERC20 private _token;
    address payable private _wallet;
    // ------------------------------------------------------------------------
    // 1 wei will give you 1 unit
    // ------------------------------------------------------------------------
    uint256 private _rate;
    uint256 private _weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // ------------------------------------------------------------------------
    // Constructor to allow total rate at which tokens are given to wei
    // To set the wallet that the funds are sent token
    // The token that is to be sent (address)
    // ------------------------------------------------------------------------
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    // ------------------------------------------------------------------------
    // Allows the contract to be payable and tokens to be returned
    // ------------------------------------------------------------------------
    function () external payable {
        buyTokens(msg.sender);
    }

    // ------------------------------------------------------------------------
    // Returns the token that the wrapper is mapped to
    // ------------------------------------------------------------------------
    function token() external view returns (IERC20) {
        return _token;
    }

    // ------------------------------------------------------------------------
    // Returns the admin wallet funds are sent to
    // ------------------------------------------------------------------------
    function wallet() external view returns (address) {
        return _wallet;
    }

    // ------------------------------------------------------------------------
    // Returns the rate of wei to token
    // ------------------------------------------------------------------------
    function rate() external view returns (uint256) {
        return _rate;
    }

    // ------------------------------------------------------------------------
    // Returns how much wei has been raised using this wrapper
    // ------------------------------------------------------------------------
    function weiRaised() external view returns (uint256) {
        return _weiRaised;
    }

    // ------------------------------------------------------------------------
    // Instead of sending wei to contract we can also pay this fundtion
    // We can also send tokens to another users account this way
    // ------------------------------------------------------------------------
    function buyTokens(address beneficiary) public nonReentrant outOfLockdown payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        //Calculate token amount to sent
        uint256 tokens = _getTokenAmount(weiAmount);
        //Update total raised
        _weiRaised = _weiRaised.add(weiAmount);
        //Send tokens to beneficiary
        _processPurchase(beneficiary, tokens);
        //Update the event log
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
        //Forwad the funds to admin
        _forwardFunds();
    }

    // ------------------------------------------------------------------------
    // Require purchase isn't burn address and amount is greater than 0
    // ------------------------------------------------------------------------
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal pure {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

    // ------------------------------------------------------------------------
    // Safe transfer the tokens to user
    // ------------------------------------------------------------------------
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    // ------------------------------------------------------------------------
    // Wrapper for the above method
    // ------------------------------------------------------------------------
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    // ------------------------------------------------------------------------
    // Get amount of tokens for wei sent
    // ------------------------------------------------------------------------
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    
    // ------------------------------------------------------------------------
    // Sends funds paid to the contract to the admin account
    // ------------------------------------------------------------------------
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
    // ------------------------------------------------------------------------
    // To remove contract from blockchain
    // ------------------------------------------------------------------------
    function deprecateContract() onlyOwner external{
        selfdestruct(owner);
    } 
}