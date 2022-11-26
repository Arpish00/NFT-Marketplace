//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//Console functions to help debug the smart contract just like in Javascript

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    constructor() ERC721("NFTMarketplace", "NFTM") {
       owner = payable(msg.sender);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;
    address payable owner;
    uint256 listPrice = 0.01 ether;

    struct listedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    mapping(uint256 => listedToken) private idToListedToken;

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //this function exist in openzappelin erc721Uri
        _safeMint(msg.sender, newTokenId);
        //ste token uri eixts on openzappelin
        _setTokenURI(newTokenId, tokenURI);

        createListedToken(newTokenId, price);

        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        //requirement check
        require(msg.value == listPrice, "Hopefully sending the correct price");

        require(price > 0, "price must be positive value");

        idToListedToken[tokenId] = listedToken (
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);

        emit TokenListedSuccess(tokenId, address(this), msg.sender, price, true);
    }
    
    function getAllNFTS () public view returns (listedToken[] memory) {
        uint totalCount = _tokenIds.current();
        listedToken[] memory tokens = new listedToken[](totalCount);
        uint currentNum = 0;

        //looping
        for (uint i = 0; i < totalCount; i++)
        {
            uint index = i + 1;
            listedToken storage currentItem = idToListedToken[index];
            tokens[currentNum] = currentItem;
            currentNum += 1;
        }

        return tokens;
    }

    function getMyNFTs () public view returns (listedToken[] memory) {
        uint totalCount = _tokenIds.current();
        uint itemdone = 0;
        uint itemIndex = 0;

        for (uint i = 0; i < totalCount; i++) {
            if ( idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) 
            {
                itemdone += 1;
            }
        }

        listedToken[] memory items = new listedToken[] (itemdone);

        for (uint i = 0; i < totalCount; i++) 
        {
            if ( idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender)
            {
                uint currentId = i + 1;
                
                listedToken storage currentItem = idToListedToken[currentId];
                items[itemIndex] = currentItem;
                itemIndex += 1;

            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "please send asked price to purchase this");

        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemSold.increment();


        //transfer token to new owner
        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }

    //pther helper fucnctions 
    function updateListPrice (uint256 newPrice) public payable {
        require(owner == msg.sender, "you must be owner !!");
        listPrice = newPrice;
    }

    function getPriceList() public view returns (uint256){
        return listPrice;
    }

    function getnewIdToListestToken () public view returns (listedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (listedToken memory) {
        return idToListedToken[tokenId];
    }

     function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

}