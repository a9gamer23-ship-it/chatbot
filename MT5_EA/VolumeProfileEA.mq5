//+------------------------------------------------------------------+
//|                                             VolumeProfileEA.mq5  |
//|                        Volume Profile Expert Advisor for MT5      |
//|              POC / VAH / VAL Mean-Reversion & Breakout Strategy   |
//+------------------------------------------------------------------+
#property copyright   "VolumeProfileEA"
#property link        ""
#property version     "1.00"
#property description "Professional Volume Profile EA using POC, VAH, VAL"
#property description "Supports Mean-Reversion, Breakout, and Hybrid modes"
#property description "with ATR-based risk management and EMA trend filter."
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
enum ENUM_TRADE_MODE
  {
   MODE_MEAN_REVERSION = 0,  // Mean Reversion (Fade VAH/VAL toward POC)
   MODE_BREAKOUT       = 1,  // Breakout (Trade beyond VAH/VAL)
   MODE_HYBRID         = 2   // Hybrid (Both strategies combined)
  };

enum ENUM_VOLUME_TYPE
  {
   VOL_TICK = 0,  // Tick Volume
   VOL_REAL = 1   // Real Volume (if available)
  };

//+------------------------------------------------------------------+
//| Input Parameters -- Volume Profile                               |
//+------------------------------------------------------------------+
input group "=== Volume Profile Settings ==="
input int             InpLookbackBars     = 100;       // Lookback period (bars)
input int             InpPriceBins        = 50;        // Number of price bins
input double          InpValueAreaPct     = 70.0;      // Value Area percentage
input ENUM_VOLUME_TYPE InpVolumeType      = VOL_TICK;  // Volume type
input ENUM_TIMEFRAMES InpProfileTF        = PERIOD_H1; // Profile timeframe

//+------------------------------------------------------------------+
//| Input Parameters -- Strategy                                     |
//+------------------------------------------------------------------+
input group "=== Strategy Settings ==="
input ENUM_TRADE_MODE InpTradeMode        = MODE_HYBRID;   // Trading mode
input double          InpProximityATR     = 0.3;           // Proximity to VA levels (ATR mult)
input int             InpConfirmBars      = 2;             // Confirmation candles needed
input bool            InpUseTrendFilter   = true;          // Use EMA trend filter
input int             InpTrendEMAPeriod   = 200;           // Trend EMA period
input int             InpFastEMAPeriod    = 50;            // Fast EMA period
input bool            InpUseRSIFilter     = true;          // Use RSI confirmation
input int             InpRSIPeriod        = 14;            // RSI period
input double          InpRSIOverbought    = 70.0;          // RSI overbought level
input double          InpRSIOversold      = 30.0;          // RSI oversold level

//+------------------------------------------------------------------+
//| Input Parameters -- Risk Management                              |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double          InpRiskPercent      = 1.0;           // Risk per trade (% of balance)
input double          InpATRMultSL        = 1.5;           // Stop Loss ATR multiplier
input double          InpATRMultTP        = 2.5;           // Take Profit ATR multiplier
input int             InpATRPeriod        = 14;            // ATR period
input bool            InpUseTrailingStop  = true;          // Use trailing stop
input double          InpTrailATRMult     = 1.0;           // Trailing stop ATR multiplier
input bool            InpUseBreakeven     = true;          // Move SL to breakeven
input double          InpBreakevenATR     = 1.0;           // Breakeven trigger (ATR mult)
input int             InpMaxPositions     = 2;             // Maximum concurrent positions
input int             InpMaxDailyTrades   = 6;             // Maximum trades per day

//+------------------------------------------------------------------+
//| Input Parameters -- Session Filter                               |
//+------------------------------------------------------------------+
input group "=== Session Filter ==="
input bool            InpUseSessionFilter = true;          // Enable session filter
input int             InpSessionStartHour = 8;             // Session start hour (server time)
input int             InpSessionEndHour   = 20;            // Session end hour (server time)

