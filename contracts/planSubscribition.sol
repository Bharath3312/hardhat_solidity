// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

}

contract SubscriptionManager {
    address public admin;
    address public assetToken;

    event Subscribed(string  userId, string planId, uint256 amount,address assetToken);

    constructor(address _assetToken, address _admin) {
        assetToken = _assetToken;
        admin = _admin;
    }
     modifier ownerOnly() {
            require(msg.sender == admin, "You not the owner!");
            _;
    }

    function subscribe(string memory userId, string memory planId, uint256 amount) external {

        require(IERC20(assetToken).balanceOf(msg.sender) >= amount, "Insufficient Balance");
        require(IERC20(assetToken).transferFrom(msg.sender, admin, amount), "Transfer failed");

        emit Subscribed(userId, planId, amount,assetToken);
    }

    function changeOwner(address _newAdmin) external  ownerOnly {
        admin = _newAdmin;
    }

    function changeAssetToken(address _newAssetToken) external  ownerOnly {
        assetToken = _newAssetToken;
    }
}
