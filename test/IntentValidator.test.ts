//帮我写个 IntentValidator 的单元测试
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers, toTwos } from "ethers";

describe('IntentValidator', () => {

    async function deoployIntentValidator() {
        const [deployer] = await hre.ethers.getSigners();
        const IntentValidator = await hre.ethers.deployContract("IntentValidator", [deployer.address]);

        const mockUsdt = await hre.ethers.deployContract("MockUSDT", [1000]);
        return { IntentValidator, deployer, mockUsdt };
    }

    it("should deploy successfully", async () => {
        const { IntentValidator, deployer } = await loadFixture(deoployIntentValidator);

        const owner = await IntentValidator.owner();
        expect(owner).to.equal(deployer.address);
    });

    it('should validate intent correctly swap eth to any', async () => {
        const { IntentValidator } = await loadFixture(deoployIntentValidator);
        const chainId = 1;
        const swapIntent = {
            intent: "swap",
            platform: "Uniswap",
            fromToken: ethers.ZeroAddress, // ETh
            toToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
            amount: 18,
            chainId: chainId,
        }
        const result = await IntentValidator.validate(swapIntent);
        console.log(result);
        expect(result[0]).to.be.true;
        expect(result[1]).to.equal(2);
    });


    it('should validate intent INSUFFICIENT_BALANCE swap usdt to any', async () => {
        const { IntentValidator, mockUsdt } = await loadFixture(deoployIntentValidator);
        const chainId = 1;
        const swapIntent = {
            intent: "swap",
            platform: "Uniswap",
            fromToken: mockUsdt.target, // USDT
            toToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
            amount: 9000000000000,
            chainId: chainId,
        }
        // await mockUsdt.mint();
        const result = await IntentValidator.validate(swapIntent);
        expect(result[0]).to.be.false;
        expect(result[1]).to.equal(0);
    });

    it('should validate intent ALLOWANCE_NOT_ENOUGH swap usdt to any', async () => {
        const { IntentValidator, mockUsdt } = await loadFixture(deoployIntentValidator);
        const chainId = 1;
        const swapIntent = {
            intent: "swap",
            platform: "Uniswap",
            fromToken: mockUsdt.target, // USDT
            toToken: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
            amount: 10,
            chainId: chainId,
        }
        await mockUsdt.mint();
        const result = await IntentValidator.validate(swapIntent);
        expect(result[0]).to.be.false;
        expect(result[1]).to.equal(1);
    });


});


