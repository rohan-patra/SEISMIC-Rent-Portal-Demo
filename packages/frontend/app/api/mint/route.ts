import { NextRequest, NextResponse } from "next/server";
import {
  type ShieldedWalletClient,
  createShieldedWalletClient,
  getShieldedContract,
} from "seismic-viem";
import { Abi, Address, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { USDYContract } from "@/lib/contracts";
import { seismicDevnet } from "@/lib/chain";

async function getShieldedContractWithCheck(
  walletClient: ShieldedWalletClient,
  abi: Abi,
  address: Address
) {
  const contract = getShieldedContract({
    abi,
    address,
    client: walletClient,
  });

  const code = await walletClient.getCode({
    address,
  });
  if (!code) {
    throw new Error("Please deploy contract before running this script.");
  }

  return contract;
}

// Amount of USDY to mint (100 tokens with 18 decimals)
const MINT_AMOUNT = String(100 * 10 ** 18);

export async function POST(request: NextRequest) {
  try {
    const { address } = await request.json();

    if (!address || typeof address !== "string") {
      return NextResponse.json(
        { error: "Invalid address parameter" },
        { status: 400 }
      );
    }

    // Get the faucet private key from environment variables
    const privateKey = process.env.FAUCET_PRIVATE_KEY;
    if (!privateKey) {
      return NextResponse.json(
        { error: "Faucet private key not configured" },
        { status: 500 }
      );
    }

    // Create a shielded wallet client
    const walletClient = await createShieldedWalletClient({
      chain: seismicDevnet,
      transport: http(process.env.NEXT_PUBLIC_RPC_URL),
      account: privateKeyToAccount(privateKey as `0x${string}`),
    });

    // Get the USDY contract instance using the same pattern as app.ts
    const contract = await getShieldedContractWithCheck(
      walletClient,
      USDYContract.abi as Abi,
      USDYContract.address
    );

    // Mint USDY tokens to the requested address using regular address and amount
    const hash = await contract.write.mint([address, MINT_AMOUNT], {
      gas: BigInt(200000),
    });

    return NextResponse.json({ hash });
  } catch (error) {
    console.error("Error minting tokens:", error);
    return NextResponse.json(
      { error: "Failed to mint tokens" },
      { status: 500 }
    );
  }
}
