import { defineChain } from "viem";

const RPC_URL = "http://localhost:3000/api/rpc";
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
