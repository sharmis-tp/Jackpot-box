// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import "dotenv/config";

const ENTROPY_CONTRACT_ADDRESS = process.env.ENTROPY_CONTRACT_ADDRESS;
console.log("ENTROPY_CONTRACT_ADDRESS", ENTROPY_CONTRACT_ADDRESS);
if (!ENTROPY_CONTRACT_ADDRESS) {
  throw new Error("ENTROPY_CONTRACT_ADDRESS env variable must be set");
}

const JackpotboxModule = buildModule("JackpotboxModule", (m) => {
  const JackpotboxContract = m.contract("Jackpotbox", [ENTROPY_CONTRACT_ADDRESS]);

  return { JackpotboxContract };
});

export default JackpotboxModule;