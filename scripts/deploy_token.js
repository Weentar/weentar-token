async function main() {

  const [deployer] = await ethers.getSigners();
    
  console.log("Deploying contracts with the account:",deployer.address); 
  console.log("Account balance before:", (await deployer.getBalance()).toString());
    
  const TokenFactory = await ethers.getContractFactory("WeentarToken");
  const token = await TokenFactory.deploy("3000000000"+"0".repeat(18));
    
  console.log("Token address:", token.address);
  console.log("Account balance after:", (await deployer.getBalance()).toString());
  
}
    
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
