import { network } from "hardhat";

const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});


async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Using deployer account:", deployer.address);

  // --------------------------
  // 1️⃣ Config: Existing addresses
  // --------------------------
  let tokenAddress = ""  //process.env.OWN_TOKEN_ADDRESS || "";
  let subscriptionAddress = ""  //process.env.SUBSCRIPTION_ADDRESS || "";
  const userId = "68d2444f3d1897869c4a106d";
  const planId = "68eca46603d84b5ec8c5b025";
  const amount = "40"
  // --------------------------
  // 2️⃣ Deploy OwnToken if not exists
  // --------------------------
  let token: any;
  if (!tokenAddress) {
    const TokenFactory = await ethers.getContractFactory("OwnToken");
    token = await TokenFactory.deploy(
      "Tether USDT Hardhat ",
      "USDT",
      18,
      "https://image.url/",
      deployer.address
    );
    // await token.deployed();
    tokenAddress = token.target;
    console.log("OwnToken deployed at:", tokenAddress);

    const accounts = await ethers.getSigners();
    const amountToDistribute = ethers.parseUnits("1000", 18);
    for (const acc of accounts.slice(1)) {
      const tx = await token.transfer(acc.address, amountToDistribute);
      await tx.wait();
      console.log(`✅ Sent 1000 USDT to ${acc.address}`);
    }
  } else {
    token = await ethers.getContractAt("OwnToken", tokenAddress);
    console.log("Using existing OwnToken at:", tokenAddress);
  }

  // --------------------------
  // 3️⃣ Deploy SubscriptionManager if not exists
  // --------------------------
  let subscription: any;
  if (!subscriptionAddress) {
    const SubscriptionFactory = await ethers.getContractFactory("SubscriptionManager");
    subscription = await SubscriptionFactory.deploy(tokenAddress, deployer.address);
    // await subscription.deployed();
    subscriptionAddress = subscription.target;
    console.log("SubscriptionManager deployed at:", subscriptionAddress);
  } else {
    subscription = await ethers.getContractAt("SubscriptionManager", subscriptionAddress);
    console.log("Using existing SubscriptionManager at:", subscriptionAddress);
  }

  // --------------------------
  // 4️⃣ Approve tokens for subscription
  // --------------------------
  const amountToSubscribe = ethers.parseUnits(amount, 18); // example amount
  const allowance = await token.allowance(deployer.address, subscriptionAddress);

  if (allowance < amountToSubscribe) {
    const approveTx = await token.approve(subscriptionAddress, amountToSubscribe);
    await approveTx.wait();
    console.log("Approved subscription contract to spend tokens");
  } else {
    console.log("Sufficient allowance exists, skipping approve");
  }

  // --------------------------
  // 5️⃣ Call subscribe() function
  // --------------------------


  const subscribeTx = await subscription.subscribe(userId, planId, amountToSubscribe);
  const receipt = await subscribeTx.wait();
  console.log("Subscribe tx hash:", receipt?.hash);

  // --------------------------
  // 6️⃣ Parse Subscribed event
  // --------------------------
  const iface = new ethers.Interface([
    "event Subscribed(string userId, string planId, uint256 amount, address assetToken)"
  ]);

  for (const log of receipt.logs) {
    try {
      const parsed = iface.parseLog(log);
      if (parsed.name === "Subscribed") {
        console.log("Subscribed Event:", parsed.args);
      }
    } catch {
      continue;
    }
  }

  console.log("✅ Subscription process completed!");
}

main().catch((err) => {
  console.error("Error in deployment script:", err);
  process.exitCode = 1;
});


// async function main() {
//     const [deployer] = await ethers.getSigners();
//     console.log("Deploying contracts with account:", deployer.address);
  
//     // --------------------------
//     // 1️⃣ Deploy OwnToken
//     // --------------------------
//     const Token = await ethers.getContractFactory("OwnToken");
//     const token = await Token.deploy(
//       "MyToken",               // name
//       "MTK",                   // symbol
//       18,                      // decimals
//       "https://image.url/",    // image URI
//       deployer.address         // initial receiver
//     );
//     console.log("OwnToken deployed at:", token.target);
  
//     // --------------------------
//     // 2️⃣ Deploy SubscriptionManager
//     // --------------------------
//     const Subscription = await ethers.getContractFactory("SubscriptionManager");
//     const subscription = await Subscription.deploy(
//       token.target,          // assetToken
//       deployer.address       // admin
//     );
//     console.log("SubscriptionManager deployed at:", subscription.target);
  
//     // --------------------------
//     // 3️⃣ Approve SubscriptionManager to spend token
//     // --------------------------
//     const amountToSubscribe = ethers.parseUnits("30", 18); // 100 tokens
//     const approveTx = await token.approve(subscription.target, amountToSubscribe);
//     await approveTx.wait();
//     console.log("Approved subscription contract to spend tokens");
  
//     // --------------------------
//     // 4️⃣ Call subscribe() function
//     // --------------------------
//     const userId = "68e8f882574406880f73eb36";
//     const planId = "68d7defb7f1e0775531004d1";
  
//     const subscribeTx = await subscription.subscribe(userId, planId, amountToSubscribe);
//     const receipt = await subscribeTx.wait();
//     console.log("Subscribe tx hash:", receipt?.hash);
  
//     // Optional: parse Subscribed event
//     const iface = new ethers.Interface([
//       "event Subscribed(string userId, string planId, uint256 amount, address assetToken)"
//     ]);
  
//     for (const log of receipt.logs) {
//       try {
//         const parsed = iface.parseLog(log);
//         if (parsed.name === "Subscribed") {
//           console.log("Subscribed Event:", parsed.args);
//         }
//       } catch {
//         continue;
//       }
//     }
  
//     console.log("✅ Subscription completed successfully!");
//   }
  
//   main().catch((err) => {
//     console.error(err);
//     process.exitCode = 1;
//   });