//+------------------------------------------------------------------+
//| Input Parameters -- Visual                                       |
//+------------------------------------------------------------------+
input group "=== Visual Settings ==="
input bool            InpDrawProfile      = true;          // Draw volume profile on chart
input bool            InpDrawLevels       = true;          // Draw POC/VAH/VAL lines
input color           InpPOCColor         = clrGold;       // POC line color
input color           InpVAHColor         = clrDodgerBlue; // VAH line color
input color           InpVALColor         = clrOrangeRed;  // VAL line color
input int             InpMagicNumber      = 202605;        // EA Magic Number

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
CAccountInfo   accInfo;

double g_poc;
double g_vah;
double g_val;
double g_profileHigh;
double g_profileLow;
double g_volumeBins[];
double g_priceLevels[];
double g_hvnLevels[];
double g_lvnLevels[];
int    g_hvnCount;
int    g_lvnCount;

int    g_handleATR;
int    g_handleEMA200;
int    g_handleEMA50;
int    g_handleRSI;

double g_atrBuffer[];
double g_ema200Buffer[];
double g_ema50Buffer[];
double g_rsiBuffer[];

int    g_dailyTradeCount;
datetime g_lastTradeDay;
datetime g_lastBarTime;

string g_prefix = "VP_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpLookbackBars < 10)
     {
      Print("Lookback bars must be >= 10");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpPriceBins < 10 || InpPriceBins > 200)
     {
      Print("Price bins must be between 10 and 200");
      return INIT_PARAMETERS_INCORRECT;
     }

   symInfo.Name(_Symbol);

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_handleATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   g_handleEMA200 = iMA(_Symbol, PERIOD_CURRENT, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleEMA50 = iMA(_Symbol, PERIOD_CURRENT, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);

   if(g_handleATR == INVALID_HANDLE || g_handleEMA200 == INVALID_HANDLE ||
      g_handleEMA50 == INVALID_HANDLE || g_handleRSI == INVALID_HANDLE)
     {
      Print("Failed to create indicator handles");
      return INIT_FAILED;
     }

   ArraySetAsSeries(g_atrBuffer, true);
   ArraySetAsSeries(g_ema200Buffer, true);
   ArraySetAsSeries(g_ema50Buffer, true);
   ArraySetAsSeries(g_rsiBuffer, true);

   g_dailyTradeCount = 0;
   g_lastTradeDay = 0;
   g_lastBarTime = 0;

   g_poc = 0;
   g_vah = 0;
   g_val = 0;
   g_hvnCount = 0;
   g_lvnCount = 0;

   Print("VolumeProfileEA initialized. Mode: ", EnumToString(InpTradeMode));
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   CleanupChartObjects();

   if(g_handleATR != INVALID_HANDLE)    IndicatorRelease(g_handleATR);
   if(g_handleEMA200 != INVALID_HANDLE) IndicatorRelease(g_handleEMA200);
   if(g_handleEMA50 != INVALID_HANDLE)  IndicatorRelease(g_handleEMA50);
   if(g_handleRSI != INVALID_HANDLE)    IndicatorRelease(g_handleRSI);

   Print("VolumeProfileEA deinitialized. Reason: ", reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == g_lastBarTime)
      return;
   g_lastBarTime = currentBarTime;

   if(!UpdateIndicatorBuffers())
      return;

   ResetDailyCounterIfNeeded();

   if(!IsWithinSession())
      return;

   BuildVolumeProfile();

   if(InpDrawLevels)
      DrawProfileLevels();

   ManageOpenPositions();

   if(CountPositions() >= InpMaxPositions)
      return;
   if(g_dailyTradeCount >= InpMaxDailyTrades)
      return;

   EvaluateTradeSignals();
  }

