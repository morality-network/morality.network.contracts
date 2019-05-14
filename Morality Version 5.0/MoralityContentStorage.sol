pragma solidity ^0.5.7;

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
contract MoralityContentStorage is Moderatable{
    
    using SafeMath for uint256;
    
    struct ContentMap{
        uint256[] contentIds;
        mapping(uint256 => bool) containsContentId;
        bool exists;
    }
    
    uint256[] internal uniqueContentIds;
    mapping(uint256 => bool) internal contentIdExists;
    mapping(uint256 => ContentMap) internal articleContentIds;
    mapping(uint256 => ContentMap) internal subArticleContentIds;
    mapping(uint256 => string) internal contentById;
    uint256 public perPage = 7;
    
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
       //Add contentId to list of already added contents
       if(contentIdExists[contentId] == false){
           uniqueContentIds.push(contentId);
           contentIdExists[contentId] = true;
       }
       //Add the data
       contentById[contentId] = data;
       //Map the articleId to the contentId
       if(articleContentIds[articleId].containsContentId[contentId] == false){
           articleContentIds[articleId].exists = true;
           articleContentIds[articleId].contentIds.push(contentId);
           articleContentIds[articleId].containsContentId[contentId] = true;    
       }
       //Map the subArticleId to the contentId
       if(subArticleContentIds[subArticleId].containsContentId[contentId] == false){
           articleContentIds[articleId].exists = true;
           subArticleContentIds[subArticleId].contentIds.push(contentId);
           subArticleContentIds[subArticleId].containsContentId[contentId] = true;    
       }
       //Add event (everything but content)
       emit ContentAdded(contentCreator, articleId, subArticleId, contentId, timestamp);
    }
    
    // ------------------------------------------------------------------------
    // Get Content by contentId
    // ------------------------------------------------------------------------
    function getContentById(uint256 contentId) public view returns(string memory) {
        return contentById[contentId];
    }
    
    // ------------------------------------------------------------------------
    // Get all content ids
    // ------------------------------------------------------------------------
    function getAllContentIds() public view returns(uint256[] memory) {
        return uniqueContentIds;
    }
    
    // ------------------------------------------------------------------------
    // Get all content count
    // ------------------------------------------------------------------------
    function getAllContentCount() public view returns(uint256) {
        return uniqueContentIds.length;
    }
    
    // ------------------------------------------------------------------------
    // Get all content ids for article
    // ------------------------------------------------------------------------
    function getAllContentIdsForArticle(uint256 articleId) public view returns(uint256[] memory) {
        return articleContentIds[articleId].contentIds;
    }
    
    // ------------------------------------------------------------------------
    // Count content for article
    // ------------------------------------------------------------------------
    function countContentForArticle(uint256 articleId) public view returns(uint256) {
        return articleContentIds[articleId].contentIds.length;
    }
    
    // ------------------------------------------------------------------------
    // Get all content ids for sub-article
    // ------------------------------------------------------------------------
    function getAllContentIdsForSubArticle(uint256 subArticleId) public view returns(uint256[] memory) {
        return subArticleContentIds[subArticleId].contentIds;
    }
    
    // ------------------------------------------------------------------------
    // Count content for sub-article
    // ------------------------------------------------------------------------
    function countContentForSubArticle(uint256 subArticleId) public view returns(uint256 count) {
        return subArticleContentIds[subArticleId].contentIds.length;
    }
    
    // ------------------------------------------------------------------------
    // Get page for sub article (page starts at 0) ~ all to avoid experimental
    // ------------------------------------------------------------------------
    function getPageForSubArticle(uint256 subArticleId, uint256 page) public view 
        returns(string memory pageItem1,
                string memory pageItem2,
                string memory pageItem3,
                string memory pageItem4,
                string memory pageItem5,
                string memory pageItem6,
                string memory pageItem7) {
        string[] memory contentToReturn = new string[](perPage);
        uint256[] memory contentIds = subArticleContentIds[subArticleId].contentIds;
        uint256 index = page.mul(perPage.sub(1));
        for(uint256 i=0; i<perPage;i++){
            contentToReturn[i] = contentById[contentIds[index.add(i)]];
        }
        pageItem1 = contentToReturn[0];
        pageItem2 = contentToReturn[1];
        pageItem3 = contentToReturn[2];
        pageItem4 = contentToReturn[3];
        pageItem5 = contentToReturn[4];
        pageItem6 = contentToReturn[5];
        pageItem7 = contentToReturn[6];
    }
    
    // ------------------------------------------------------------------------
    // Get page for article (page starts at 0) ~ all to avoid experimental
    // ------------------------------------------------------------------------
    function getPageForArticle(uint256 articleId, uint256 page) public view 
        returns(string memory pageItem1,
                string memory pageItem2,
                string memory pageItem3,
                string memory pageItem4,
                string memory pageItem5,
                string memory pageItem6,
                string memory pageItem7) {
        string[] memory contentToReturn = new string[](perPage);
        uint256[] memory contentIds = articleContentIds[articleId].contentIds;
        uint256 index = page.mul(perPage.sub(1));
        for(uint256 i=0; i<perPage;i++){
            contentToReturn[i] = contentById[contentIds[index.add(i)]];
        }
        pageItem1 = contentToReturn[0];
        pageItem2 = contentToReturn[1];
        pageItem3 = contentToReturn[2];
        pageItem4 = contentToReturn[3];
        pageItem5 = contentToReturn[4];
        pageItem6 = contentToReturn[5];
        pageItem7 = contentToReturn[6];
    }
}