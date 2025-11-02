import { network } from "hardhat";

const { ethers } = await network.connect({
  network: "hardhatOp",
  chainType: "op",
});

console.log("Sending transaction using the OP chain type");

const [sender] = await ethers.getSigners();


// const myContractAddress =  await ethers.

// console.log("Sending 1 wei from", sender.address, "to itself");

// console.log("Sending L2 transaction");
// const tx = await sender.sendTransaction({
//   to: sender.address,
//   value: 1n,
// });

// await tx.wait();

// console.log("Transaction sent successfully");
