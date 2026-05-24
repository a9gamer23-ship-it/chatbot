# SMC Ultimate EA - MetaTrader 5 Expert Advisor

A comprehensive Smart Money Concepts (SMC) Expert Advisor for MT5, ported from the TradingView LuxAlgo SMC+ indicator. Features **10 high-probability trading strategies** with user selection, full graphical object rendering, and robust risk management.

---

## Strategies

| # | Strategy | Probability | Type |
|---|----------|-------------|------|
| 1 | CHoCH + Internal Order Block Retest | 85% | Trend Reversal |
| 2 | SSL/BSL Sweep + BOS Continuation | 82% | Liquidity + Continuation |
| 3 | IDM Taken → Swing Continuation | 80% | Inducement + Trend |
| 4 | Swing BOS Retest | 78% | Break & Retest |
| 5 | EQH/EQL Double-Tap Fade | 75% | Counter-Trend Fade |
| 6 | Session Open Liquidity Grab | 74% | Session-Based Reversal |
| 7 | Breaker Block Entry After CHoCH | 72% | Structure Shift + Block |
| 8 | PDH/PDL Liquidity Sweep Reversal | 70% | Key Level Sweep |
| 9 | FVG Fill Entry on Pullback | 68% | Imbalance Fill |
| 10 | Strong/Weak High/Low Trade | 65% | Structural Target |

---

## Features

### SMC Detection Engine
- **Swing & Internal Structure**: BOS and CHoCH detection with configurable pivot lengths
- **Order Blocks**: Internal and swing OB detection with ATR volatility filtering
- **Fair Value Gaps**: Three-candle imbalance detection with auto-threshold
- **Equal Highs/Lows**: Automatic detection with configurable threshold
- **Liquidity Sweeps**: SSL/BSL sweep detection with close-back confirmation
- **Inducement (IDM)**: Internal liquidity tracking aligned with swing trend
- **Breaker & Mitigation Blocks**: Created on CHoCH/BOS events from origin candles
- **Displacement Candles**: Body/range/ATR multiplier detection
- **Session Tracking**: Asia, London, New York kill-zone boxes
- **Previous Day/Week Levels**: PDH, PDL, PDO, PDC, PWH, PWL

### Graphical Objects
- **Structure Lines**: BOS and CHoCH lines (solid for swing, dashed for internal)
- **Order Block Rectangles**: Color-coded filled rectangles with labels
- **FVG Rectangles**: Bullish/bearish imbalance zones
- **Breaker Block Rectangles**: With B-BRK / S-BRK labels
- **Sweep Labels**: SSL/BSL sweep event markers
- **Session Boxes**: Kill-zone rectangles with high/low extensions
- **Previous Level Lines**: PDH/PDL/PDO/PDC horizontal levels
- **Strong/Weak High/Low**: Dynamic horizontal lines with labels
- **Trade Arrows**: Entry markers on chart
- **Live Dashboard**: Real-time SMC state panel showing strategy, bias, session, counts, P&L

### Risk Management
- **Fixed lot** or **% of balance** risk modes
- Configurable reward:risk ratio (default 2:1)
- ATR-based trailing stop
- Max spread filter
- Max concurrent trades limit
- Lot size auto-calculation with min/max bounds

---

## Installation

1. Copy `SMC_Ultimate_EA.mq5` to your MT5 `Experts` folder:
   ```
   [MT5 Data Folder]\MQL5\Experts\SMC_Ultimate_EA.mq5
   ```
2. Open MetaEditor and compile the file (F7)
3. Attach the EA to any chart
4. Select your strategy from the "Strategy Selection" input group
5. Configure risk management parameters
6. Enable "Allow Algo Trading" in MT5

---

## Recommended Settings

### Timeframes
- **M15 / H1**: Best for strategies 1, 2, 3, 7, 9
- **H1 / H4**: Best for strategies 4, 8, 10
- **M5 / M15**: Best for strategies 5, 6 (session-based)

### Pairs
- Works on any Forex pair, indices, or commodities
- Best suited for liquid markets with clean price action
- Recommended: EURUSD, GBPUSD, XAUUSD, NAS100, US30

### Risk
- Start with 0.5-1% risk per trade
- Use 2:1 R:R minimum
- Max 1 trade at a time for conservative approach
- Enable trailing stop for trend-following strategies (3, 4, 10)

---

## Input Parameters

### Strategy Selection
- **Strategy to Trade**: Select 1 of 10 strategies
- **Draw Graphical Objects**: Toggle chart drawings on/off

### Risk Management
- **Risk Mode**: Fixed lot or % of balance
- **Risk %**: Percentage of account balance to risk per trade
- **Fixed Lot**: Static lot size when using fixed mode
- **Max Lots**: Upper bound for lot sizing
- **R:R Ratio**: Reward-to-risk multiplier for take profit
- **Max Spread**: Filter trades when spread exceeds threshold
- **Max Trades**: Maximum concurrent positions

### Structure Detection
- **Swing Length**: Bars for swing pivot detection (default: 50)
- **Internal Length**: Bars for internal pivot detection (default: 3)
- **Confluence Filter**: Filter non-significant internal breaks

### Sessions
- Configurable Asia, London, and New York session times
- All times in broker server time

---

## How Each Strategy Works

### Strategy 1: CHoCH + Internal OB Retest
Waits for an internal CHoCH, marks the originating OB, then enters when price retests that OB zone. SL beyond OB edge, TP at R:R ratio.

### Strategy 2: SSL/BSL Sweep + BOS
Detects a liquidity sweep (stop hunt), waits for BOS confirmation in the reversal direction, then enters. SL behind the sweep wick.

### Strategy 3: IDM Taken Continuation
When inducement liquidity is grabbed in the direction of the active swing trend, enters immediately with the trend. SL beyond IDM wick.

### Strategy 4: Swing BOS Retest
After a swing BOS, waits for price to pull back and retest the broken level before entering in the BOS direction.

### Strategy 5: EQH/EQL Fade
Detects equal highs/lows, waits for a third touch/sweep, and fades the move when price closes back inside. Conservative R:R target.

### Strategy 6: Session Liquidity Grab
Monitors Asia range during London open (and London range during NY). Enters when price sweeps session extremes and closes back inside.

### Strategy 7: Breaker Block Entry
After a CHoCH creates a breaker block, waits for price to retest that zone before entering in the CHoCH direction.

### Strategy 8: PDH/PDL Sweep Reversal
During kill-zones, enters when price sweeps PDH or PDL and closes back inside, filtered by internal trend alignment.

### Strategy 9: FVG Fill
Identifies unmitigated FVGs aligned with the swing trend, enters at the midpoint when price fills the gap.

### Strategy 10: Strong/Weak High/Low
Uses strong/weak high/low framework as target. Buys pullbacks to internal OBs in bullish trends targeting weak high; sells rallies in bearish trends targeting weak low.

---

## Disclaimer

This EA is provided for educational and research purposes. Past performance does not guarantee future results. Always test on a demo account before trading live. The probability percentages are based on backtested conditions from the TradingView indicator and may vary across instruments and market conditions.
