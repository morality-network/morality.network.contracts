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
    uint256[] internal uniqueArticleIds;
    uint256[] internal uniqueSubArticleIds;
    mapping(uint256 => bool) internal contentIdExists;
    mapping(uint256 => ContentMap) internal articleContentIds;
    mapping(uint256 => ContentMap) internal subArticleContentIds;
    mapping(uint256 => string) internal contentById;
    uint256 public perPage = 6;
    
    event ContentAdded(address contentCreator, uint256 indexed articleId, uint256 indexed subArticleId, uint256 indexed contentId, uint256 timestamp);
    event ContentAddedViaEvent(address contentCreator, uint256 indexed articleId, uint256 indexed subArticleId, uint256 indexed contentId, uint256 timestamp, string data);
    
    // ------------------------------------------------------------------------
    // Add content to event for content persistance - cheap 
    // ------------------------------------------------------------------------
    function addContentViaEvent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
       emit ContentAddedViaEvent(contentCreator, articleId, subArticleId, contentId, timestamp, data);
    }
    
    // ------------------------------------------------------------------------
    // Add content for content persistance expensive - expensive
    // ------------------------------------------------------------------------
    function addContent(address contentCreator, uint256 articleId, uint256 subArticleId, uint256 contentId, uint256 timestamp, string memory data) onlyModerators public {
       //Add contentId to list of already added contents
       _addUniqueIdToContentsList(contentId);
       //Add the data
       _addContent(contentId, data);
       //Add to the unique article list
       _addUniqueIdToArticleList(articleId);
       //Add to the unique article list
       _addUniqueIdToSubArticleList(subArticleId);
       //Map the articleId to the contentId
       _addArticleToContentMap(articleId, contentId);
       //Map the subArticleId to the contentId
       _addSubArticleToContentMap(subArticleId, contentId);
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
    // Get all article ids
    // ------------------------------------------------------------------------
    function getAllArticleIds() public view returns(uint256[] memory) {
        return uniqueArticleIds;
    }
    
    // ------------------------------------------------------------------------
    // Get all sub-article ids
    // ------------------------------------------------------------------------
    function getAllSubArticleIds() public view returns(uint256[] memory) {
        return uniqueSubArticleIds;
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
    function countContentForSubArticle(uint256 subArticleId) public view returns(uint256) {
        return subArticleContentIds[subArticleId].contentIds.length;
    }

    // ------------------------------------------------------------------------
    // Get page for sub article (page starts at 0) ~ all to avoid experimental
    // ------------------------------------------------------------------------
    function getPageForSubArticle(uint256 subArticleId, uint256 page) public view returns(string memory,string memory,string memory,string memory,string memory,string memory) {
        //Set up the page
        string[] memory contentToReturn = new string[](perPage);
        //Get all content ids for sub-article
        uint256[] memory contentIds = getAllContentIdsForSubArticle(subArticleId);
        //Get minimum index based on page
        uint256 indexMin = _getMinimumIndex(page);
        //Add the content ids to the page
        for(uint256 i=0; i<perPage;i++){
            //Get current index based on page
            uint256 currentIndex = _getCurrentIndex(indexMin, i);
            //If the current index exists then add the content to the page
            if(contentIds.length > currentIndex){
                uint256 id = contentIds[currentIndex];
                contentToReturn[i] = getContentById(id);
            }
        }
        //Return the page
        return _returnPageOfContent(contentToReturn[0], contentToReturn[1], contentToReturn[2], contentToReturn[3], contentToReturn[4], contentToReturn[5]);
    }

    // ------------------------------------------------------------------------
    // Get page for article (page starts at 0) ~ all to avoid experimental
    // To break this method down, we need to use the experimental encoder
    // ------------------------------------------------------------------------
    function getPageForArticle(uint256 articleId, uint256 page) public view returns(string memory,string memory,string memory,string memory,string memory,string memory) {
        //Set up the page
        string[] memory contentToReturn = new string[](perPage);
        //Get all content ids for article
        uint256[] memory contentIds = getAllContentIdsForArticle(articleId);
        //Get minimum index based on page
        uint256 indexMin = _getMinimumIndex(page);
        //Add the content ids to the page
        for(uint256 i=0; i<perPage;i++){
            //Get current index based on page
            uint256 currentIndex = _getCurrentIndex(indexMin, i);
            //If the current index exists then add the content to the page
            if(contentIds.length > currentIndex){
                uint256 id = contentIds[currentIndex];
                contentToReturn[i] = getContentById(id);
            }
        }
        //Return the page
        return _returnPageOfContent(contentToReturn[0], contentToReturn[1], contentToReturn[2], contentToReturn[3], contentToReturn[4], contentToReturn[5]);
    }

    
    //Internal helpers---------------------------------------------------------
    
    // ------------------------------------------------------------------------
    // Add unique article Id to array
    // ------------------------------------------------------------------------
    function _addUniqueIdToArticleList(uint256 articleId) internal{
       if(articleContentIds[articleId].exists == false)
       {
           uniqueArticleIds.push(articleId);
       }
    }
    
    // ------------------------------------------------------------------------
    // Add unique sub-article Id to array
    // ------------------------------------------------------------------------
    function _addUniqueIdToSubArticleList(uint256 subArticleId) internal{
       if(subArticleContentIds[subArticleId].exists == false)
       {
           uniqueSubArticleIds.push(subArticleId);
       }
    }
    
    // ------------------------------------------------------------------------
    // Add unique article Id to array
    // ------------------------------------------------------------------------
    function _addArticleToContentMap(uint256 articleId, uint256 contentId) internal{
       if(articleContentIds[articleId].containsContentId[contentId] == false){
           articleContentIds[articleId].exists = true;
           articleContentIds[articleId].contentIds.push(contentId);
           articleContentIds[articleId].containsContentId[contentId] = true;    
       }
    }
    
    // ------------------------------------------------------------------------
    // Add unique sub-article Id to array
    // ------------------------------------------------------------------------
    function _addSubArticleToContentMap(uint256 subArticleId, uint256 contentId) internal{
       if(subArticleContentIds[subArticleId].containsContentId[contentId] == false){
           subArticleContentIds[subArticleId].exists = true;
           subArticleContentIds[subArticleId].contentIds.push(contentId);
           subArticleContentIds[subArticleId].containsContentId[contentId] = true;    
       }
    }
    
    // ------------------------------------------------------------------------
    // Add unique content Id to array
    // ------------------------------------------------------------------------
    function _addUniqueIdToContentsList(uint256 contentId) internal{
       if(contentIdExists[contentId] == false){
           uniqueContentIds.push(contentId);
           contentIdExists[contentId] = true;
       }
    }
    
    // ------------------------------------------------------------------------
    // Try to add content if it doesnt exist
    // ------------------------------------------------------------------------
    function _addContent(uint256 contentId, string memory data) internal{
       contentById[contentId] = data;
    }
    
    // ------------------------------------------------------------------------
    // Get minimum index based on page 
    // ------------------------------------------------------------------------
    function _getMinimumIndex(uint256 page) internal view returns(uint256){
        return page.mul(perPage.sub(1));
    }
    
    // ------------------------------------------------------------------------
    // Get current index from base of index min plus the loop index
    // ------------------------------------------------------------------------
    function _getCurrentIndex(uint256 indexMin, uint256 loopIndex) internal pure returns(uint256){
        return indexMin.add(loopIndex);
    }
    
    // ------------------------------------------------------------------------
    // This mapping saves a block of code written out twice
    // ------------------------------------------------------------------------
    function _returnPageOfContent(string memory pageItem1, string memory pageItem2, string memory pageItem3, string memory pageItem4, string memory pageItem5, string memory pageItem6) internal pure 
        returns(string memory,string memory,string memory,string memory,string memory,string memory) {
        return(pageItem1, pageItem2, pageItem3, pageItem4, pageItem5, pageItem6);
    }
    
}