// SPDX-License-Identifier: MIT

pragma solidity >=0.8.5 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract KeringNFT is ERC721Royalty, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public metadatauri = "";

  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  address private dev = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  address private own = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
   _transferOwnership(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4); 
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }


  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public  mintCompliance(_mintAmount) {
    // Verify whitelist requirements
    
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");


    whitelistClaimed[msg.sender] = true;
    _mintLoop(msg.sender, _mintAmount);

  }

  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner  {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

     return metadatauri; 
  
  }



  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public  {
    require(_msgSender() == dev || _msgSender() == own );
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }


  function setUriPrefix(string memory _uriPrefix) public {
    require(_msgSender() == dev || _msgSender() == own );
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public {
    require(_msgSender() == dev || _msgSender() == own );
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public {
    require(_msgSender() == dev || _msgSender() == own );
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public {
    require(_msgSender() == dev || _msgSender() == own );
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public {
    require(_msgSender() == dev || _msgSender() == own );
    whitelistMintEnabled = _state;
  }

    function changeMetadatauri(string memory _metadatauri) public {
    require(_msgSender() == dev || _msgSender() == own );
    metadatauri = _metadatauri; 
  }


  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

   function gift(address[] calldata addresses, uint[] memory tokenId) public returns(bool) {
      require (dev == msg.sender || own == msg.sender);  
      require(addresses.length > 0, "Need to gift at least 1 NFT");
        
        for (uint256 i = 0; i < addresses.length; i++) {        
          require( _exists(tokenId[i]),"Nonexistent token");
          safeTransferFrom(msg.sender, addresses[i], tokenId[i]);
        }

        return true;
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }


}
