# Ocean BTC Profit Calculator (`ocean-btc-profit.ps1`)

**Real-time Bitcoin mining profitability calculator optimized for [Ocean.xyz](https://ocean.xyz)**  
Uses **live pool hashrate**, **TIDES variance**, **DATUM 1% fee**, and **your electricity cost**.

> No stale data. No guesswork. Just **your actual expected BTC/day on Ocean**.

---

## Features

| Feature | Description |
|--------|-------------|
| **Ocean Pool Live Stats** | Scrapes `ocean.xyz/dashboard` for hashrate & last block |
| **TIDES Variance Detection** | Auto-applies `1.1x` (lucky) or `0.9x` (unlucky) |
| **DATUM 1% Fee** | Transparent, non-custodial pool fee |
| **Live BTC Price** | CoinGecko → blockchain.info fallback |
| **Network Difficulty** | blockchain.info → mempool.space fallback |
| **Theoretical vs Ocean** | Compare global vs real pool output |
| **Full P&L** | Daily / monthly / annual revenue, cost, profit |
| **Break-even & Discount** | Know when you profit vs market |
| **Color + Emoji Output** | Beautiful in Windows Terminal / VS Code |

---

## Requirements

| Requirement | Notes |
|-----------|-------|
| **PowerShell 7+** | `pwsh` — **recommended** |
| **PowerShell 5.1** | Works with warning (no modern syntax) |
| Internet | For live data |
| Modern Terminal | For colors + emojis |

> **Check your version**:
> ```powershell
> $PSVersionTable.PSVersion
> ```

---

## Installation

```powershell
# Clone the repo
git clone https://github.com/yourname/ocean-btc-profit-calculator.git
cd ocean-btc-profit-calculator

# Run with PowerShell 7+
pwsh -File .\ocean-btc-profit.ps1 370 6900 0.11