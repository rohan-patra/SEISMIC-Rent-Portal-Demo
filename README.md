# Seismic SERC-20

## Overview

A full-stack dApp demonstrating shielded tokens on the Seismic network, featuring private balances, transfers, and recipients.
The project includes:

- smart contracts for
  - SRC20 (a shielded ERC20 implementation)
  - USDY (a shielded yield-bearing stablecoin)
- a Next.js app with Rainbowkit & `seismic-react`
  - a faucet for minting USDY
  - a rent portal for managing and processing rent payments

## Project Structure

```
packages/
├── contracts/        # Solidity smart contracts
│   ├── src/
│   │   ├── SRC20.sol # Base shielded ERC20 implementation
│   │   └── USDY.sol  # Shielded yield-bearing stablecoin
│   ├── script/       # Deployment scripts
│   └── test/         # Contract test suites
└── frontend/         # Next.js web application
    ├── app/          # Application routes and components
    └── components/   # Reusable UI components
```

## Features

- **Shielded Tokens**: Private token balances and transfers using zero-knowledge proofs
- **USDY**: Yield-bearing stablecoin with privacy features
- **Rent Portal**: Web interface for managing and processing rent payments
- **Modern UI**: Built with Next.js, TailwindCSS, and RainbowKit
- **Privacy-First**: All token operations maintain user privacy through Seismic's ZK infrastructure

## Getting Started

### Setup

1. Install dependencies:

```bash
cd packages/frontend && bun install
cd ../contracts && forge install
```

2. Set up environment variables:

```bash
cp packages/frontend/.env.example packages/frontend/.env
cp packages/contracts/.env.example packages/contracts/.env
```

3. Run the development environment:

```bash
# In packages/frontend
bun dev
```