//+------------------------------------------------------------------+
//| Update indicator buffers                                         |
//+------------------------------------------------------------------+
bool UpdateIndicatorBuffers()
  {
   if(CopyBuffer(g_handleATR, 0, 0, 3, g_atrBuffer) < 3)       return false;
   if(CopyBuffer(g_handleEMA200, 0, 0, 3, g_ema200Buffer) < 3) return false;
   if(CopyBuffer(g_handleEMA50, 0, 0, 3, g_ema50Buffer) < 3)   return false;
   if(CopyBuffer(g_handleRSI, 0, 0, 3, g_rsiBuffer) < 3)       return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Build the Volume Profile                                         |
//| Computes POC, VAH, VAL from lookback bars                       |
//+------------------------------------------------------------------+
void BuildVolumeProfile()
  {
   int totalBars = iBars(_Symbol, InpProfileTF);
   int lookback = MathMin(InpLookbackBars, totalBars - 1);
   if(lookback < 10) return;

   double highArr[];
   double lowArr[];
   double closeArr[];
   long   volArr[];

   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr, true);
   ArraySetAsSeries(closeArr, true);
   ArraySetAsSeries(volArr, true);

   if(CopyHigh(_Symbol, InpProfileTF, 0, lookback, highArr) < lookback)   return;
   if(CopyLow(_Symbol, InpProfileTF, 0, lookback, lowArr) < lookback)     return;
   if(CopyClose(_Symbol, InpProfileTF, 0, lookback, closeArr) < lookback) return;

   bool volCopied = false;
   if(InpVolumeType == VOL_REAL)
     {
      long realVol[];
      ArraySetAsSeries(realVol, true);
      if(CopyRealVolume(_Symbol, InpProfileTF, 0, lookback, realVol) >= lookback)
        {
         ArrayResize(volArr, lookback);
         for(int i = 0; i < lookback; i++)
            volArr[i] = realVol[i];
         volCopied = true;
        }
     }
   if(!volCopied)
     {
      if(CopyTickVolume(_Symbol, InpProfileTF, 0, lookback, volArr) < lookback)
         return;
     }

   //--- Find highest high and lowest low in the lookback
   double rangeHigh = highArr[0];
   double rangeLow  = lowArr[0];
   for(int i = 1; i < lookback; i++)
     {
      if(highArr[i] > rangeHigh) rangeHigh = highArr[i];
      if(lowArr[i] < rangeLow)   rangeLow  = lowArr[i];
     }

   g_profileHigh = rangeHigh;
   g_profileLow  = rangeLow;

   double priceRange = rangeHigh - rangeLow;
   if(priceRange <= 0) return;

   double binSize = priceRange / InpPriceBins;
   if(binSize <= 0) return;

   //--- Initialize bins
   ArrayResize(g_volumeBins, InpPriceBins);
   ArrayResize(g_priceLevels, InpPriceBins);
   ArrayInitialize(g_volumeBins, 0);

   for(int b = 0; b < InpPriceBins; b++)
      g_priceLevels[b] = rangeLow + (b + 0.5) * binSize;

   //--- Distribute volume into bins using OHLC distribution
   //--- Each bar's volume is distributed across all bins that the bar's range covers
   for(int i = 0; i < lookback; i++)
     {
      double barHigh  = highArr[i];
      double barLow   = lowArr[i];
      double barClose = closeArr[i];
      long   barVol   = volArr[i];

      if(barVol <= 0) continue;

      //--- Determine which bins the bar covers
      int binStart = (int)MathFloor((barLow - rangeLow) / binSize);
      int binEnd   = (int)MathFloor((barHigh - rangeLow) / binSize);

      binStart = MathMax(0, binStart);
      binEnd   = MathMin(InpPriceBins - 1, binEnd);

      int coveredBins = binEnd - binStart + 1;
      if(coveredBins <= 0) continue;

      //--- Weight volume toward close price bin (close gets 2x weight)
      int closeBin = (int)MathFloor((barClose - rangeLow) / binSize);
      closeBin = MathMax(0, MathMin(InpPriceBins - 1, closeBin));

      double totalWeight = coveredBins + 1.0; // +1 for the extra weight on close bin
      double perBinVol = (double)barVol / totalWeight;

      for(int b = binStart; b <= binEnd; b++)
        {
         g_volumeBins[b] += perBinVol;
         if(b == closeBin)
            g_volumeBins[b] += perBinVol; // extra weight at close
        }
     }

   //--- Find POC (bin with highest volume)
   double maxVol = 0;
   int    pocBin = 0;
   for(int b = 0; b < InpPriceBins; b++)
     {
      if(g_volumeBins[b] > maxVol)
        {
         maxVol = g_volumeBins[b];
         pocBin = b;
        }
     }
   g_poc = g_priceLevels[pocBin];

   //--- Calculate total volume
   double totalVolume = 0;
   for(int b = 0; b < InpPriceBins; b++)
      totalVolume += g_volumeBins[b];

   if(totalVolume <= 0) return;

   //--- Calculate Value Area (70% of volume centered on POC)
   double vaTarget = totalVolume * (InpValueAreaPct / 100.0);
   double vaVolume = g_volumeBins[pocBin];
   int    vaUpper  = pocBin;
   int    vaLower  = pocBin;

   while(vaVolume < vaTarget && (vaLower > 0 || vaUpper < InpPriceBins - 1))
     {
      double volAbove = 0;
      double volBelow = 0;

      if(vaUpper < InpPriceBins - 1)
         volAbove = g_volumeBins[vaUpper + 1];
      if(vaLower > 0)
         volBelow = g_volumeBins[vaLower - 1];

      if(volAbove >= volBelow && vaUpper < InpPriceBins - 1)
        {
         vaUpper++;
         vaVolume += g_volumeBins[vaUpper];
        }
      else if(vaLower > 0)
        {
         vaLower--;
         vaVolume += g_volumeBins[vaLower];
        }
      else if(vaUpper < InpPriceBins - 1)
        {
         vaUpper++;
         vaVolume += g_volumeBins[vaUpper];
        }
      else
         break;
     }

   g_vah = rangeLow + (vaUpper + 1) * binSize;
   g_val = rangeLow + vaLower * binSize;

   //--- Detect HVN and LVN zones
   DetectVolumeNodes(totalVolume);
  }

