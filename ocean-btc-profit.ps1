#!/usr/bin/env pwsh
#requires -version 7.0
<#
.SYNOPSIS
    Ocean-optimized Bitcoin mining profitability calculator
.DESCRIPTION
    Uses live Ocean.xyz pool data (hashrate, last block, TIDES) + BTC price
    to calculate real expected BTC/day, revenue, cost, and profit.
#>

param(
    [Parameter(Mandatory,Position=0)][decimal]$HashrateThS,
    [Parameter(Mandatory,Position=1)][decimal]$PowerWatts,
    [Parameter(Mandatory,Position=2)][decimal]$ElectricityRate
)

# ──────────────────────────────────────────────────────────────
# Fallback for PowerShell 5.1: Allow script to run without #requires
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ recommended. Running in compatibility mode."
}

# Helper: Write with emoji (works in modern terminals)
function Write-Emoji {
    param([string]$Text)
    Write-Host $Text -NoNewline
}
# ──────────────────────────────────────────────────────────────

function Get-BTCPrice {
    try {
        $resp = Invoke-RestMethod "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" -TimeoutSec 10
        return [decimal]$resp.bitcoin.usd
    } catch {
        try {
            $resp = Invoke-RestMethod "https://blockchain.info/ticker" -TimeoutSec 10
            return [decimal]$resp.USD.last
        } catch {
            Write-Host "ERROR: Could not fetch BTC price" -ForegroundColor Red
            return $null
        }
    }
}

function Get-NetworkDifficulty {
    try {
        $resp = Invoke-RestMethod "https://blockchain.info/q/getdifficulty" -TimeoutSec 10
        return [decimal]$resp
    } catch {
        try {
            $resp = Invoke-RestMethod "https://mempool.space/api/v1/difficulty-adjustment" -TimeoutSec 10
            return [decimal]$resp.currentDifficulty
        } catch {
            Write-Host "ERROR: Could not fetch difficulty" -ForegroundColor Red
            return $null
        }
    }
}

function Get-OceanPoolStats {
    $url = "https://ocean.xyz/dashboard"
    try {
        $html = Invoke-WebRequest $url -UserAgent "Mozilla/5.0 (MiningCalc)" -TimeoutSec 15
        $html = $html.Content

        # Parse pool hashrate: "17.56 Eh/s"
        if ($html -match '([\d.]+)\s*Eh/s') {
            $poolEh = [decimal]$Matches[1]
        } else {
            throw "Could not parse pool hashrate"
        }

        # Parse last block: "4H AGO"
        if ($html -match '(\d+)H AGO') {
            $hoursAgo = [int]$Matches[1]
        } else {
            $hoursAgo = $null
        }

        # Convert EH/s → TH/s (compatible with PS 5.1)
        $poolTh = $poolEh * 1000000
        $networkEh = 730  # Approximate current network hashrate
        $poolShare = $poolEh / $networkEh
        $blocksPerDay = 144 * $poolShare
        $avgHoursBetween = if ($blocksPerDay -gt 0) { 24 / $blocksPerDay } else { 999 }

        $variance = "normal"
        $tidesMul = 1.0
        if ($null -ne $hoursAgo -and $avgHoursBetween -ne 999) {
            if ($hoursAgo -gt $avgHoursBetween * 1.5) {
                $variance = "unlucky"; $tidesMul = 0.90
            } elseif ($hoursAgo -lt $avgHoursBetween * 0.5) {
                $variance = "lucky"; $tidesMul = 1.10
            }
        }

        return @{
            PoolHashrateEh   = $poolEh
            PoolHashrateTh   = $poolTh
            HoursSinceBlock  = $hoursAgo
            PoolNetworkShare = $poolShare
            ExpectedBlocks   = $blocksPerDay
            AvgHoursBetween  = $avgHoursBetween
            Variance         = $variance
            TidesMultiplier  = $tidesMul
        }
    } catch {
        Write-Host "ERROR: Failed to scrape Ocean stats: $_" -ForegroundColor Red
        return $null
    }
}

function Calculate-TheoreticalBTC {
    param([decimal]$HashThs, [decimal]$Diff, [decimal]$Reward = 3.125)
    if ($Diff -le 0) { return 0 }
    $netThs = ($Diff * [Math]::Pow(2,32)) / (600 * 1000000000000)
    $share   = $HashThs / $netThs
    return $share * 144 * $Reward
}

function Calculate-OceanBTC {
    param([decimal]$HashThs, [hashtable]$Pool, [decimal]$Reward = 3.20)
    if (-not $Pool) { return 0 }
    $yourShare = $HashThs / $Pool.PoolHashrateTh
    $gross     = $yourShare * $Pool.ExpectedBlocks * $Reward
    $net       = $gross * 0.99  # DATUM 1% fee
    return $net * $Pool.TidesMultiplier
}

# ──────────────────────────────────────────────────────────────
# Header
Write-Host "`n" ("="*50) -ForegroundColor Cyan
Write-Emoji "Ocean BTC Profit Calculator "
Write-Host ("="*50) -ForegroundColor Cyan

# Live data
Write-Host "`nFetching live data..." -ForegroundColor Yellow
$btcPrice   = Get-BTCPrice
$difficulty = Get-NetworkDifficulty
$ocean      = Get-OceanPoolStats

if (-not $btcPrice -or -not $difficulty -or -not $ocean) {
    Write-Host "`nCannot continue without required data." -ForegroundColor Red
    exit 1
}

Write-Host "`nBTC Price:      " -NoNewline -ForegroundColor Green
Write-Host "`$$($btcPrice.ToString('N0'))" -ForegroundColor White

Write-Host "Network Diff:   " -NoNewline -ForegroundColor Green
Write-Host "$($difficulty.ToString('N0'))" -ForegroundColor White

