// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract ArtLandscapeNFT is ERC721, Ownable, ChainlinkClient {
    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public maxSupply;
    string private baseURI;
    uint256 private constant MAX_RANDOM_NUMBER = 100;
    
    event ArtLandscapeMinted(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => string) private _tokenURIs;

    // Chainlink integration
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    mapping(bytes32 => uint256) private requestIdToTokenId;

    constructor(
        string memory _baseURI_,
        uint256 _maxSupply,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) ERC721("ArtLandscapeNFT", "ALNFT") {
        baseURI = _baseURI_;
        maxSupply = _maxSupply;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function mintArtLandscape() external {
        require(totalSupply < maxSupply, "Maximum supply reached");
        
        uint256 tokenId = totalSupply + 1;
        totalSupply++;

        _safeMint(msg.sender, tokenId);
        _generateArt(tokenId);
        
        emit ArtLandscapeMinted(msg.sender, tokenId);
    }
    
    function _generateArt(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721Metadata: Art generation for nonexistent token");
        bytes32 txHash = keccak256(abi.encodePacked(tx.origin));
        requestArtFromAI(txHash);
        }

        //onverts a bytes32 data type into a string, removes any leading zeroes in the bytes32 data.
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
            }
        bytes memory bytesArray = new bytes(i);
        for(i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
            }
        return string(bytesArray);
    }



    function requestArtFromAI(bytes32 txHash) internal returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        string memory txHashString = bytes32ToString(txHash);
        Chainlink.add(request, "txHash", txHashString);
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        return requestId;
    }

        
    // Handle the Chainlink callback in the `fulfill` function
    function fulfill(bytes32 requestId, bytes32 ipfsHash) public recordChainlinkFulfillment(requestId) {
        uint256 tokenId = requestIdToTokenId[requestId];
        string memory baseIpfsURI = "ipfs://";
        string memory tokenURI_ = string(abi.encodePacked(baseIpfsURI, hashToString(ipfsHash)));
        _tokenURIs[tokenId] = tokenURI_;
    }
    
    function generateArtFromHash(bytes32 hash) internal pure returns (string memory) {
        // Here you can implement your own logic to generate art based on the hash
        // This can be an algorithm, a lookup table, or any other method you prefer
        // For simplicity, we return the hash as a string in this example
        return hashToString(hash);
    }
    
    function hashToString(bytes32 hash) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 char = bytes1(bytes32(uint256(hash) * 2**(8 * i)));
            bytes1 hi = bytes1(uint8(char) / 16);
            bytes1 lo = bytes1(uint8(char) % 16);
            buffer[i * 2] = charToHex(hi);
            buffer[i * 2 + 1] = charToHex(lo);
        }
        return string(buffer);
    }
    
    function charToHex(bytes1 char) internal pure returns (bytes1) {
        if (uint8(char) < 10) {
            return bytes1(uint8(char) + 0x30);
        } else {
            return bytes1(uint8(char) + 0x57);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

}
