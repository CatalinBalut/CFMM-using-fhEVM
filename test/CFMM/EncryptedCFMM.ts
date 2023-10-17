import { expect } from "chai";
import { ethers } from "hardhat";

import { deployEncryptedERC20Fixture } from "../encryptedERC20/EncryptedERC20.fixture";
import { createInstances } from "../instance";
import { getSigners } from "../signers";
import { createTransaction } from "../utils";
import { deployEncryptedCFMMFixture } from "./EncryptedCFMM.fixture";

describe.only("EncryptedCFMM tests", function () {
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
    this.instancesCFMM = await createInstances(this.contractAddressCFMM, ethers, this.signers);
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
    expect(balance).to.equal(5000);

    const encryptedTotalSupply = await this.cfmm.getTotalSupply(token.publicKey, token.signature);
    // Decrypt the total supply
    const totalSupply = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedTotalSupply);
    expect(totalSupply).to.equal(5000);

    const encryptedReserveBalanceA = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20A,
    );
    // Decrypt the balance
    const reservaA = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceA);
    expect(reservaA).to.equal(5000);

    const encryptedReserveBalanceB = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20B,
    );
    // Decrypt the balance
    const reservaB = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceB);
    expect(reservaB).to.equal(5000);
  });

  it("should do a swap:", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(50000);
    const encryptedLiquidityAmount = this.instancesERC20A.alice.encrypt32(5000);
    const encryptedSwapAmount = this.instancesERC20A.alice.encrypt32(700);
    const expectedReserveA = 5700;
    const expectedReserveB = 4386;
    const expectedBalance = 5000;

    await createTransaction(this.erc20A.mint, encryptedAmount);
    await createTransaction(this.erc20B.mint, encryptedAmount);

    await createTransaction(this.erc20A.approve, this.contractAddressCFMM, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMM, encryptedAmount);

    const transaction1 = await createTransaction(
      this.cfmm.addLiquidity,
      encryptedLiquidityAmount,
      encryptedLiquidityAmount,
    );
    await transaction1.wait();

    const transaction2 = await createTransaction(this.cfmm.swap, this.contractAddressERC20A, encryptedSwapAmount);
    await transaction2.wait();

    const token = this.instancesCFMM.alice.getTokenSignature(this.contractAddressCFMM) || {
      signature: "",
      publicKey: "",
    };

    const encryptedReserveBalanceA = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20A,
    );
    const reserveA = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceA);
    expect(reserveA).to.be.equal(expectedReserveA);

    const encryptedReserveBalanceB = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20B,
    );
    const reserveB = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceB);
    expect(reserveB).to.be.equal(expectedReserveB);

    const encryptedBalance = await this.cfmm.balanceOf(token.publicKey, token.signature);
    const balance = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedBalance);
    expect(balance).to.be.equal(expectedBalance);
  });

  it("should remove Liquidity:", async function () {
    const encryptedAmount = this.instancesERC20A.alice.encrypt32(50000);
    const encryptedLiquidityAmount = this.instancesERC20A.alice.encrypt32(5000);
    const encryptedSharesAmount = this.instancesERC20A.alice.encrypt32(2500);
    const expectedReserveA = 2500;
    const expectedReserveB = 2500;
    const expectedBalance = 2500;

    await createTransaction(this.erc20A.mint, encryptedAmount);
    await createTransaction(this.erc20B.mint, encryptedAmount);

    await createTransaction(this.erc20A.approve, this.contractAddressCFMM, encryptedAmount);
    await createTransaction(this.erc20B.approve, this.contractAddressCFMM, encryptedAmount);

    const tx1 = await createTransaction(this.cfmm.addLiquidity, encryptedLiquidityAmount, encryptedLiquidityAmount);
    await tx1.wait();

    const token = this.instancesCFMM.alice.getTokenSignature(this.contractAddressCFMM) || {
      signature: "",
      publicKey: "",
    };

    const tx2 = await createTransaction(this.cfmm.removeLiquidity, encryptedSharesAmount);
    await tx2.wait();

    const encryptedReserveBalanceA = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20A,
    );
    const reserveA = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceA);
    expect(reserveA).to.be.equal(expectedReserveA);

    const encryptedReserveBalanceB = await this.cfmm.getReserve(
      token.publicKey,
      token.signature,
      this.contractAddressERC20B,
    );
    const reserveB = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedReserveBalanceB);
    expect(reserveB).to.be.equal(expectedReserveB);

    const encryptedBalance = await this.cfmm.balanceOf(token.publicKey, token.signature);
    const balance = this.instancesCFMM.alice.decrypt(this.contractAddressCFMM, encryptedBalance);
    expect(balance).to.be.equal(expectedBalance);
  });
});