Write-Host "`nOcean Pool:" -ForegroundColor Cyan
Write-Host "   Hashrate:    $($ocean.PoolHashrateEh) EH/s  ($($ocean.PoolNetworkShare*100):N2)% of network)"
Write-Host "   Last block:  $($ocean.HoursSinceBlock ?? 'unknown') h ago (avg $($ocean.AvgHoursBetween):N1 h))"
Write-Host "   Variance:    $($ocean.Variance) (TIDES $($ocean.TidesMultiplier)x)"

# Calculations
$theoreticalBTC = Calculate-TheoreticalBTC -HashThs $HashrateThS -Diff $difficulty
$oceanBTC       = Calculate-OceanBTC -HashThs $HashrateThS -Pool $ocean

$dailyBTC   = $oceanBTC
$monthlyBTC = $dailyBTC * 30
$annualBTC  = $dailyBTC * 365

$dailyRev   = $dailyBTC * $btcPrice
$monthlyRev = $monthlyBTC * $btcPrice
$annualRev  = $annualBTC * $btcPrice

$dailyKwh   = ($PowerWatts / 1000) * 24
$dailyCost  = $dailyKwh * $ElectricityRate
$monthlyCost= $dailyCost * 30
$annualCost = $dailyCost * 365

$dailyProfit = $dailyRev - $dailyCost
$monthlyProfit = $monthlyRev - $monthlyCost
$annualProfit  = $annualRev  - $annualCost

$breakEven  = if ($dailyBTC -gt 0) { $dailyCost / $dailyBTC } else { [decimal]::MaxValue }
$discount   = if ($btcPrice -gt $breakEven) { ($btcPrice - $breakEven)/$btcPrice*100 } else { -([Math]::Abs(($breakEven - $btcPrice)/$btcPrice*100)) }
$efficiency = $PowerWatts / $HashrateThS

# ──────────────────────────────────────────────────────────────
# Report
Write-Host "`n" ("="*50) -ForegroundColor Cyan
Write-Host "          SETUP" -ForegroundColor Yellow
Write-Host ("-"*50)
Write-Host "Hashrate:       $HashrateThS TH/s"
Write-Host "Power:          $PowerWatts W"
Write-Host "Efficiency:     $($efficiency.ToString('N1')) J/TH"
Write-Host "Electricity:    `$$($ElectricityRate)/kWh"
Write-Host ""

Write-Host "       BTC PRODUCTION" -ForegroundColor Yellow
Write-Host ("-"*50)
Write-Host "Theoretical:    $($theoreticalBTC.ToString('F8')) BTC/day"
Write-Host "Ocean + TIDES:  $($oceanBTC.ToString('F8')) BTC/day"
Write-Host "Monthly:        $($monthlyBTC.ToString('F8')) BTC"
Write-Host "Annual:         $($annualBTC.ToString('F8')) BTC"
Write-Host ""

Write-Host "          REVENUE" -ForegroundColor Yellow
Write-Host ("-"*50)
Write-Host "Daily:   `$$($dailyRev.ToString('N2'))"
Write-Host "Monthly: `$$($monthlyRev.ToString('N2'))"
Write-Host "Annual:  `$$($annualRev.ToString('N2'))"
Write-Host ""

Write-Host "        ELECTRICITY" -ForegroundColor Yellow
Write-Host ("-"*50)
Write-Host "Daily kWh: $($dailyKwh.ToString('N2')) kWh"
Write-Host "Daily Cost: `$$($dailyCost.ToString('N2'))"
Write-Host "Monthly:    `$$($monthlyCost.ToString('N2'))"
Write-Host "Annual:     `$$($annualCost.ToString('N2'))"
Write-Host ""

Write-Host "        PROFITABILITY" -ForegroundColor Yellow
Write-Host ("-"*50)
if ($dailyProfit -gt 0) {
    Write-Host "Status:   " -NoNewline; Write-Host "PROFITABLE" -ForegroundColor Green
    Write-Host "Daily:    +`$$($dailyProfit.ToString('N2'))" -ForegroundColor Green
    Write-Host "Monthly:  +`$$($monthlyProfit.ToString('N2'))" -ForegroundColor Green
    Write-Host "Annual:   +`$$($annualProfit.ToString('N2'))" -ForegroundColor Green
} else {
    Write-Host "Status:   " -NoNewline; Write-Host "UNPROFITABLE" -ForegroundColor Red
    Write-Host "Daily:    `$$($dailyProfit.ToString('N2'))" -ForegroundColor Red
    Write-Host "Monthly:  `$$($monthlyProfit.ToString('N2'))" -ForegroundColor Red
    Write-Host "Annual:   `$$($annualProfit.ToString('N2'))" -ForegroundColor Red
}
Write-Host ""

Write-Host "          METRICS" -ForegroundColor Yellow
Write-Host ("-"*50)
Write-Host "Break-Even: `$$($breakEven.ToString('N0')) BTC"
Write-Host "Cost/BTC:   `$$($breakEven.ToString('N0'))"
if ($discount -gt 0) {
    Write-Host "vs Market:  $($discount.ToString('N1'))% discount" -ForegroundColor Green
} elseif ($discount -lt 0) {
    Write-Host "vs Market:  $([Math]::Abs($discount).ToString('N1'))% premium" -ForegroundColor Red
} else {
    Write-Host "vs Market:  At market price"
}
Write-Host ""

if ($dailyProfit -le 0) {
    Write-Host "`nWARNING: Mining is currently unprofitable!" -ForegroundColor Red
    Write-Host "You need BTC > `$$($breakEven.ToString('N0')) to break even." -ForegroundColor Yellow
}
Write-Host "`n" ("="*50) -ForegroundColor Cyan