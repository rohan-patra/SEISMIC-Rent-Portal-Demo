import { createPublicClient, fallback, http } from "viem";
import { defineChain } from "viem";

export const seismicDevnet = defineChain({
  id: 1337,
  name: "Seismic Devnet",
  rpcUrls: {
    default: { http: ["http://48.211.212.30:8545"] },
  },
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  // blockExplorers: {
  //   default: { name: "TBD", url: "https://seismic.systems/explorer" },
  // },
  // contracts: {
  //   multicall3: {
  //     address: "TBD",
  //     blockCreated: TBD,
  //   },
  // },
});

export const publicClient = createPublicClient({
  batch: {
    multicall: true,
  },
  chain: seismicDevnet,
  transport: fallback([http("http://48.211.212.30:8545")]),
});
