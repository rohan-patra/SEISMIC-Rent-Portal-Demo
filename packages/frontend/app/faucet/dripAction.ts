"use server";

import { USDYContract } from "@/lib/contracts";
import {
  createShieldedWalletClient,
  getShieldedContract,
  seismicDevnet,
  shieldedWriteContract
} from "seismic-viem";
import { http, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";

export async function drip(address: `0x${string}`, rawAmount: number) {
  // as long as the private key has the MINTER role it can mint
  const walletClient = await createShieldedWalletClient({
    chain: seismicDevnet,
    transport: http(process.env.NEXT_PUBLIC_SEISMIC_RPC_URL!),
    account: privateKeyToAccount(
      process.env.FAUCET_PRIVATE_KEY as `0x${string}`,
    ),
  });


  // convert to wei
  const amount = parseEther(rawAmount.toString());

  shieldedWriteContract(walletClient, {
    address: USDYContract.address,
    abi: USDYContract.abi,
    functionName: "mint",
    args: [address, amount],
    gas: BigInt(10000000000),
  });

//   const contract = getShieldedContract({
//     address: USDYContract.address,
//     abi: USDYContract.abi,
//     client: walletClient,
//   });

//   contract.write.mint([address, amount], {
//     gas: 1000000,
//   });
}
