import { ethers } from "hardhat";
import { BigNumber } from "ethers";

async function main() {
  const [owner] = await ethers.getSigners();
  const ownerAddress = owner.address;
  console.log(ownerAddress);

  const mintAmount = BigNumber.from(10).pow(18).mul(100);
  const Coin = await ethers.getContractFactory("Coin");
  const coin = await Coin.deploy(ownerAddress, mintAmount);
  await coin.deployed();
  const coinAddress = coin.address;

  const oneDay = BigNumber.from(60*60*24); // 1 day
  const cycleDuration = oneDay.mul(100); // 100 day 
  const rate = 100; // 10%
  const mintPrice = BigNumber.from(10).pow(18);
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
  await rnft.deployed();
  console.log(`Coin deployed to ${coin.address}\nrNFT deployed to ${rnft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
