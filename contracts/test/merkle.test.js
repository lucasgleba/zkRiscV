const { ethers } = require("hardhat");
// const { expect } = require("chai");

const testBytes32 =
  "0x1111111111111111111111111111111111111111111111111111111111111111";
const testUint256 = 1;

describe("Merkle contract", function () {
  it("test", async () => {
    const contract = await ethers.getContractFactory("TestMerkle");
    const liveContract = await contract.deploy();
    const len = 100;
    await liveContract.testMerkle_old(
      new Array(len).fill(testBytes32),
      new Array(len).fill(testUint256)
    );
    await liveContract.testMerkle(
      new Array(len).fill(testBytes32),
      testUint256
    );
  });
});
