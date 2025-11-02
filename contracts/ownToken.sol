// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnToken is ERC20,Ownable {
    // Metadata for the token
    string private _imageURI;

    constructor( 
        string memory name,
        string memory symbol,
        uint8 decimal, 
        string memory imageURI,
        address receiver
        ) ERC20(name, symbol) Ownable(msg.sender){
        _imageURI = imageURI;
        // Mint initial supply to the owner (optional)
        _mint(receiver, 1000000000 * 10 ** decimal);
    }
    // Function to update the image URI (only by owner)
    function setImageURI(string memory newImageURI) public onlyOwner {
        _imageURI = newImageURI;
    }
    // Function to retrieve the image URI
    function imageURI() public view returns (string memory) {
        return _imageURI;
    }
}