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

        

        it("invalid mint by unauthorized address", async () => {
            // onlyAdmin check
           await expect( token.connect(owner).mint()).to.be.revertedWith("WeentarToken: Caller is not the admin");   
    
        });

        it("valid mint by admin", async () => {
          
            await token.connect(admin).mint();  
            // Day hasn't advanced so no minting
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("0")); 

            // Increasing timestamp by a day
            await provider.send("evm_increaseTime", [86400]);
            await provider.send("evm_mine");

            await token.connect(admin).mint();  
            expect( await token.getDay()).to.eq(1);
            // Day advanced so minted 10 M tokens for Day 1
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("100000000000000000000000000"));

        });

    });

    describe("testing minting schedule ", async () => {

        it("valid mint by admin", async () => {
          
           // Setting current day to 91
            await provider.send("evm_increaseTime", [86400*90]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(91);

            // Setting _day variable to 90
            await token.connect(admin).setDay(90); 

            // 5 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("150000000000000000000000000")); 
            expect( await token.getDay()).to.eq(91);

            // No tokens minted as _day equals current day
            await token.connect(admin).mint(); 

            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("150000000000000000000000000"));
            expect( await token.getDay()).to.eq(91);
          
            

        });

        it("valid mint for missed days", async () => {
          
            // Setting current day to 94
            await provider.send("evm_increaseTime", [86400*3]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(94);
        
            // 5 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("200000000000000000000000000")); 
            expect( await token.getDay()).to.eq(92);

            // 5 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("250000000000000000000000000")); 
            expect( await token.getDay()).to.eq(93);

            // 5 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("300000000000000000000000000")); 
            expect( await token.getDay()).to.eq(94);

            // No tokens minted as _day equals current day
            await token.connect(admin).mint(); 

            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("300000000000000000000000000"));
            expect( await token.getDay()).to.eq(94);
             
 
         });

         it("valid token distribution according to schedule", async () => {
          
            // Setting current day to 366 (Year 2)
            await provider.send("evm_increaseTime", [86400*272]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(366);

            // Setting _day variable to 365
            await token.connect(admin).setDay(365); 

            // 4 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("340000000000000000000000000")); 
            expect( await token.getDay()).to.eq(366);

            // Setting current day to 731 (Year 3)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(731);

            // Setting _day variable to 730
            await token.connect(admin).setDay(730); 

            // 3 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("370000000000000000000000000")); 
            expect( await token.getDay()).to.eq(731);

            // Setting current day to 1096 (Year 4)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(1096);

            // Setting _day variable to 1095
            await token.connect(admin).setDay(1095); 

            // 2 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("390000000000000000000000000")); 
            expect( await token.getDay()).to.eq(1096);

            // Setting current day to 1461 (Year 5)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(1461);

            // Setting _day variable to 1460
            await token.connect(admin).setDay(1460); 

            // 1 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("400000000000000000000000000")); 
            expect( await token.getDay()).to.eq(1461);

            // Setting current day to 1826 (Year 6)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(1826);

            // Setting _day variable to 1825
            await token.connect(admin).setDay(1825); 

            // 1 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("410000000000000000000000000")); 
            expect( await token.getDay()).to.eq(1826);

            // Setting current day to 2191 (Year 7)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(2191);

            // Setting _day variable to 2190
            await token.connect(admin).setDay(2190); 

            // 1 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("420000000000000000000000000")); 
            expect( await token.getDay()).to.eq(2191);

            // Setting current day to 2556 (Year 8)
            await provider.send("evm_increaseTime", [86400*365]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(2556);

            // Setting _day variable to 2555
            await token.connect(admin).setDay(2555); 

            // 1 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("430000000000000000000000000")); 
            expect( await token.getDay()).to.eq(2556);

            // Setting current day to 2901 (where minting stops)
            await provider.send("evm_increaseTime", [86400*345]);
            await provider.send("evm_mine");
            expect( await token.getCurrentDay()).to.eq(2901);

            // Setting _day variable to 2900
            await token.connect(admin).setDay(2900); 

            // 1 M tokens minted as scheduled and _day increased by 1
            await token.connect(admin).mint(); 
            expect( await token.balanceOf(admin.address)).to.eq( BigNumber.from("430000000000000000000000000")); 
            expect( await token.getDay()).to.eq(2901);

            
             
 
         });

    });


   



});