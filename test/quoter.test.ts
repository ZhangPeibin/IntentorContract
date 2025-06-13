import hre, { ethers } from "hardhat";
import { expect } from "chai";


describe('Quoter'  , () => {        

    async function deployQuoter() {
        const [deployer] = await hre.ethers.getSigners();
        const Quoter = await hre.ethers.deployContract("Quoter", [deployer.address]);
        return { Quoter, deployer };
    }   

    it("should deploy successfully", async () => {
        const { Quoter, deployer } = await deployQuoter();
        const owner = await Quoter.owner();
        expect(owner).to.equal(deployer.address);
    });

    it("should add a quote", async () => {
        const { Quoter ,deployer } = await deployQuoter();
        const quoter = await Quoter.quoterFromDex('uni');
        expect(quoter).to.equal(ethers.ZeroAddress); 
        await Quoter.updateQuoter('uni', deployer.address);
        const updatedQuoter = await Quoter.quoterFromDex('uni');
        expect(updatedQuoter).to.equal(deployer.address);
    });

    it('should revert when trying to add a quote with zero address', async () => {
        const { Quoter } = await deployQuoter();
        await expect(Quoter.updateQuoter('uni', ethers.ZeroAddress)).to.be.revertedWith("Quoter address cannot be zero");
    });
    it('should revert when trying to add a quote with empty string', async () => {  
        const { Quoter } = await deployQuoter();
        await expect(Quoter.updateQuoter('', ethers.ZeroAddress)).to.be.revertedWith("Dex  cannot be zero");
    });
    
});