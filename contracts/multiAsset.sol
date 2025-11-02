// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Subscription {

    address public admin;
    mapping(string => bool) public usedTxRefs; // prevent duplicate

    event PlanPurchased(address indexed user, uint planId, string txRef, uint amount);

    constructor() {
        admin = msg.sender;
    }

    function buyPlan(uint planId, string memory txRef) external payable {
        require(!usedTxRefs[txRef], "Duplicate transaction detected");
        require(msg.value > 0, "Payment required");

        usedTxRefs[txRef] = true; // mark as used

        // send funds to admin
        payable(admin).transfer(msg.value);

        emit PlanPurchased(msg.sender, planId, txRef, msg.value);
    }
}
