# Ocean BTC Profit Calculator (`ocean-btc-profit.ps1`)

**Real-time Bitcoin mining profitability calculator optimized for [Ocean.xyz](https://ocean.xyz)**  
Uses **live pool hashrate**, **TIDES variance**, **DATUM 1% fee**, and **your electricity cost**.

> No guessing. No stale data. Just **your actual expected BTC/day on Ocean**.

---

## Features

| Feature | Description |
|-------|-----------|
| **Ocean Pool Integration** | Scrapes live hashrate & last block from `ocean.xyz/dashboard` |
| **TIDES Multiplier** | Auto-detects lucky/unlucky variance: `1.1x` or `0.9x` |
| **DATUM Fee** | Hardcoded 1% fee (transparent, non-custodial) |
| **Live BTC Price** | Fallbacks: CoinGecko → blockchain.info |
| **Network Difficulty** | Fallbacks: blockchain.info → mempool.space |
| **Theoretical vs Ocean** | Compare global network vs your real Ocean output |
| **Full P&L** | Daily, monthly, annual revenue, cost, profit |
| **Break-even & Discount** | Know exactly when you profit |
| **Color + Emoji Output** | Beautiful in Windows Terminal / VS Code |

---

## Requirements

- **PowerShell 7+** (`pwsh`)
- Internet connection
- Windows Terminal or VS Code (for full color/emoji support)

> Tested on Windows 11, PowerShell 7.4+

---

## Installation

```powershell
# Clone the repo
git clone https://github.com/yourname/ocean-btc-profit.git
cd ocean-btc-profit

# Make executable (optional)
# chmod +x ocean-btc-profit.ps1   # Linux/macOS
```

---

## Usage

```powershell
.\ocean-btc-profit.ps1 <Hashrate TH/s> <Power Watts> <$/kWh>
```

### Example: 4× Avalon Q (SUPER mode)

```powershell
.\ocean-btc-profit.ps1 370 6900 0.11
```

### Output (sample)

```
Bitcoin Mining Profitability (Ocean-Optimized) 
============================================
Fetching live data...

BTC Price:      $96,420
Network Diff:   96,420,123,456,789

Ocean Pool:
   Hashrate:    17.56 EH/s  (2.41% of network)
   Last block:  4 h ago (avg 9.9 h)
   Variance:    unlucky (TIDES 0.9x)

============================================
          SETUP
------------------------------------------
Hashrate:       370 TH/s
Power:          6900 W
Efficiency:     18.6 J/TH
Electricity:    $0.11/kWh

       BTC PRODUCTION
------------------------------------------
Theoretical:    0.00042135 BTC/day
Ocean + TIDES:  0.00039871 BTC/day
Monthly:        0.01196130 BTC
Annual:         0.14562915 BTC

          REVENUE
------------------------------------------
Daily:   $38.45
Monthly: $1,153.50
Annual:  $14,037.25

        ELECTRICITY
------------------------------------------
Daily kWh: 165.60 kWh
Daily Cost: $18.22
Monthly:    $546.60
Annual:     $6,650.30

        PROFITABILITY
------------------------------------------
Status:   PROFITABLE
Daily:    +$20.23
Monthly:  +$606.90
Annual:   +$7,386.95

          METRICS
------------------------------------------
Break-Even: $45,700 BTC
Cost/BTC:   $45,700
vs Market:  52.6% discount

============================================
```

---

## How It Works

1. **Scrapes Ocean dashboard** → gets pool hashrate + hours since last block
2. **Estimates expected blocks/day** based on Ocean’s network share
3. **Applies TIDES**:
   - `>1.5× avg` → unlucky → `0.9x`
   - `<0.5× avg` → lucky → `1.1x`
4. **Your BTC/day** = `(your TH/s / pool TH/s) × blocks × reward × 0.99 × TIDES`
5. **Profit** = Revenue − Electricity

---

## Contributing

Pull requests welcome! Especially:
- Better HTML parsing (Ocean UI changes often)
- Support for other Ocean-like pools
- JSON API integration (if Ocean exposes one)
- GUI version (PowerShell + WPF?)

---

## License

```
MIT License
```

See [`LICENSE`](LICENSE) for full text.

---

## Disclaimer

> This tool is for **educational and informational purposes only**.  
> Cryptocurrency mining involves risk. Past performance ≠ future results.  
> Always verify outputs with multiple sources.

---

**Star this repo if you mine with Ocean!**