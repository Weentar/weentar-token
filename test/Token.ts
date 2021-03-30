const { ethers } = require("hardhat");
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { WeentarToken } from "../typechain";
import { BigNumber } from "ethers";
const { waffle } = require("hardhat");
const provider = waffle.provider;

chai.use(solidity);
const { expect } = chai;


describe("Token ", () => {

    let token: WeentarToken;
    let accounts: any;
    let owner: any;
    let admin: any;

    before(async () => {
        accounts = await ethers.getSigners();
        owner = accounts[0];
        admin = accounts[1];
        const hundretBillion: BigNumber = ethers.utils.parseEther("100000000000");
        const thirtyBillion: BigNumber = ethers.utils.parseEther("30000000000");
        const tokenFactory = await ethers.getContractFactory("WeentarToken", owner);
        token = (await tokenFactory.deploy(hundretBillion)) as WeentarToken;
        await token.deployed();

        expect(await token.name()).to.eq("Weentar Token");
        expect(await token.symbol()).to.eq("$WNTR");
        expect(await token.owner()).to.eq(owner.address);
        expect(await token.decimals()).to.eq(18);
        expect(await token.totalSupply()).to.eq(thirtyBillion);

        await token.connect(owner).transfer(accounts[3].address, 100);
        await token.connect(owner).transfer(accounts[4].address, 100);

    });

    describe("set admin", async () => {

        it("invalid admin set", async () => {

            // onlyOwner check
            await expect(token.connect(admin).setAdmin(admin.address)).to.be.revertedWith("Ownable: caller is not the owner");
               
           
        });

        it("valid admin set", async () => {

            // valid transaction
             await token.connect(owner).setAdmin(admin.address);
           

            //checking admin address
            expect(await token.getAdmin()).to.equal(admin.address);   
           
        });

    
    });

    describe("set start timestamp", async () => {

        it("invalid start timestamp ", async () => {
            await provider.send("evm_increaseTime", [86400000])
            await provider.send("evm_mine")

            // onlyAdmin check
            await expect( token.connect(owner).setStartTimestamp()).to.be.revertedWith("WeentarToken: Caller is not the admin");     
           
        });

        it("valid start timestamp ", async () => {

            // valid transaction
            await token.connect(admin).setStartTimestamp();
            await expect( token.connect(admin).setStartTimestamp()).to.be.revertedWith("WeentarToken: Tokens already being minted");

           
        });

    
    });

    

    describe("minting Weentar Tokens ", async () => {

        

        it("invalid mint by not authorized address", async () => {
            // onlyAdmin check
           await expect( token.connect(owner).mint()).to.be.revertedWith("WeentarToken: Caller is not the admin");   
    
        });

        it("valid mint by admin", async () => {
          
            await token.connect(admin).mint();  
            // Day hasn't advanced so no minting
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("0")); 

            // Increasing timestamp by a day
            await provider.send("evm_increaseTime", [86400])
            await provider.send("evm_mine")

            await token.connect(admin).mint();  
            expect( await token.getDay()).to.eq(1);
            // Day advanced so minted equivalent amount for Day 1
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("100000000000000000000000000"));

        });

    });


   



});