import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { token } from "../typechain-types/@openzeppelin/contracts";

describe("RadicalNFT", function () {
  async function deployFixture() {
    const [owner, someone] = await ethers.getSigners();
    const ownerAddress = owner.address;
    console.log(ownerAddress);

    const mintAmount = BigNumber.from(10).pow(18).mul(100);
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy(ownerAddress, mintAmount);
    const coinAddress = coin.address;

    const cycleDuration = 30; // 30 seconds
    const rate = 80; // 8%
    const mintPrice = BigNumber.from(10).pow(17);
    const maxItemNum = 100;
    const rNFT = await ethers.getContractFactory("RadicalNFT");
    const rnft = await rNFT.deploy(
      "RadicalNFT", 
      "rNFT", 
      coinAddress, 
      cycleDuration, 
      rate, 
      mintPrice, 
      maxItemNum
      );

    return { coin, rnft, owner, someone,  mintAmount, mintPrice};
  }

  describe("Deployment", function () {
    it("Should mint correct amount", async function () {
      const { coin, owner, mintAmount } = await loadFixture(deployFixture);
      expect(await coin.balanceOf(owner.address)).to.equal(mintAmount);
    });
    });
  
  describe("Mint", function () {
    it("Should mint NFT", async function () {
      const { coin, rnft, mintPrice } = await loadFixture(deployFixture);
      expect(await coin.approve(rnft.address, mintPrice)).not.to.be.reverted;
      expect(await rnft.mint()).not.to.be.reverted;
      expect(await rnft.getPrice(0)).to.equal(mintPrice);
    });

    it("Should not mint NFT without sufficient founds", async function () {
      const { coin, rnft, mintPrice } = await loadFixture(deployFixture);
      expect(await coin.approve(rnft.address, mintPrice.sub(1))).not.to.be.reverted;
      await expect(rnft.mint()).to.be.reverted;
    });
  });

  describe("Buy", function () {
    it("Should buy NFT", async function () {
      const { coin, rnft, someone, mintPrice } = await loadFixture(deployFixture);
      expect(await coin.approve(rnft.address, mintPrice)).not.to.be.reverted;
      expect(await rnft.mint()).not.to.be.reverted;
      expect(await coin.transfer(someone.address, mintPrice.mul(2))).not.to.be.reverted;
      expect(await coin.connect(someone).approve(rnft.address, mintPrice.mul(2))).not.to.be.reverted;
      expect(await rnft.connect(someone).buy(0)).not.to.be.reverted;
    });
  });

  describe("Pay tax", function () {
    it("Should pay tax", async function () { 

    } );
  });
});
