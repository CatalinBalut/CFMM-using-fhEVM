import type { FhevmInstance } from "fhevmjs";

import { EncryptedCFMM, EncryptedCFMMv1, EncryptedERC20 } from "../types";
import type { Signers } from "./signers";

declare module "mocha" {
  export interface Context {
    signers: Signers;
    contractAddressERC20A: string;
    contractAddressERC20B: string;
    contractAddressCFMMv1: string;
    contractAddressCFMM: string;
    instancesERC20: FhevmInstances;
    instancesCFMMv1: FhevmInstances;
    instancesCFMM: FhevmInstances;
    erc20A: EncryptedERC20;
    erc20B: EncryptedERC20;
    cfmmv1: EncryptedCFMMv1;
    cfmm: EncryptedCFMM;
  }
}

export interface FhevmInstances {
  alice: FhevmInstance;
  bob: FhevmInstance;
  carol: FhevmInstance;
  dave: FhevmInstance;
}
