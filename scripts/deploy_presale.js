async function main() {

    const [deployer] = await ethers.getSigners();
      
    console.log("Deploying contracts with the account:",deployer.address); 
    console.log("Account balance before:", (await deployer.getBalance()).toString());
      
    const PresaleFactory = await ethers.getContractFactory("WeentarPresale");
    const tokenAddr = "0x93f63d9455685621aBd73E63cC04f7e454270A66";
    const walletAddr = "0xCd35fa70CD2111985ae6F77c939b516f248e6935";
    const presale = await PresaleFactory.deploy(tokenAddr, walletAddr);
      
    console.log("Presale address:", presale.address);
    console.log("Account balance after:", (await deployer.getBalance()).toString());
    
  }
      
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  