import express from "express";
import { ethers } from "ethers";
import wallet from "./utils/signer.js";
import dotenv from "dotenv";
dotenv.config();

const app = express();
app.use(express.json());

const CONTRACT_ABI = [
  "event DiceRolled(bytes32 indexed requestId, address indexed roller)",
  "event DiceLanded(bytes32 indexed requestId, uint256 result)",
  "function fulfillRandomness(bytes32 requestId, uint256 random, bytes signature) external",
];

const contract = new ethers.Contract(
  process.env.CONTRACT_ADDRESS,
  CONTRACT_ABI,
  wallet
);

// 🎧 Listen for requests
contract.on("DiceRolled", async (requestId, player) => {
  console.log(`➡️ DiceRolled requested by ${player} [ID: ${requestId}]`);

  // 1. Generate secure random number
  const randomBytes = ethers.randomBytes(32);
  const random = ethers.toBigInt(randomBytes);

  // 2. Create message hash
  const messageHash = ethers.hashMessage(
    ethers.solidityPacked(["bytes32", "uint256"], [requestId, random])
  );

  // 3. Sign the hash
  const signature = await wallet.signMessage(ethers.getBytes(messageHash));

  // 4. Call fulfillRandomness
  try {
    const tx = await contract.fulfillRandomness(requestId, random, signature);
    await tx.wait();
    console.log(`✅ Fulfilled randomness for ${player} with tx: ${tx.hash}`);
  } catch (err) {
    console.error(`❌ Error fulfilling randomness:`, err);
  }
});

app.get("/", (req, res) => {
  res.send("Jackpot Oracle is running.");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🟢 Oracle server running on port ${PORT}`));
