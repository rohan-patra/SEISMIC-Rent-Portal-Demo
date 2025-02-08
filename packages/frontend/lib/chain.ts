import { defineChain } from "viem";

const RPC_URL = process.env.NEXT_PUBLIC_RPC_URL as string;
const EXPLORER_URL = process.env.NEXT_PUBLIC_EXPLORER_URL as string;

export const seismicDevnet = defineChain({
  id: 1337,
  name: "Seismic Devnet",
  rpcUrls: {
    default: { http: [RPC_URL] },
  },
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  blockExplorers: {
    default: { name: "Seismic Devnet Explorer", url: EXPLORER_URL },
  },
  // contracts: {
  //   multicall3: {
  //     address: "TBD",
  //     blockCreated: TBD,
  //   },
  // },
});
