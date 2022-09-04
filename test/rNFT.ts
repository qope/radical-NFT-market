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
    const rate = 100; // 10%
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
      const approveTx = await coin.approve(rnft.address, mintPrice);
      await approveTx.wait();
      await expect(rnft.mint()).not.to.be.reverted;
    });

    it("Should not mint NFT without sufficient founds", async function () {
      const { coin, rnft, mintPrice } = await loadFixture(deployFixture);
      const approveTx = await coin.approve(rnft.address, mintPrice.sub(1));
      await approveTx.wait();
      await expect(rnft.mint()).to.be.reverted;
    });
  });

  // describe("Transfers", function () {
  //   it("Should transfer NFT", async function () {
  //     const { coin, rnft, someone, mintPrice } = await loadFixture(deployFixture);
  //     const approveTx = await coin.approve(rnft.address, mintPrice);
  //     await approveTx.wait();
  //     const mintTx  = await rnft.mint();
  //     await mintTx.wait();
  //     const transferTx = await coin.transfer(someone.address, mintPrice.mul(2));
  //     await transferTx.wait();
  //     const approveTx2 = await coin.approve(someone.address, mintPrice.mul(2));
  //     await approveTx2.wait();
  //     const buyTx = await rnft.connect(someone).buy(0);
  //     await buyTx.wait();
  //     // rnft.connect(someone).buy()
  //   });
  // });
});