//+------------------------------------------------------------------+
//| Detect High Volume Nodes and Low Volume Nodes                    |
//+------------------------------------------------------------------+
void DetectVolumeNodes(double totalVolume)
  {
   double avgVolPerBin = totalVolume / InpPriceBins;
   double hvnThreshold = avgVolPerBin * 1.5;
   double lvnThreshold = avgVolPerBin * 0.5;

   g_hvnCount = 0;
   g_lvnCount = 0;
   ArrayResize(g_hvnLevels, InpPriceBins);
   ArrayResize(g_lvnLevels, InpPriceBins);

   for(int b = 0; b < InpPriceBins; b++)
     {
      if(g_volumeBins[b] >= hvnThreshold)
        {
         g_hvnLevels[g_hvnCount] = g_priceLevels[b];
         g_hvnCount++;
        }
      else if(g_volumeBins[b] <= lvnThreshold)
        {
         g_lvnLevels[g_lvnCount] = g_priceLevels[b];
         g_lvnCount++;
        }
     }
  }

//+------------------------------------------------------------------+
//| Evaluate trade signals based on volume profile                   |
//+------------------------------------------------------------------+
void EvaluateTradeSignals()
  {
   if(g_poc == 0 || g_vah == 0 || g_val == 0)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double atr = g_atrBuffer[1]; // completed bar ATR
   if(atr <= 0) return;

   double proximity = atr * InpProximityATR;

   double ema200 = g_ema200Buffer[1];
   double ema50  = g_ema50Buffer[1];
   double rsi    = g_rsiBuffer[1];

   bool trendUp   = !InpUseTrendFilter || (bid > ema200 && ema50 > ema200);
   bool trendDown = !InpUseTrendFilter || (bid < ema200 && ema50 < ema200);

   //--- Get recent candle data for confirmation
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
   double open1  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double open2  = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double low1   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double high1  = iHigh(_Symbol, PERIOD_CURRENT, 1);

   //--- Mean Reversion Signals
   if(InpTradeMode == MODE_MEAN_REVERSION || InpTradeMode == MODE_HYBRID)
     {
      //--- Buy at VAL: Price near VAL with bullish rejection
      if(MathAbs(low1 - g_val) <= proximity || (bid <= g_val + proximity && bid >= g_val - proximity))
        {
         bool bullishCandle = close1 > open1;
         bool rejectionWick = (open1 - low1) > (high1 - close1) * 1.5;
         bool rsiOK = !InpUseRSIFilter || rsi < InpRSIOversold + 10;

         if(bullishCandle && (rejectionWick || InpConfirmBars <= 1) && rsiOK && trendUp)
           {
            double sl = g_val - atr * InpATRMultSL;
            double tp = g_poc; // target POC
            if(tp - ask < atr * 0.5)
               tp = ask + atr * InpATRMultTP; // fallback if POC too close

            OpenTrade(ORDER_TYPE_BUY, ask, sl, tp, "MR_VAL_Buy");
           }
        }

      //--- Sell at VAH: Price near VAH with bearish rejection
      if(MathAbs(high1 - g_vah) <= proximity || (bid >= g_vah - proximity && bid <= g_vah + proximity))
        {
         bool bearishCandle = close1 < open1;
         bool rejectionWick = (high1 - open1) > (close1 - low1) * 1.5;
         bool rsiOK = !InpUseRSIFilter || rsi > InpRSIOverbought - 10;

         if(bearishCandle && (rejectionWick || InpConfirmBars <= 1) && rsiOK && trendDown)
           {
            double sl = g_vah + atr * InpATRMultSL;
            double tp = g_poc; // target POC
            if(bid - tp < atr * 0.5)
               tp = bid - atr * InpATRMultTP; // fallback if POC too close

            OpenTrade(ORDER_TYPE_SELL, bid, sl, tp, "MR_VAH_Sell");
           }
        }
     }

   //--- Breakout Signals
   if(InpTradeMode == MODE_BREAKOUT || InpTradeMode == MODE_HYBRID)
     {
      //--- Bullish breakout above VAH
      if(close1 > g_vah && close2 <= g_vah)
        {
         bool momentumOK = close1 > open1;
         bool rsiOK = !InpUseRSIFilter || (rsi > 50 && rsi < InpRSIOverbought);

         if(momentumOK && rsiOK && trendUp)
           {
            double sl = g_vah - atr * (InpATRMultSL * 0.8);
            double tp = FindNextHVNAbove(ask);
            if(tp <= ask || tp - ask < atr)
               tp = ask + atr * InpATRMultTP;

            OpenTrade(ORDER_TYPE_BUY, ask, sl, tp, "BO_VAH_Buy");
           }
        }

      //--- Bearish breakout below VAL
      if(close1 < g_val && close2 >= g_val)
        {
         bool momentumOK = close1 < open1;
         bool rsiOK = !InpUseRSIFilter || (rsi < 50 && rsi > InpRSIOversold);

         if(momentumOK && rsiOK && trendDown)
           {
            double sl = g_val + atr * (InpATRMultSL * 0.8);
            double tp = FindNextHVNBelow(bid);
            if(tp >= bid || bid - tp < atr)
               tp = bid - atr * InpATRMultTP;

            OpenTrade(ORDER_TYPE_SELL, bid, sl, tp, "BO_VAL_Sell");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Find the next HVN above the given price                          |
//+------------------------------------------------------------------+
double FindNextHVNAbove(double price)
  {
   double nearest = 0;
   double minDist = DBL_MAX;
   for(int i = 0; i < g_hvnCount; i++)
     {
      if(g_hvnLevels[i] > price)
        {
         double dist = g_hvnLevels[i] - price;
         if(dist < minDist)
           {
            minDist = dist;
            nearest = g_hvnLevels[i];
           }
        }
     }
   return nearest;
  }

//+------------------------------------------------------------------+
//| Find the next HVN below the given price                          |
//+------------------------------------------------------------------+
double FindNextHVNBelow(double price)
  {
   double nearest = 0;
   double minDist = DBL_MAX;
   for(int i = 0; i < g_hvnCount; i++)
     {
      if(g_hvnLevels[i] < price)
        {
         double dist = price - g_hvnLevels[i];
         if(dist < minDist)
           {
            minDist = dist;
            nearest = g_hvnLevels[i];
           }
        }
     }
   return nearest;
  }

//+------------------------------------------------------------------+
//| Open a trade with risk-based position sizing                     |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, double price, double sl, double tp,
               string comment)
  {
   symInfo.Refresh();
   double point = symInfo.Point();
   int    digits = symInfo.Digits();

   price = NormalizeDouble(price, digits);
   sl    = NormalizeDouble(sl, digits);
   tp    = NormalizeDouble(tp, digits);

   //--- Calculate position size based on risk
   double riskAmount = accInfo.Balance() * (InpRiskPercent / 100.0);
   double slDistance = MathAbs(price - sl);

   if(slDistance <= 0)
      return;

   double tickValue = symInfo.TickValue();
   double tickSize  = symInfo.TickSize();

   if(tickValue <= 0 || tickSize <= 0)
      return;

   double lotSize = (riskAmount * tickSize) / (slDistance * tickValue);

   double lotMin  = symInfo.LotsMin();
   double lotMax  = symInfo.LotsMax();
   double lotStep = symInfo.LotsStep();

   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(lotMin, MathMin(lotMax, lotSize));
   lotSize = NormalizeDouble(lotSize, 2);

   if(lotSize < lotMin)
      return;

   //--- Validate SL/TP distances
   double minStops = symInfo.StopsLevel() * point;
   if(minStops > 0)
     {
      if(MathAbs(price - sl) < minStops)
        {
         if(orderType == ORDER_TYPE_BUY)
            sl = price - minStops;
         else
            sl = price + minStops;
         sl = NormalizeDouble(sl, digits);
        }
      if(MathAbs(price - tp) < minStops)
        {
         if(orderType == ORDER_TYPE_BUY)
            tp = price + minStops;
         else
            tp = price - minStops;
         tp = NormalizeDouble(tp, digits);
        }
     }

   string fullComment = StringFormat("VP_%s_M%d", comment, InpMagicNumber);

   bool result = false;
   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(lotSize, _Symbol, price, sl, tp, fullComment);
   else
      result = trade.Sell(lotSize, _Symbol, price, sl, tp, fullComment);

   if(result)
     {
      g_dailyTradeCount++;
      PrintFormat("Trade opened: %s | Lots: %.2f | Entry: %.5f | SL: %.5f | TP: %.5f",
                  comment, lotSize, price, sl, tp);
     }
   else
      PrintFormat("Trade failed: %s | Error: %d", comment, GetLastError());
  }

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, breakeven)                 |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   double atr = g_atrBuffer[1];
   if(atr <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Symbol() != _Symbol)
         continue;
      if(posInfo.Magic() != InpMagicNumber)
         continue;

      double posPrice   = posInfo.PriceOpen();
      double posSL      = posInfo.StopLoss();
      double posTP      = posInfo.TakeProfit();
      double posCurrent = posInfo.PriceCurrent();
      ulong  ticket     = posInfo.Ticket();
      int    digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      //--- Breakeven logic
      if(InpUseBreakeven)
        {
         double beDistance = atr * InpBreakevenATR;

         if(posInfo.PositionType() == POSITION_TYPE_BUY)
           {
            if(posCurrent - posPrice >= beDistance && posSL < posPrice)
              {
               double newSL = NormalizeDouble(posPrice + symInfo.Point() * 5, digits);
               trade.PositionModify(ticket, newSL, posTP);
              }
           }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL)
           {
            if(posPrice - posCurrent >= beDistance && (posSL > posPrice || posSL == 0))
              {
               double newSL = NormalizeDouble(posPrice - symInfo.Point() * 5, digits);
               trade.PositionModify(ticket, newSL, posTP);
              }
           }
        }

      //--- Trailing stop logic
      if(InpUseTrailingStop)
        {
         double trailDist = atr * InpTrailATRMult;

         if(posInfo.PositionType() == POSITION_TYPE_BUY)
           {
            double newSL = NormalizeDouble(posCurrent - trailDist, digits);
            if(newSL > posSL && newSL > posPrice)
               trade.PositionModify(ticket, newSL, posTP);
           }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL)
           {
            double newSL = NormalizeDouble(posCurrent + trailDist, digits);
            if((newSL < posSL || posSL == 0) && newSL < posPrice)
               trade.PositionModify(ticket, newSL, posTP);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Count positions for this EA                                      |
//+------------------------------------------------------------------+
int CountPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posInfo.SelectByIndex(i))
        {
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Check if within allowed trading session                          |
//+------------------------------------------------------------------+
bool IsWithinSession()
  {
   if(!InpUseSessionFilter)
      return true;

   MqlDateTime dt;
   TimeCurrent(dt);

   if(InpSessionStartHour < InpSessionEndHour)
      return (dt.hour >= InpSessionStartHour && dt.hour < InpSessionEndHour);
   else // overnight session
      return (dt.hour >= InpSessionStartHour || dt.hour < InpSessionEndHour);
  }

//+------------------------------------------------------------------+
//| Reset daily trade counter                                        |
//+------------------------------------------------------------------+
void ResetDailyCounterIfNeeded()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));

   if(today != g_lastTradeDay)
     {
      g_lastTradeDay = today;
      g_dailyTradeCount = 0;
     }
  }

