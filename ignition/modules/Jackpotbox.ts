// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const JackpotboxModule = buildModule("JackpotboxModule", (m) => {
  const JackpotboxContract = m.contract("Jackpotbox", []);

  return { JackpotboxContract };
});

export default JackpotboxModule;