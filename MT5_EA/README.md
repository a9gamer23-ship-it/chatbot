# Volume Profile Expert Advisor for MetaTrader 5

A professional-grade Volume Profile EA that builds a real-time volume-by-price distribution and trades based on institutional-level Volume Profile concepts: **Point of Control (POC)**, **Value Area High (VAH)**, **Value Area Low (VAL)**, **High Volume Nodes (HVN)**, and **Low Volume Nodes (LVN)**.

---

## Core Concepts

### What is Volume Profile?

Volume Profile is a horizontal histogram showing how much volume was traded at each price level over a configurable lookback period. Unlike time-based volume bars, it reveals **where** institutional capital is concentrated.

| Term | Definition | Trading Implication |
|------|-----------|-------------------|
| **POC** | Price level with highest traded volume | Acts as a magnet; price tends to gravitate here |
| **VAH** | Upper boundary of the Value Area (70% of volume) | Resistance / breakout trigger |
| **VAL** | Lower boundary of the Value Area | Support / breakdown trigger |
| **HVN** | High Volume Node — significant activity cluster | Strong support/resistance |
| **LVN** | Low Volume Node — minimal activity | Price moves through quickly |

---

## Trading Strategies

### Mode 1: Mean Reversion (Value Area Fade)

Trades price rejections at Value Area boundaries back toward the POC.

- **Buy Signal**: Price reaches VAL + shows bullish rejection candle (long lower wick) + RSI near oversold + trend filter aligned
- **Sell Signal**: Price reaches VAH + shows bearish rejection candle (long upper wick) + RSI near overbought + trend filter aligned
- **Target**: POC (fair value)
- **Stop Loss**: ATR-based beyond the VA boundary

**Best in**: Range-bound markets, consolidation periods, balanced volume profiles (D-shaped).

### Mode 2: Breakout

Trades confirmed closes beyond VAH/VAL with momentum confirmation.

- **Buy Signal**: Close above VAH (first bar to break out) + bullish momentum + RSI 50-70 zone + uptrend confirmed
- **Sell Signal**: Close below VAL (first bar to break down) + bearish momentum + RSI 30-50 zone + downtrend confirmed
- **Target**: Next HVN level or ATR-based projection
- **Stop Loss**: Back inside the Value Area (tighter ATR multiplier)

**Best in**: Trending markets, P-shaped (buying) or b-shaped (selling) profiles.

### Mode 3: Hybrid (Default)

Combines both strategies simultaneously — fades at VA edges in ranging conditions and catches breakouts when momentum confirms.

---

## Filters & Confluence

| Filter | Purpose | Default |
|--------|---------|---------|
| **EMA 200** | Long-term trend direction | Enabled |
| **EMA 50** | Trend confirmation (50 > 200 = uptrend) | Enabled |
| **RSI 14** | Momentum/overbought/oversold filter | Enabled |
| **Session Filter** | Only trade during active hours | 08:00-20:00 server time |
| **Proximity ATR** | How close price must be to VA levels | 0.3x ATR |

---

## Risk Management

- **Position Sizing**: Automatic lot calculation based on % risk per trade
- **ATR-Based Stops**: Dynamic SL/TP adapting to current volatility
- **Trailing Stop**: ATR-based trailing that locks in profits
- **Breakeven**: Moves SL to entry + small buffer once trade is profitable by 1 ATR
- **Max Positions**: Configurable cap on concurrent trades (default: 2)
- **Max Daily Trades**: Prevents overtrading (default: 6)

---

## Input Parameters

### Volume Profile Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpLookbackBars` | 100 | Number of bars to build the profile from |
| `InpPriceBins` | 50 | Granularity of price bins |
| `InpValueAreaPct` | 70.0 | Value Area percentage |
| `InpVolumeType` | Tick | Tick Volume or Real Volume |
| `InpProfileTF` | H1 | Timeframe for profile calculation |

### Strategy Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpTradeMode` | Hybrid | Mean Reversion / Breakout / Hybrid |
| `InpProximityATR` | 0.3 | ATR multiplier for proximity detection |
| `InpConfirmBars` | 2 | Confirmation candles needed |
| `InpUseTrendFilter` | true | Enable EMA trend filter |
| `InpTrendEMAPeriod` | 200 | Slow EMA period |
| `InpFastEMAPeriod` | 50 | Fast EMA period |
| `InpUseRSIFilter` | true | Enable RSI filter |
| `InpRSIPeriod` | 14 | RSI calculation period |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpRiskPercent` | 1.0 | Risk per trade (% of balance) |
| `InpATRMultSL` | 1.5 | Stop Loss ATR multiplier |
| `InpATRMultTP` | 2.5 | Take Profit ATR multiplier |
| `InpATRPeriod` | 14 | ATR period |
| `InpUseTrailingStop` | true | Enable trailing stop |
| `InpTrailATRMult` | 1.0 | Trailing distance (ATR mult) |
| `InpUseBreakeven` | true | Move SL to breakeven |
| `InpBreakevenATR` | 1.0 | Breakeven trigger distance |
| `InpMaxPositions` | 2 | Max concurrent positions |
| `InpMaxDailyTrades` | 6 | Max trades per day |

---

## Installation

1. Copy `VolumeProfileEA.mq5` into your MT5 `Experts` folder:
   ```
   <MT5 Data Folder>\MQL5\Experts\VolumeProfileEA.mq5
   ```
2. Open MetaEditor and compile the file (F7)
3. In MT5, open Navigator → Expert Advisors → drag `VolumeProfileEA` onto a chart
4. Enable "Allow Algo Trading" in MT5 settings
5. Configure inputs as desired and click OK

---

## Recommended Settings by Asset Class

### Forex (EURUSD, GBPUSD, etc.)
- Lookback: 100-150 bars on H1
- Price Bins: 50
- Risk: 1-2%
- Session: 08:00-20:00 (London + NY overlap)

### Indices (US30, NAS100, etc.)
- Lookback: 50-80 bars on H1
- Price Bins: 40
- Risk: 0.5-1%
- Session: 14:30-21:00 (US session)

### Gold (XAUUSD)
- Lookback: 80-120 bars on H1
- Price Bins: 50
- Risk: 0.5-1%
- Higher ATR multipliers (SL: 2.0, TP: 3.0)

---

## Backtesting Tips

1. Use **"Every tick based on real ticks"** mode for best accuracy
2. Start with a demo account to validate
3. Test across multiple market conditions (trending, ranging, volatile)
4. Optimize lookback period and ATR multipliers first
5. Check the **Profit Factor** (target > 1.5) and **Max Drawdown** (target < 15%)

---

## How the Volume Profile is Built

1. **Data Retrieval**: Copies High, Low, Close, and Volume arrays for the lookback period using `CopyHigh`, `CopyLow`, `CopyClose`, `CopyTickVolume`/`CopyRealVolume`
2. **Price Binning**: Divides the high-low range into N equal bins
3. **Volume Distribution**: Each bar's volume is distributed across all bins it covers, with extra weight given to the close price bin (close-weighted distribution)
4. **POC Calculation**: The bin with the highest accumulated volume
5. **Value Area**: Starting from the POC bin, expands up and down, always adding the higher-volume adjacent bin, until 70% of total volume is enclosed
6. **HVN/LVN Detection**: Bins above 1.5x average = HVN, below 0.5x average = LVN

---

## Disclaimer

This EA is provided for educational and research purposes. Past performance does not guarantee future results. Always test on a demo account before live trading. Use proper risk management and never risk more than you can afford to lose.
