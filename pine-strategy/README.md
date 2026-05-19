# AMD + Fibonacci ATR Strategy (TradingView Pine Script)

A **TradingView Pine Script v6** strategy that combines the **AMD (Accumulation, Manipulation, Distribution)** smart money concept with **Fibonacci retracement levels** and **ATR-based** risk management.

## Strategy Concept

The AMD model describes how institutional ("smart money") price delivery works in three phases:

### 1. Accumulation (Range/Consolidation)
- Price trades in a **tight range** (detected automatically via ATR-relative range width)
- Smart money is quietly building positions during this phase
- Visualized as a **blue shaded box** on the chart

### 2. Manipulation (Liquidity Sweep / False Breakout)
- Price **breaks out** of the accumulation range to grab liquidity (stop-losses)
- The breakout is **fake** — identified by a long wick with a small body that closes back inside the range
- **Sweep above** the range = bearish manipulation → short setup
- **Sweep below** the range = bullish manipulation → long setup
- Detection uses ATR-scaled wick length and body-to-range ratio filters

### 3. Distribution (The Real Move)
- After the manipulation sweep, price **reverses** and moves in the opposite direction
- Entry is refined using **Fibonacci retracement levels** (default: 61.8% golden ratio)
- Price must retrace to the Fibonacci zone and confirm by closing back inside the accumulation range
- **ATR-based stop-loss** and **take-profit** are placed automatically

## How It Works

```
   ┌────────────────────────────────────────┐
   │          ACCUMULATION ZONE              │
   │    (tight range, smart money builds)    │
   │                                         │
   │  ══════════════ accumTop ═══════════    │
   │  ║  price consolidates here        ║    │
   │  ══════════════ accumBot ═══════════    │
   │                                         │
   └────────────────────────────────────────┘
                     │
                     ▼
   ┌────────────────────────────────────────┐
   │          MANIPULATION SWEEP             │
   │                                         │
   │  Price sweeps BELOW accumBot            │
   │  (long wick, small body)                │
   │  → Bullish manipulation detected        │
   │  → Fibonacci levels drawn from           │
   │    sweep low → accumTop                 │
   │                                         │
   └────────────────────────────────────────┘
                     │
                     ▼
   ┌────────────────────────────────────────┐
   │          DISTRIBUTION (ENTRY)           │
   │                                         │
   │  Price retraces to Fib 61.8% level      │
   │  and closes back above accumBot         │
   │  → LONG entry triggered                 │
   │  → SL = Close - 1.5× ATR               │
   │  → TP = Close + 2.5× ATR               │
   │                                         │
   └────────────────────────────────────────┘
```

## Installation

1. Open [TradingView](https://www.tradingview.com)
2. Go to **Pine Editor** (bottom panel)
3. Click **Open** → **New blank indicator**
4. Delete the default code
5. Paste the contents of `AMD_Fib_ATR_Strategy.pine`
6. Click **Save** and then **Add to chart**

## Inputs / Settings

### AMD Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| Accumulation Lookback | 20 | Bars to scan for the consolidation range |
| Manipulation Wick ATR | 0.5 | Min wick length (as ATR multiple) for sweep detection |
| Manipulation Body % | 50 | Max body-to-range % for sweep candle (smaller = stricter) |
| Range Max Width (ATR) | 3.0 | Max accumulation range width in ATR (tighter = stricter) |
| Distribution Confirm Bars | 2 | Consecutive closes inside range to confirm distribution |

### ATR Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| ATR Period | 14 | ATR calculation period |
| Stop Loss ATR Multiple | 1.5 | SL distance = ATR × this value |
| Take Profit ATR Multiple | 2.5 | TP distance = ATR × this value |

### Fibonacci Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| Show Fibonacci Levels | true | Toggle Fibonacci overlay |
| Fib Entry Level | 0.618 | Primary Fibonacci level for entry (golden ratio) |
| Fib Level 38.2% | 0.382 | Secondary Fibonacci level |
| Fib Level 50% | 0.5 | Mid-point Fibonacci level |
| Fib Level 78.6% | 0.786 | Deep Fibonacci level |

### Session Filter
| Parameter | Default | Description |
|-----------|---------|-------------|
| Use Session Filter | false | Restrict signals to a specific trading session |
| Trading Session | 0800-1600 | Session window (exchange timezone) |

## Visual Elements

- **Blue Box** — Accumulation zone (consolidation range)
- **🔺 Green Label** — Bullish manipulation (sweep below)
- **🔻 Red Label** — Bearish manipulation (sweep above)
- **▲ Green Label** — Long entry signal
- **▼ Red Label** — Short entry signal
- **Dashed Lines** — Fibonacci levels (orange=38.2%, yellow=50%, cyan=61.8%, purple=78.6%)
- **Dotted Lines** — Stop-loss (red) and take-profit (green)
- **Info Table** — Top-right panel showing ATR, accumulation status, pending signals, position

## Alerts

The strategy includes 5 alert conditions:

1. **Bullish Manipulation** — Sweep below accumulation range detected
2. **Bearish Manipulation** — Sweep above accumulation range detected
3. **Long Entry Signal** — Distribution phase confirmed, long entry
4. **Short Entry Signal** — Distribution phase confirmed, short entry
5. **Accumulation Start** — New accumulation phase detected

To set up: TradingView → Alerts → Condition → Select this strategy → Choose alert type.

## Recommended Timeframes

- **15m / 1H** for intraday trading
- **4H / Daily** for swing trading
- Works on any asset (forex, crypto, stocks, futures)

## Risk Management

- **Fixed fractional**: Default 2% of equity per trade
- **ATR-based SL/TP**: Dynamic levels that adapt to volatility
- **Risk:Reward ratio**: Default 1:1.67 (1.5 ATR SL : 2.5 ATR TP)
- Adjust `atrSLMult` and `atrTPMult` to change the R:R ratio

## Disclaimer

This strategy is for **educational and research purposes only**. It is not financial advice. Past performance does not guarantee future results. Always backtest thoroughly and use proper risk management before trading with real capital.
