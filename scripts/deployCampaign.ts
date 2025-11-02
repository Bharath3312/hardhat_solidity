import { network } from "hardhat";

const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});



const [admin,user1,user2,user3] = await ethers.getSigners();
console.log(admin.address, "deployer address");

  async function deployCampaignContract() {
    const factoryContract = await ethers.getContractFactory("CampaignFactory");
    const CampaignFactory = await factoryContract.deploy( );
    await CampaignFactory.waitForDeployment();
    console.log("✅ Campaign Factory Contract :", await CampaignFactory.getAddress());

  }

  async function CampaignFactoryContract(factoryAddress:string,user?:any) {
    console.log(user,"user sender");
    
      const CampaignFactory = await ethers.getContractAt("CampaignFactory",factoryAddress ,user);
      return CampaignFactory
  }

  async function createCampaign(factoryAddress:string,user:number) {
      const CampaignFactory = await CampaignFactoryContract(factoryAddress,user === 1 ? user1 : user === 2 ? user2 : admin);
       const tx =  await CampaignFactory.createCampaign(
        "My second Campaign",              // title
        "This is a test crowdfunding",    // description
        "https://example.com/img.png",    // image URL
        "https://example.com/doc.pdf",    // pdf URL
        1,                               // minAmount
        20,                             // maxAmount
        0,                                // fundingType (0 = AllOrNothing)
        Math.floor(Date.now() / 1000) + 86400, // deadline = 24 hrs from now
      );
      const receipt = await tx.wait();
      let campaignAddress:string = receipt.logs.find((log:any) => CampaignFactory?.interface.parseLog(log)?.name === "CampaignCreated")?.args[0]
      console.log(campaignAddress,"Newcampaignaddress");
  }

  async function totalCampaign(factoryAddress:string) {
      const CampaignFactory = await CampaignFactoryContract(factoryAddress);
      const totalInvested = await CampaignFactory.getAllCampaigns();
      console.log("Total Invested so far Address:", totalInvested);
  }

  async function campaignData(campaignAddress:string) {
      const campaignContract = await ethers.getContractAt("Campaign",campaignAddress);
      const campaignData = await campaignContract.campaign();
      console.log("Campaign data:", campaignData);
  }

  async function investInCampaign(campaignAddress:string,amount:number,Signer?:number) {
      // try {
        console.log(BigInt(amount),"amount");
        
        const campaignContract = await ethers.getContractAt("Campaign",campaignAddress,Signer === 1 ? user1 : Signer === 2 ? user2 : admin);
        const investAmt = await campaignContract.invest({value: BigInt(amount)});
        const campaignReceipt = await investAmt.wait();
        console.log(campaignReceipt,"Invested");
      // } catch (error) {
      //   console.log(error,"error");
        
      // }
  }
  const factoryAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3" //deployed factory address
// await deployCampaignContract() //0x5FbDB2315678afecb367f032d93F642f64180aa3;

// await createCampaign(factoryAddress,1) // pass factory address

// await totalCampaign(factoryAddress);

const  campaignDatas:string[] =[
  "0xa16E02E87b7454126E5E10d957A927A7F5B5d2be","0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968","0xeEBe00Ac0756308ac4AaBfD76c05c4F3088B8883"
]
await campaignData(campaignDatas[0]); // pass campaign address


// await investInCampaign(campaignDatas[0],10 ,2) // pass campaign address and amount to invest