//+------------------------------------------------------------------+
//| Draw POC, VAH, VAL lines on chart                               |
//+------------------------------------------------------------------+
void DrawProfileLevels()
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   DrawHLine(g_prefix + "POC", g_poc, InpPOCColor, STYLE_SOLID, 2,
             StringFormat("POC %."+IntegerToString(digits)+"f", g_poc));

   DrawHLine(g_prefix + "VAH", g_vah, InpVAHColor, STYLE_DASH, 1,
             StringFormat("VAH %."+IntegerToString(digits)+"f", g_vah));

   DrawHLine(g_prefix + "VAL", g_val, InpVALColor, STYLE_DASH, 1,
             StringFormat("VAL %."+IntegerToString(digits)+"f", g_val));

   //--- Draw HVN markers
   for(int i = 0; i < g_hvnCount && i < 10; i++)
     {
      string name = g_prefix + "HVN_" + IntegerToString(i);
      DrawHLine(name, g_hvnLevels[i], clrDarkGreen, STYLE_DOT, 1, "");
     }

   //--- Info panel
   DrawInfoPanel();

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Draw a horizontal line                                           |
//+------------------------------------------------------------------+
void DrawHLine(string name, double price, color clr,
               ENUM_LINE_STYLE style, int width, string tooltip)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   else
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   if(tooltip != "")
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
  }

//+------------------------------------------------------------------+
//| Draw information panel on chart                                  |
//+------------------------------------------------------------------+
void DrawInfoPanel()
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   string fmt = "%." + IntegerToString(digits) + "f";

   string info = StringFormat(
      "=== Volume Profile EA ===\n"
      "Mode: %s\n"
      "POC:  " + fmt + "\n"
      "VAH:  " + fmt + "\n"
      "VAL:  " + fmt + "\n"
      "HVNs: %d | LVNs: %d\n"
      "Positions: %d/%d\n"
      "Daily Trades: %d/%d",
      EnumToString(InpTradeMode),
      g_poc, g_vah, g_val,
      g_hvnCount, g_lvnCount,
      CountPositions(), InpMaxPositions,
      g_dailyTradeCount, InpMaxDailyTrades);

   string panelName = g_prefix + "InfoPanel";
   if(ObjectFind(0, panelName) < 0)
      ObjectCreate(0, panelName, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, panelName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, panelName, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, panelName, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, panelName, OBJPROP_TEXT, info);
   ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
   ObjectSetInteger(0, panelName, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Clean up all chart objects created by this EA                    |
//+------------------------------------------------------------------+
void CleanupChartObjects()
  {
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
     }
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
