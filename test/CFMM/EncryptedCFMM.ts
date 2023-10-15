import { expect } from "chai";
import { ethers } from "hardhat";

import { deployEncryptedERC20Fixture } from "../encryptedERC20/EncryptedERC20.fixture";
import { createInstances } from "../instance";
import { getSigners } from "../signers";
import { createTransaction } from "../utils";
import { deployEncryptedCFMMFixture } from "./EncryptedCFMM.fixture";

describe("EncryptedCFMM", function () {
  before(async function () {
    this.signers = await getSigners(ethers);
  });

  beforeEach(async function () {
    const ERC20A = await deployEncryptedERC20Fixture();
    this.contractAddressERC20A = await ERC20A.getAddress();
    this.erc20A = ERC20A;

    const ERC20B = await deployEncryptedERC20Fixture();
    this.contractAddressERC20B = await ERC20B.getAddress();
    this.erc20B = ERC20B;

    const CFMM = await deployEncryptedCFMMFixture(this.contractAddressERC20A, this.contractAddressERC20B);
    this.contractAddressCFMM = await CFMM.getAddress();
    this.cfmm = CFMM;

    this.instancesERC20A = await createInstances(this.contractAddressERC20A, ethers, this.signers);
    // this.instancesERC20B = await createInstances(this.contractAddressERC20B, ethers, this.signers);
    this.instancesCFMM = await createInstances(this.contractAddressCFMM, ethers, this.signers);
  });

  it("should mint the contract", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(1000);
    const transaction = await createTransaction(this.erc20A.mint, encryptedAmount);
    await transaction.wait();
    // Call the method
    const token = this.instancesERC20A.alice.getTokenSignature(this.contractAddressERC20A) || {
      signature: "",
      publicKey: "",
    };
    const encryptedBalance = await this.erc20A.balanceOf(token.publicKey, token.signature);
    // Decrypt the balance
    const balance = this.instancesERC20A.alice.decrypt(this.contractAddressERC20A, encryptedBalance);
    expect(balance).to.equal(1000);

    const encryptedTotalSupply = await this.erc20A.getTotalSupply(token.publicKey, token.signature);
    // Decrypt the total supply
    const totalSupply = this.instancesERC20A.alice.decrypt(this.contractAddressERC20A, encryptedTotalSupply);
    expect(totalSupply).to.equal(1000);
  });

  it("should add liquidity", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(5000);
    await createTransaction(this.erc20A.mint, encryptedAmount);
    await createTransaction(this.erc20B.mint, encryptedAmount);

    await createTransaction(this.erc20A.approve, this.contractAddressCFMM, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMM, encryptedAmount);

    const transaction = await createTransaction(this.cfmm.addLiquidity, encryptedAmount, encryptedAmount);
    await transaction.wait();

    // Call the method
    const token = this.instancesCFMM.alice.getTokenSignature(this.contractAddressCFMM) || {
      signature: "",
      publicKey: "",
    };
    const encryptedBalance = await this.cfmm.balanceOf(token.publicKey, token.signature);
    // Decrypt the balance
    const balance = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedBalance);
    expect(balance).to.equal(5000); //25_000_000

    const encryptedTotalSupply = await this.cfmm.getTotalSupply(token.publicKey, token.signature);
    // Decrypt the total supply
    const totalSupply = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedTotalSupply);
    expect(totalSupply).to.equal(5000);
  });

  it("should do a swap:", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(1);
    await createTransaction(this.erc20A.mint, encryptedAmount);
    await createTransaction(this.erc20B.mint, encryptedAmount);

    await createTransaction(this.erc20A.approve, this.contractAddressCFMM, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMM, encryptedAmount);

    const transaction = await createTransaction(this.cfmm.addLiquidity, encryptedAmount, encryptedAmount);
    await transaction.wait();

    await createTransaction(this.cfmm.swap, this.contractAddressERC20A, encryptedAmount);

    // // Call the method
    // const token = this.instancesCFMM.alice.getTokenSignature(this.contractAddressCFMM) || {
    //   signature: "",
    //   publicKey: "",
    // };
    // const encryptedBalance = await this.cfmm.balanceOf(token.publicKey, token.signature);
    // // Decrypt the balance
    // const balance = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedBalance);
    // expect(balance).to.equal(5000); //25_000_000
  });
});
