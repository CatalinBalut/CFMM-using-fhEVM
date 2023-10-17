import { expect } from "chai";
import { ethers } from "hardhat";

import { deployEncryptedERC20Fixture } from "../encryptedERC20/EncryptedERC20.fixture";
import { createInstances } from "../instance";
import { getSigners } from "../signers";
import { createTransaction } from "../utils";
import { deployEncryptedCFMMv1Fixture } from "./EncryptedCFMMv1.fixture";

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

    const CFMM = await deployEncryptedCFMMv1Fixture(this.contractAddressERC20A, this.contractAddressERC20B);
    this.contractAddressCFMMv1 = await CFMM.getAddress();
    this.cfmmv1 = CFMM;

    this.instancesERC20A = await createInstances(this.contractAddressERC20A, ethers, this.signers);
    // this.instancesERC20B = await createInstances(this.contractAddressERC20B, ethers, this.signers);
    this.instancesCFMMv1 = await createInstances(this.contractAddressCFMMv1, ethers, this.signers);
  });

  it("should mint the erc20 contract", async function () {
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

    await createTransaction(this.erc20A.approve, this.contractAddressCFMMv1, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMMv1, encryptedAmount);

    const transaction = await createTransaction(this.cfmmv1.addLiquidity, encryptedAmount, encryptedAmount);
    await transaction.wait();

    // Call the method
    const token = this.instancesCFMMv1.alice.getTokenSignature(this.contractAddressCFMMv1) || {
      signature: "",
      publicKey: "",
    };
    const encryptedBalance = await this.cfmmv1.balanceOf(token.publicKey, token.signature);
    // Decrypt the balance
    const balance = this.instancesCFMMv1.alice.decrypt(this.contractAddressCFMMv1, encryptedBalance);
    expect(balance).to.equal(25_000_000);

    const encryptedTotalSupply = await this.cfmmv1.getTotalSupply(token.publicKey, token.signature);
    // Decrypt the total supply
    const totalSupply = this.instancesCFMMv1.alice.decrypt(this.contractAddressCFMMv1, encryptedTotalSupply);
    expect(totalSupply).to.equal(25_000_000);
  });

  it("should do a swap:", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(50000);
    const encryptedLiquidityAmount = this.instancesERC20A.alice.encrypt32(5000);
    const encryptedSwapAmount = this.instancesERC20A.alice.encrypt32(700);
    await createTransaction(this.erc20A.mint, encryptedLiquidityAmount);
    await createTransaction(this.erc20B.mint, encryptedLiquidityAmount);

    await createTransaction(this.erc20A.approve, this.contractAddressCFMMv1, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMMv1, encryptedAmount);

    const transaction = await createTransaction(
      this.cfmmv1.addLiquidity,
      encryptedLiquidityAmount,
      encryptedLiquidityAmount,
    );
    await transaction.wait();

    const tx = await createTransaction(this.cfmmv1.swap, this.contractAddressERC20A, encryptedSwapAmount);
    await tx.wait();
    // Call the method
    // const token = this.instancesCFMMv1.alice.getTokenSignature(this.contractAddressCFMMv1) || {
    //   signature: "",
    //   publicKey: "",
    // };
    // const encryptedReserveBalance = await this.cfmmv1.getReserve(
    //   token.publicKey,
    //   token.signature,
    //   this.contractAddressERC20A,
    // );
    // // Decrypt the balance
    // const balance = this.instancesCFMMv1.alice.decrypt(this.contractAddressCFMMv1, encryptedReserveBalance);
    // // expect(balance).to.equal(25_000_000); //25_000_000
    // console.log(balance);
  });
});
