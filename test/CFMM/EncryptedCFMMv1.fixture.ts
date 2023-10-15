import { ethers } from "hardhat";

import type { EncryptedCFMMv1 } from "../../types";
import { getSigners } from "../signers";

export async function deployEncryptedCFMMv1Fixture(erc20A: string, erc20B: string): Promise<EncryptedCFMMv1> {
  const signers = await getSigners(ethers);

  const contractFactory = await ethers.getContractFactory("EncryptedCFMMv1");
  const contract = await contractFactory.connect(signers.alice).deploy(erc20A, erc20B);
  await contract.waitForDeployment();
  return contract;
}
