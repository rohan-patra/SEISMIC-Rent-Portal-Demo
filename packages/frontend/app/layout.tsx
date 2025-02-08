import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { WalletProviders } from "@/components/wallet-providers";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { Toaster } from "@/components/ui/sonner";
const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Seismic Rent App",
  description:
    "Privately pay your rent in yield-bearing stablecoins with Seismic.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <WalletProviders>
            <nav className="top-0 left-0 right-0 flex justify-between items-center p-4 bg-background border-b">
              <div className="font-semibold text-2xl">Rent App</div>
              <div className="flex items-center gap-2">
                <ThemeSwitcher />
                <ConnectButton />
              </div>
            </nav>
            <div className="p-4">{children}</div>
            <Toaster richColors />
          </WalletProviders>
        </ThemeProvider>
      </body>
    </html>
  );
}
