import { ethers } from "hardhat";

async function main() {
  const NFT = await ethers.getContractFactory("RadicalNFT");
  const nft = await NFT.deploy("RadicalNFT", "rNFT");

  await nft.deployed();

  // console.log(`Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
