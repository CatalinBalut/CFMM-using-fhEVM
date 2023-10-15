import { ethers } from "hardhat";

import type { EncryptedCFMM } from "../../types";
import { getSigners } from "../signers";

export async function deployEncryptedCFMMFixture(erc20A: string, erc20B: string): Promise<EncryptedCFMM> {
  const signers = await getSigners(ethers);

  const contractFactory = await ethers.getContractFactory("EncryptedCFMM");
  const contract = await contractFactory.connect(signers.alice).deploy(erc20A, erc20B);
  await contract.waitForDeployment();

  return contract;
}
