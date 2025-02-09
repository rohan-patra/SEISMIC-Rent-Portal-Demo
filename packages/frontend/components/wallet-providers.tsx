"use client";

import "@rainbow-me/rainbowkit/styles.css";
import {
  getDefaultConfig,
  RainbowKitProvider,
  lightTheme,
  darkTheme,
} from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { seismicDevnet } from "@/lib/chain";
import { ShieldedWalletProvider } from "seismic-react";

const config = getDefaultConfig({
  appName: "Seismic Rent App",
  projectId: "YOUR_PROJECT_ID",
  chains: [seismicDevnet],
  ssr: true, // If your dApp uses server side rendering (SSR)
});

const queryClient = new QueryClient();

export function WalletProviders({ children }: { children: React.ReactNode }) {
  const { resolvedTheme } = useTheme();
  const theme = resolvedTheme === "dark" ? darkTheme() : lightTheme();

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={theme}>
          <ShieldedWalletProvider config={config}>
            {children}
          </ShieldedWalletProvider>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
