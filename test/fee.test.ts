import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { Fee, Fee__factory } from "../typechain-types";

describe("Fee Contract", () => {
  let fee: Fee;
  let owner: any;
  let aiExecutor: any;
  let user: any;
  const NATIVE_TOKEN = ethers.ZeroAddress;

  beforeEach(async () => {
    [owner, aiExecutor, user] = await ethers.getSigners();

    const FeeFactory = (await ethers.getContractFactory("Fee", owner)) as Fee__factory;

    fee = await upgrades.deployProxy(FeeFactory, [owner.address, owner.address], {
      initializer: "__Fee_init",
    });

    await fee.waitForDeployment();
  });

  it("should initialize properly", async () => {
    expect(await fee.feeRecipient()).to.equal(owner.address);
    expect(await fee.feeAmountTickSpacing(500)).to.equal(10);
    expect(await fee.feeAmountTickSpacing(1000)).to.equal(20);
    expect(await fee.feeAmountTickSpacing(2000)).to.equal(30);
  });

  it("should set AI executor by owner", async () => {
    await fee.setAIExecutor(aiExecutor.address);
    expect(await fee.aiExecutor()).to.equal(aiExecutor.address);
  });

  it("should revert if non-owner tries to set AI executor", async () => {
    await expect(fee.connect(user).setAIExecutor(user.address)).to.be.revertedWithCustomError(fee,'OwnableUnauthorizedAccount');
  });

  it("should estimate fee correctly for ERC20 token", async () => {
    const amount = ethers.parseEther("1000"); // 1000 tokens
    const feeValue = await fee.estimateFee(user.address, "0x1111111111111111111111111111111111111111", amount);
    expect(feeValue).to.equal((amount * 10n) / 10_000n);
  });

  it("should return fixed fee for native token", async () => {
    const feeValue = await fee.estimateFee(user.address, NATIVE_TOKEN, ethers.parseEther("1"));
    expect(feeValue).to.equal(ethers.parseEther("0.001"));
  });

  it("should allow only AI executor to call collectFee", async () => {
    const amount = ethers.parseEther("1000");
    await fee.setAIExecutor(aiExecutor.address);

    const feeValue = await fee.connect(aiExecutor).collectFee.staticCall(user.address, "0x1111111111111111111111111111111111111111", amount);
    console.log('feeValue',feeValue)
    expect(feeValue).to.equal((amount * 10n) / 10_000n);
  });

  it("should revert collectFee if called by non AI executor", async () => {
    const amount = ethers.parseEther("1000");
    await expect(
      fee.connect(user).collectFee(user.address, user.address, amount)
    ).to.be.revertedWith("Caller is not the AI Executor");
  });

  it("should increment user nonce correctly", async () => {
    await fee.setAIExecutor(aiExecutor.address);
    await fee.connect(aiExecutor).updateUserNonce(user.address);

    const nonce = await fee.userNonce(user.address);
    expect(nonce).to.equal(1);
  });

  it("should collect native token in receive()", async () => {
    const value = ethers.parseEther("0.1");
    await owner.sendTransaction({ to: await fee.getAddress(), value });

    const collected = await fee.feesCollected(NATIVE_TOKEN);
    expect(collected).to.equal(value);
  });
});
