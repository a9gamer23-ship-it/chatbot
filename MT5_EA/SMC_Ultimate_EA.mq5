//+------------------------------------------------------------------+
//|                                           SMC_Ultimate_EA.mq5    |
//|                     Smart Money Concepts - 10 Strategy EA        |
//|          Ported from TradingView LuxAlgo SMC+ Indicator          |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property link      ""
#property version   "1.00"
#property strict
#property description "10-Strategy Smart Money Concepts EA with graphical objects"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                             |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY
{
   STRATEGY_1_CHOCH_OB_RETEST       = 1,  // 1. CHoCH + Internal OB Retest (85%)
   STRATEGY_2_SWEEP_BOS             = 2,  // 2. SSL/BSL Sweep + BOS (82%)
   STRATEGY_3_IDM_CONTINUATION      = 3,  // 3. IDM Taken Swing Continuation (80%)
   STRATEGY_4_SWING_BOS_RETEST      = 4,  // 4. Swing BOS Retest (78%)
   STRATEGY_5_EQH_EQL_FADE          = 5,  // 5. EQH/EQL Double-Tap Fade (75%)
   STRATEGY_6_SESSION_LIQ_GRAB      = 6,  // 6. Session Open Liquidity Grab (74%)
   STRATEGY_7_BREAKER_ENTRY         = 7,  // 7. Breaker Block Entry After CHoCH (72%)
   STRATEGY_8_PDH_PDL_SWEEP         = 8,  // 8. PDH/PDL Sweep Reversal (70%)
   STRATEGY_9_FVG_FILL              = 9,  // 9. FVG Fill Entry on Pullback (68%)
   STRATEGY_10_STRONG_WEAK          = 10  // 10. Strong/Weak High/Low Trade (65%)
};

enum ENUM_RISK_MODE
{
   RISK_FIXED_LOT   = 0, // Fixed Lot Size
   RISK_PERCENT     = 1  // Risk % of Balance
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== Strategy Selection ==="
input ENUM_STRATEGY   InpStrategy          = STRATEGY_1_CHOCH_OB_RETEST; // Strategy to Trade
input bool            InpDrawGraphics      = true;                        // Draw Graphical Objects

input group "=== Risk Management ==="
input ENUM_RISK_MODE  InpRiskMode          = RISK_PERCENT;   // Risk Mode
input double          InpRiskPercent       = 1.0;            // Risk % per Trade
input double          InpFixedLot          = 0.01;           // Fixed Lot Size
input double          InpMaxLots           = 1.0;            // Maximum Lot Size
input double          InpRR_Ratio          = 2.0;            // Reward:Risk Ratio
input int             InpMaxSpread         = 30;             // Max Spread (points)
input int             InpSlippage          = 10;             // Max Slippage (points)
input int             InpMaxTrades         = 1;              // Max Concurrent Trades

input group "=== Structure Detection ==="
input int             InpSwingLength       = 50;             // Swing Structure Length
input int             InpInternalLength    = 3;              // Internal Structure Length
input bool            InpConfluenceFilter  = false;          // Internal Confluence Filter

input group "=== Order Blocks ==="
input int             InpMaxOB             = 5;              // Max Order Blocks to Track
input int             InpOB_ATR_Period     = 200;            // OB ATR Filter Period

input group "=== Equal Highs/Lows ==="
input int             InpEQL_Bars          = 3;              // EQH/EQL Confirmation Bars
input double          InpEQL_Threshold     = 0.1;            // EQH/EQL Threshold (ATR mult)

input group "=== Fair Value Gaps ==="
input bool            InpAutoFVGThreshold  = true;           // FVG Auto Threshold
input int             InpFVGExtendBars     = 5;              // FVG Extend Bars

input group "=== Liquidity / Sweeps ==="
input int             InpSweepMaxAge       = 300;            // Sweep Max Pivot Age (bars)
input double          InpSweepMinATR       = 0.0;            // Sweep Min Pierce (ATR mult)
input bool            InpSweepCloseBack    = true;           // Require Sweep Close Back

input group "=== Inducement / IDM ==="
input int             InpIDM_MaxAge        = 180;            // IDM Max Pivot Age (bars)
input bool            InpIDM_CloseBack     = false;          // Require IDM Close Back

input group "=== Breaker Blocks ==="
input int             InpBreakerSearchBars = 25;             // Breaker Origin Search Bars
input int             InpMaxBreakerBlocks  = 12;             // Max Active Breaker Blocks

input group "=== Displacement ==="
input int             InpDispLength        = 20;             // Displacement Average Length
input double          InpDispBodyFactor    = 1.8;            // Displacement Body Multiplier
input double          InpDispRangeFactor   = 1.2;            // Displacement Range Multiplier
input double          InpDispATR_Factor    = 0.8;            // Displacement ATR Multiplier

input group "=== Sessions (Broker Time) ==="
input string          InpAsiaStart         = "00:00";        // Asia Session Start
input string          InpAsiaEnd           = "06:00";        // Asia Session End
input string          InpLondonStart       = "07:00";        // London Kill-zone Start
input string          InpLondonEnd         = "10:00";        // London Kill-zone End
input string          InpNYStart           = "12:30";        // New York Kill-zone Start
input string          InpNYEnd             = "16:00";        // New York Kill-zone End

input group "=== Graphical Settings ==="
input color           InpBullColor         = clrLime;        // Bullish Color
input color           InpBearColor         = clrRed;         // Bearish Color
input color           InpOB_BullColor      = clrDodgerBlue;  // Bullish OB Color
input color           InpOB_BearColor      = clrCoral;       // Bearish OB Color
input color           InpFVG_BullColor     = clrSpringGreen;  // Bullish FVG Color
input color           InpFVG_BearColor     = clrTomato;       // Bearish FVG Color
input color           InpSweepBullColor    = clrLime;        // SSL Sweep Color
input color           InpSweepBearColor    = clrRed;         // BSL Sweep Color
input color           InpBreakerBullColor  = clrGreen;       // Bullish Breaker Color
input color           InpBreakerBearColor  = clrDarkRed;     // Bearish Breaker Color
input color           InpAsiaColor         = clrMediumPurple; // Asia Session Color
input color           InpLondonColor       = clrMediumAquamarine; // London Session Color
input color           InpNYColor           = clrIndianRed;    // New York Session Color
input color           InpDashBG            = clrMidnightBlue; // Dashboard Background
input int             InpDashX             = 20;              // Dashboard X Position
input int             InpDashY             = 30;              // Dashboard Y Position

input group "=== Trade Management ==="
input int             InpMagicNumber       = 20250524;        // EA Magic Number
input bool            InpTrailStop         = true;            // Use Trailing Stop
input double          InpTrailATR_Mult     = 1.5;             // Trailing Stop ATR Multiplier
input int             InpTrailATR_Period   = 14;              // Trailing Stop ATR Period

//+------------------------------------------------------------------+
//| CONSTANTS                                                         |
//+------------------------------------------------------------------+
#define BULLISH   1
#define BEARISH  -1
#define NEUTRAL   0
#define PREFIX    "SMC_EA_"
#define BULLISH_LEG 1
#define BEARISH_LEG 0

//+------------------------------------------------------------------+
//| DATA STRUCTURES                                                   |
//+------------------------------------------------------------------+
struct PivotPoint
{
   double   currentLevel;
   double   lastLevel;
   bool     crossed;
   datetime barTime;
   int      barIndex;
};

struct OrderBlock
{
   double   top;
   double   bottom;
   datetime barTime;
   int      bias;
   bool     valid;
   bool     touched;
   string   objName;
};

struct FairValueGap
{
   double   top;
   double   bottom;
   int      bias;
   datetime barTime;
   bool     valid;
   bool     mitigated;
   string   objName;
};

struct BreakerBlock
{
   double   top;
   double   bottom;
   datetime barTime;
   int      bias;
   bool     isBreaker;
   bool     mitigated;
   bool     valid;
   string   objName;
};

struct EqualLevel
{
   double   level;
   datetime time1;
   datetime time2;
   int      touchCount;
   bool     valid;
   string   objName;
};

struct SessionState
{
   bool     active;
   double   high;
   double   low;
   datetime startTime;
   string   objName;
};

struct TrailingExtremes
{
   double   top;
   double   bottom;
   datetime topTime;
   datetime bottomTime;
};

struct StructureAlert
{
   bool internalBullishBOS;
   bool internalBearishBOS;
   bool internalBullishCHoCH;
   bool internalBearishCHoCH;
   bool swingBullishBOS;
   bool swingBearishBOS;
   bool swingBullishCHoCH;
   bool swingBearishCHoCH;
   bool bullishSweep;
   bool bearishSweep;
   bool bullishIDM;
   bool bearishIDM;
   bool bullishDisplacement;
   bool bearishDisplacement;
};

struct TradeSignal
{
   int      direction;
   double   entryPrice;
   double   stopLoss;
   double   takeProfit;
   string   reason;
   bool     valid;
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         g_trade;
CPositionInfo  g_posInfo;
CSymbolInfo    g_symInfo;

// Pivots
PivotPoint     g_swingHigh, g_swingLow;
PivotPoint     g_internalHigh, g_internalLow;
PivotPoint     g_eqHigh, g_eqLow;

// Trends
int            g_swingTrend  = NEUTRAL;
int            g_internalTrend = NEUTRAL;

// Order Blocks
OrderBlock     g_internalOB[];
OrderBlock     g_swingOB[];

// Fair Value Gaps
FairValueGap   g_fvg[];

// Breaker Blocks
BreakerBlock   g_breakerBlocks[];

// Equal Levels
EqualLevel     g_equalHighs[];
EqualLevel     g_equalLows[];

// Sessions
SessionState   g_asiaSession, g_londonSession, g_nySession;

// Trailing Extremes
TrailingExtremes g_trailing;

// Structure Alerts
StructureAlert g_alerts;

// Previous Day/Week
double         g_prevDayHigh, g_prevDayLow, g_prevDayOpen, g_prevDayClose;
double         g_prevWeekHigh, g_prevWeekLow;

// IDM tracking
double         g_bullIDM_Level = 0;
datetime       g_bullIDM_Time  = 0;
int            g_bullIDM_Bar   = -1;
bool           g_bullIDM_Taken = true;

double         g_bearIDM_Level = 0;
datetime       g_bearIDM_Time  = 0;
int            g_bearIDM_Bar   = -1;
bool           g_bearIDM_Taken = true;

// Leg tracking
int            g_currentLegSwing    = -1;
int            g_currentLegInternal = -1;

// ATR handles
int            g_atrHandle200;
int            g_atrHandle14;
int            g_atrHandleDisp;
int            g_atrTrailHandle;
double         g_atr200 = 0;
double         g_atr14  = 0;
double         g_atrDisp = 0;
double         g_atrTrail = 0;

// Bar tracking
datetime       g_lastBarTime = 0;
int            g_barCount    = 0;
int            g_objCounter  = 0;

// CHoCH retest pending (Strategy 1)
bool           g_chochPending     = false;
int            g_chochDirection   = 0;
double         g_chochOB_Top      = 0;
double         g_chochOB_Bottom   = 0;
datetime       g_chochOB_Time     = 0;
int            g_chochBar         = 0;

// Sweep+BOS pending (Strategy 2)
bool           g_sweepPending     = false;
int            g_sweepDirection   = 0;
double         g_sweepLevel       = 0;
int            g_sweepBar         = 0;

// BOS retest pending (Strategy 4)
bool           g_bosRetestPending = false;
int            g_bosDirection     = 0;
double         g_bosLevel         = 0;
int            g_bosBar           = 0;

// Breaker retest pending (Strategy 7)
bool           g_breakerPending   = false;
int            g_breakerDirection = 0;
double         g_breakerTop       = 0;
double         g_breakerBottom    = 0;
int            g_breakerBar       = 0;

// Session grab pending (Strategy 6)
bool           g_sessionGrabPending = false;
int            g_sessionGrabDir     = 0;
double         g_sessionGrabEntry   = 0;
double         g_sessionGrabStop    = 0;
int            g_sessionGrabBar     = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_symInfo.Name(_Symbol);
   g_symInfo.Refresh();

   g_atrHandle200  = iATR(_Symbol, PERIOD_CURRENT, InpOB_ATR_Period);
   g_atrHandle14   = iATR(_Symbol, PERIOD_CURRENT, 14);
   g_atrHandleDisp = iATR(_Symbol, PERIOD_CURRENT, InpDispLength);
   g_atrTrailHandle = iATR(_Symbol, PERIOD_CURRENT, InpTrailATR_Period);

   if(g_atrHandle200 == INVALID_HANDLE || g_atrHandle14 == INVALID_HANDLE)
   {
      Print("Failed to create ATR indicators");
      return(INIT_FAILED);
   }

   InitPivot(g_swingHigh);
   InitPivot(g_swingLow);
   InitPivot(g_internalHigh);
   InitPivot(g_internalLow);
   InitPivot(g_eqHigh);
   InitPivot(g_eqLow);

   InitSession(g_asiaSession);
   InitSession(g_londonSession);
   InitSession(g_nySession);

   g_trailing.top = 0;
   g_trailing.bottom = 0;
   g_trailing.topTime = 0;
   g_trailing.bottomTime = 0;

   ArrayResize(g_internalOB, 0);
   ArrayResize(g_swingOB, 0);
   ArrayResize(g_fvg, 0);
   ArrayResize(g_breakerBlocks, 0);
   ArrayResize(g_equalHighs, 0);
   ArrayResize(g_equalLows, 0);

   if(InpDrawGraphics)
      DrawDashboard();

   Print("SMC Ultimate EA initialized. Strategy: ", EnumToString(InpStrategy));
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, PREFIX);
   IndicatorRelease(g_atrHandle200);
   IndicatorRelease(g_atrHandle14);
   IndicatorRelease(g_atrHandleDisp);
   IndicatorRelease(g_atrTrailHandle);
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBar())
   {
      if(InpTrailStop)
         ManageTrailingStop();
      return;
   }

   g_barCount++;

   g_symInfo.Refresh();
   if(g_symInfo.Spread() > InpMaxSpread)
      return;

   UpdateATR();
   if(g_atr200 <= 0 || g_atr14 <= 0)
      return;

   ResetAlerts();
   UpdatePreviousLevels();
   UpdateSessions();
   DetectStructure();
   DetectOrderBlocks();
   DetectFVG();
   DetectEqualLevels();
   DetectSweeps();
   DetectIDM();
   DetectDisplacement();
   DetectBreakerBlocks();
   UpdateTrailingExtremes();
   MitigateOrderBlocks();
   MitigateFVG();
   MitigateBreakers();

   if(InpDrawGraphics)
   {
      DrawStructureObjects();
      DrawOrderBlockObjects();
      DrawFVGObjects();
      DrawSweepObjects();
      DrawSessionObjects();
      DrawPreviousLevels();
      DrawStrongWeakLevels();
      UpdateDashboard();
   }

   TradeSignal signal;
   signal.valid = false;

   switch(InpStrategy)
   {
      case STRATEGY_1_CHOCH_OB_RETEST:   signal = Strategy1_CHoCH_OB();       break;
      case STRATEGY_2_SWEEP_BOS:         signal = Strategy2_SweepBOS();       break;
      case STRATEGY_3_IDM_CONTINUATION:  signal = Strategy3_IDM();            break;
      case STRATEGY_4_SWING_BOS_RETEST:  signal = Strategy4_SwingBOS();       break;
      case STRATEGY_5_EQH_EQL_FADE:      signal = Strategy5_EQH_EQL();       break;
      case STRATEGY_6_SESSION_LIQ_GRAB:  signal = Strategy6_SessionGrab();    break;
      case STRATEGY_7_BREAKER_ENTRY:     signal = Strategy7_Breaker();        break;
      case STRATEGY_8_PDH_PDL_SWEEP:     signal = Strategy8_PDH_PDL();        break;
      case STRATEGY_9_FVG_FILL:          signal = Strategy9_FVG();            break;
      case STRATEGY_10_STRONG_WEAK:      signal = Strategy10_StrongWeak();    break;
   }

   if(signal.valid)
      ExecuteTrade(signal);

   if(InpTrailStop)
      ManageTrailingStop();
}

//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                  |
//+------------------------------------------------------------------+
void InitPivot(PivotPoint &p)
{
   p.currentLevel = 0;
   p.lastLevel    = 0;
   p.crossed      = false;
   p.barTime      = 0;
   p.barIndex     = -1;
}

void InitSession(SessionState &s)
{
   s.active    = false;
   s.high      = 0;
   s.low       = 0;
   s.startTime = 0;
   s.objName   = "";
}

void ResetAlerts()
{
   ZeroMemory(g_alerts);
}

bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == g_lastBarTime) return false;
   g_lastBarTime = currentBarTime;
   return true;
}

string ObjName(string type)
{
   g_objCounter++;
   return PREFIX + type + "_" + IntegerToString(g_objCounter);
}

void UpdateATR()
{
   double buf[];
   if(CopyBuffer(g_atrHandle200, 0, 1, 1, buf) > 0) g_atr200 = buf[0];
   if(CopyBuffer(g_atrHandle14, 0, 1, 1, buf) > 0)  g_atr14  = buf[0];
   if(CopyBuffer(g_atrHandleDisp, 0, 1, 1, buf) > 0) g_atrDisp = buf[0];
   if(CopyBuffer(g_atrTrailHandle, 0, 1, 1, buf) > 0) g_atrTrail = buf[0];
}

int CountOpenTrades()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_posInfo.SelectByIndex(i))
         if(g_posInfo.Symbol() == _Symbol && g_posInfo.Magic() == InpMagicNumber)
            count++;
   }
   return count;
}

double CalculateLotSize(double stopDistPoints)
{
   if(InpRiskMode == RISK_FIXED_LOT)
      return MathMin(InpFixedLot, InpMaxLots);

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   if(tickValue <= 0 || tickSize <= 0 || stopDistPoints <= 0)
      return minLot;

   double riskMoney  = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   double pointValue = tickValue / tickSize * _Point;
   double lots       = riskMoney / (stopDistPoints * pointValue);

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, InpMaxLots);

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| STRUCTURE DETECTION                                               |
//+------------------------------------------------------------------+
int DetectLeg(int size, int shift)
{
   double pivotHigh = iHigh(_Symbol, PERIOD_CURRENT, shift + size);
   double pivotLow  = iLow(_Symbol, PERIOD_CURRENT, shift + size);

   double highest = pivotHigh;
   double lowest  = pivotLow;

   for(int i = shift; i < shift + size; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(h > highest) highest = h;
      if(l < lowest)  lowest  = l;
   }

   if(pivotHigh > highest) return BEARISH_LEG;
   if(pivotLow < lowest)   return BULLISH_LEG;
   return -1;
}

void DetectPivots(int size, PivotPoint &highPivot, PivotPoint &lowPivot, bool isInternal)
{
   int leg = DetectLeg(size, 1);
   if(leg < 0) return;

   int prevLeg = DetectLeg(size, 2);

   bool newLeg = (leg != prevLeg && prevLeg >= 0);
   if(!newLeg) return;

   if(leg == BULLISH_LEG)
   {
      double pivotLowVal = iLow(_Symbol, PERIOD_CURRENT, 1 + size);
      datetime pivotTime = iTime(_Symbol, PERIOD_CURRENT, 1 + size);
      int pivotIndex     = g_barCount - (1 + size);

      lowPivot.lastLevel    = lowPivot.currentLevel;
      lowPivot.currentLevel = pivotLowVal;
      lowPivot.crossed      = false;
      lowPivot.barTime      = pivotTime;
      lowPivot.barIndex     = pivotIndex;

      if(!isInternal)
      {
         g_trailing.bottom     = pivotLowVal;
         g_trailing.bottomTime = pivotTime;
      }
   }
   else
   {
      double pivotHighVal = iHigh(_Symbol, PERIOD_CURRENT, 1 + size);
      datetime pivotTime  = iTime(_Symbol, PERIOD_CURRENT, 1 + size);
      int pivotIndex      = g_barCount - (1 + size);

      highPivot.lastLevel    = highPivot.currentLevel;
      highPivot.currentLevel = pivotHighVal;
      highPivot.crossed      = false;
      highPivot.barTime      = pivotTime;
      highPivot.barIndex     = pivotIndex;

      if(!isInternal)
      {
         g_trailing.top     = pivotHighVal;
         g_trailing.topTime = pivotTime;
      }
   }
}

void DetectStructureBreak(PivotPoint &highPivot, PivotPoint &lowPivot, int &trend, bool isInternal)
{
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   // Bullish break
   if(highPivot.currentLevel > 0 && !highPivot.crossed && closePrice > highPivot.currentLevel)
   {
      bool isCHoCH = (trend == BEARISH);

      highPivot.crossed = true;
      trend = BULLISH;

      if(isInternal)
      {
         if(isCHoCH) g_alerts.internalBullishCHoCH = true;
         else        g_alerts.internalBullishBOS   = true;
      }
      else
      {
         if(isCHoCH) g_alerts.swingBullishCHoCH = true;
         else        g_alerts.swingBullishBOS   = true;
      }

      StoreOrderBlock(highPivot, isInternal, BULLISH);
   }

   // Bearish break
   if(lowPivot.currentLevel > 0 && !lowPivot.crossed && closePrice < lowPivot.currentLevel)
   {
      bool isCHoCH = (trend == BULLISH);

      lowPivot.crossed = true;
      trend = BEARISH;

      if(isInternal)
      {
         if(isCHoCH) g_alerts.internalBearishCHoCH = true;
         else        g_alerts.internalBearishBOS   = true;
      }
      else
      {
         if(isCHoCH) g_alerts.swingBearishCHoCH = true;
         else        g_alerts.swingBearishBOS   = true;
      }

      StoreOrderBlock(lowPivot, isInternal, BEARISH);
   }
}

void DetectStructure()
{
   DetectPivots(InpSwingLength, g_swingHigh, g_swingLow, false);
   DetectPivots(InpInternalLength, g_internalHigh, g_internalLow, true);
   DetectPivots(InpEQL_Bars, g_eqHigh, g_eqLow, true);

   DetectStructureBreak(g_swingHigh, g_swingLow, g_swingTrend, false);
   DetectStructureBreak(g_internalHigh, g_internalLow, g_internalTrend, true);
}

//+------------------------------------------------------------------+
//| ORDER BLOCK DETECTION & MANAGEMENT                                |
//+------------------------------------------------------------------+
void StoreOrderBlock(PivotPoint &pivot, bool isInternal, int bias)
{
   if(pivot.barIndex < 0) return;

   int lookback = g_barCount - pivot.barIndex;
   if(lookback < 1 || lookback > 500) return;

   double obHigh = 0, obLow = DBL_MAX;
   datetime obTime = 0;

   // Find the extreme candle between pivot and current
   int bestBar = lookback;
   if(bias == BEARISH)
   {
      double maxH = 0;
      for(int i = 1; i <= lookback && i < Bars(_Symbol, PERIOD_CURRENT); i++)
      {
         double h = iHigh(_Symbol, PERIOD_CURRENT, i);
         if(h > maxH) { maxH = h; bestBar = i; }
      }
   }
   else
   {
      double minL = DBL_MAX;
      for(int i = 1; i <= lookback && i < Bars(_Symbol, PERIOD_CURRENT); i++)
      {
         double l = iLow(_Symbol, PERIOD_CURRENT, i);
         if(l < minL) { minL = l; bestBar = i; }
      }
   }

   if(bestBar >= Bars(_Symbol, PERIOD_CURRENT)) return;

   obHigh = iHigh(_Symbol, PERIOD_CURRENT, bestBar);
   obLow  = iLow(_Symbol, PERIOD_CURRENT, bestBar);
   obTime = iTime(_Symbol, PERIOD_CURRENT, bestBar);

   // Filter volatile bars
   double barRange = obHigh - obLow;
   if(barRange >= 2.0 * g_atr200)
   {
      if(bias == BEARISH) obLow = obHigh;
      else                obHigh = obLow;
   }

   OrderBlock ob;
   ob.top     = obHigh;
   ob.bottom  = obLow;
   ob.barTime = obTime;
   ob.bias    = bias;
   ob.valid   = true;
   ob.touched = false;
   ob.objName = ObjName(isInternal ? "iOB" : "sOB");

   if(isInternal)
   {
      int sz = ArraySize(g_internalOB);
      ArrayResize(g_internalOB, sz + 1);
      g_internalOB[sz] = ob;
      if(ArraySize(g_internalOB) > InpMaxOB * 2)
      {
         // Remove oldest
         for(int i = 0; i < ArraySize(g_internalOB) - 1; i++)
            g_internalOB[i] = g_internalOB[i+1];
         ArrayResize(g_internalOB, ArraySize(g_internalOB) - 1);
      }
   }
   else
   {
      int sz = ArraySize(g_swingOB);
      ArrayResize(g_swingOB, sz + 1);
      g_swingOB[sz] = ob;
      if(ArraySize(g_swingOB) > InpMaxOB * 2)
      {
         for(int i = 0; i < ArraySize(g_swingOB) - 1; i++)
            g_swingOB[i] = g_swingOB[i+1];
         ArrayResize(g_swingOB, ArraySize(g_swingOB) - 1);
      }
   }
}

void DetectOrderBlocks()
{
   // Order blocks are detected in DetectStructureBreak via StoreOrderBlock
}

void MitigateOrderBlocks()
{
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);

   for(int i = ArraySize(g_internalOB) - 1; i >= 0; i--)
   {
      if(!g_internalOB[i].valid) continue;
      if(g_internalOB[i].bias == BEARISH && highPrice > g_internalOB[i].top)
         g_internalOB[i].valid = false;
      if(g_internalOB[i].bias == BULLISH && lowPrice < g_internalOB[i].bottom)
         g_internalOB[i].valid = false;
   }

   for(int i = ArraySize(g_swingOB) - 1; i >= 0; i--)
   {
      if(!g_swingOB[i].valid) continue;
      if(g_swingOB[i].bias == BEARISH && highPrice > g_swingOB[i].top)
         g_swingOB[i].valid = false;
      if(g_swingOB[i].bias == BULLISH && lowPrice < g_swingOB[i].bottom)
         g_swingOB[i].valid = false;
   }
}

//+------------------------------------------------------------------+
//| FAIR VALUE GAP DETECTION                                          |
//+------------------------------------------------------------------+
void DetectFVG()
{
   if(Bars(_Symbol, PERIOD_CURRENT) < 4) return;

   double high0 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low0  = iLow(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 2);
   double open1  = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double high2 = iHigh(_Symbol, PERIOD_CURRENT, 3);
   double low2  = iLow(_Symbol, PERIOD_CURRENT, 3);

   double barDelta = (close1 - open1);
   bool autoThreshOk = true;

   if(InpAutoFVGThreshold && g_atr200 > 0)
   {
      double deltaPercent = MathAbs(barDelta) / (open1 > 0 ? open1 : 1) * 100;
      autoThreshOk = (deltaPercent > 0.01);
   }

   // Bullish FVG
   if(low0 > high2 && close1 > high2 && barDelta > 0 && autoThreshOk)
   {
      FairValueGap fvg;
      fvg.top       = low0;
      fvg.bottom    = high2;
      fvg.bias      = BULLISH;
      fvg.barTime   = iTime(_Symbol, PERIOD_CURRENT, 2);
      fvg.valid     = true;
      fvg.mitigated = false;
      fvg.objName   = ObjName("FVG");

      int sz = ArraySize(g_fvg);
      ArrayResize(g_fvg, sz + 1);
      g_fvg[sz] = fvg;
   }

   // Bearish FVG
   if(high0 < low2 && close1 < low2 && barDelta < 0 && autoThreshOk)
   {
      FairValueGap fvg;
      fvg.top       = low2;
      fvg.bottom    = high0;
      fvg.bias      = BEARISH;
      fvg.barTime   = iTime(_Symbol, PERIOD_CURRENT, 2);
      fvg.valid     = true;
      fvg.mitigated = false;
      fvg.objName   = ObjName("FVG");

      int sz = ArraySize(g_fvg);
      ArrayResize(g_fvg, sz + 1);
      g_fvg[sz] = fvg;
   }

   // Limit array size
   while(ArraySize(g_fvg) > 30)
   {
      for(int i = 0; i < ArraySize(g_fvg) - 1; i++)
         g_fvg[i] = g_fvg[i+1];
      ArrayResize(g_fvg, ArraySize(g_fvg) - 1);
   }
}

void MitigateFVG()
{
   double lowPrice  = iLow(_Symbol, PERIOD_CURRENT, 1);
   double highPrice = iHigh(_Symbol, PERIOD_CURRENT, 1);

   for(int i = ArraySize(g_fvg) - 1; i >= 0; i--)
   {
      if(!g_fvg[i].valid) continue;
      if(g_fvg[i].bias == BULLISH && lowPrice < g_fvg[i].bottom)
         g_fvg[i].valid = false;
      if(g_fvg[i].bias == BEARISH && highPrice > g_fvg[i].top)
         g_fvg[i].valid = false;
   }
}

//+------------------------------------------------------------------+
//| EQUAL HIGHS/LOWS DETECTION                                       |
//+------------------------------------------------------------------+
void DetectEqualLevels()
{
   if(g_eqHigh.currentLevel > 0 && g_eqHigh.lastLevel > 0)
   {
      double diff = MathAbs(g_eqHigh.currentLevel - g_eqHigh.lastLevel);
      if(diff < InpEQL_Threshold * g_atr200 && diff > 0)
      {
         EqualLevel eq;
         eq.level      = (g_eqHigh.currentLevel + g_eqHigh.lastLevel) / 2.0;
         eq.time1      = g_eqHigh.barTime;
         eq.time2      = iTime(_Symbol, PERIOD_CURRENT, 1);
         eq.touchCount = 2;
         eq.valid      = true;
         eq.objName    = ObjName("EQH");

         int sz = ArraySize(g_equalHighs);
         ArrayResize(g_equalHighs, sz + 1);
         g_equalHighs[sz] = eq;
      }
   }

   if(g_eqLow.currentLevel > 0 && g_eqLow.lastLevel > 0)
   {
      double diff = MathAbs(g_eqLow.currentLevel - g_eqLow.lastLevel);
      if(diff < InpEQL_Threshold * g_atr200 && diff > 0)
      {
         EqualLevel eq;
         eq.level      = (g_eqLow.currentLevel + g_eqLow.lastLevel) / 2.0;
         eq.time1      = g_eqLow.barTime;
         eq.time2      = iTime(_Symbol, PERIOD_CURRENT, 1);
         eq.touchCount = 2;
         eq.valid      = true;
         eq.objName    = ObjName("EQL");

         int sz = ArraySize(g_equalLows);
         ArrayResize(g_equalLows, sz + 1);
         g_equalLows[sz] = eq;
      }
   }

   // Limit arrays
   while(ArraySize(g_equalHighs) > 20)
   {
      for(int i = 0; i < ArraySize(g_equalHighs) - 1; i++)
         g_equalHighs[i] = g_equalHighs[i+1];
      ArrayResize(g_equalHighs, ArraySize(g_equalHighs) - 1);
   }
   while(ArraySize(g_equalLows) > 20)
   {
      for(int i = 0; i < ArraySize(g_equalLows) - 1; i++)
         g_equalLows[i] = g_equalLows[i+1];
      ArrayResize(g_equalLows, ArraySize(g_equalLows) - 1);
   }
}

//+------------------------------------------------------------------+
//| LIQUIDITY SWEEP DETECTION                                         |
//+------------------------------------------------------------------+
void DetectSweeps()
{
   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   double minPierce = g_atr14 * InpSweepMinATR;

   // Check swing high sweep (BSL)
   if(g_swingHigh.currentLevel > 0 && g_swingHigh.barIndex > 0)
   {
      int age = g_barCount - g_swingHigh.barIndex;
      if(age > 0 && age <= InpSweepMaxAge)
      {
         if(highPrice > g_swingHigh.currentLevel + minPierce)
         {
            bool closeBackOk = !InpSweepCloseBack || closePrice < g_swingHigh.currentLevel;
            if(closeBackOk)
            {
               g_alerts.bearishSweep = true;
               if(InpDrawGraphics)
                  DrawSweepLabel(iTime(_Symbol, PERIOD_CURRENT, 1), highPrice, "BSL Sweep", InpSweepBearColor, false);
            }
         }
      }
   }

   // Check swing low sweep (SSL)
   if(g_swingLow.currentLevel > 0 && g_swingLow.barIndex > 0)
   {
      int age = g_barCount - g_swingLow.barIndex;
      if(age > 0 && age <= InpSweepMaxAge)
      {
         if(lowPrice < g_swingLow.currentLevel - minPierce)
         {
            bool closeBackOk = !InpSweepCloseBack || closePrice > g_swingLow.currentLevel;
            if(closeBackOk)
            {
               g_alerts.bullishSweep = true;
               if(InpDrawGraphics)
                  DrawSweepLabel(iTime(_Symbol, PERIOD_CURRENT, 1), lowPrice, "SSL Sweep", InpSweepBullColor, true);
            }
         }
      }
   }

   // Check internal sweeps too
   if(g_internalHigh.currentLevel > 0 && g_internalHigh.barIndex > 0)
   {
      int age = g_barCount - g_internalHigh.barIndex;
      if(age > 0 && age <= InpSweepMaxAge)
      {
         if(highPrice > g_internalHigh.currentLevel + minPierce)
         {
            bool closeBackOk = !InpSweepCloseBack || closePrice < g_internalHigh.currentLevel;
            if(closeBackOk)
               g_alerts.bearishSweep = true;
         }
      }
   }

   if(g_internalLow.currentLevel > 0 && g_internalLow.barIndex > 0)
   {
      int age = g_barCount - g_internalLow.barIndex;
      if(age > 0 && age <= InpSweepMaxAge)
      {
         if(lowPrice < g_internalLow.currentLevel - minPierce)
         {
            bool closeBackOk = !InpSweepCloseBack || closePrice > g_internalLow.currentLevel;
            if(closeBackOk)
               g_alerts.bullishSweep = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| INDUCEMENT (IDM) DETECTION                                        |
//+------------------------------------------------------------------+
void DetectIDM()
{
   // Update bullish IDM candidate
   if(g_swingTrend == BULLISH && g_internalLow.currentLevel > 0)
   {
      int age = g_barCount - g_internalLow.barIndex;
      if(age > 0 && age <= InpIDM_MaxAge)
      {
         if(g_bullIDM_Taken || g_bullIDM_Level == 0)
         {
            g_bullIDM_Level = g_internalLow.currentLevel;
            g_bullIDM_Time  = g_internalLow.barTime;
            g_bullIDM_Bar   = g_internalLow.barIndex;
            g_bullIDM_Taken = false;
         }
      }
   }

   if(g_swingTrend != BULLISH && g_bullIDM_Level > 0 && !g_bullIDM_Taken)
   {
      g_bullIDM_Taken = true;
   }

   // Update bearish IDM candidate
   if(g_swingTrend == BEARISH && g_internalHigh.currentLevel > 0)
   {
      int age = g_barCount - g_internalHigh.barIndex;
      if(age > 0 && age <= InpIDM_MaxAge)
      {
         if(g_bearIDM_Taken || g_bearIDM_Level == 0)
         {
            g_bearIDM_Level = g_internalHigh.currentLevel;
            g_bearIDM_Time  = g_internalHigh.barTime;
            g_bearIDM_Bar   = g_internalHigh.barIndex;
            g_bearIDM_Taken = false;
         }
      }
   }

   if(g_swingTrend != BEARISH && g_bearIDM_Level > 0 && !g_bearIDM_Taken)
   {
      g_bearIDM_Taken = true;
   }

   // Check if IDM taken
   double lowPrice  = iLow(_Symbol, PERIOD_CURRENT, 1);
   double highPrice = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   if(g_swingTrend == BULLISH && !g_bullIDM_Taken && g_bullIDM_Level > 0)
   {
      if(lowPrice <= g_bullIDM_Level)
      {
         bool closeBackOk = !InpIDM_CloseBack || closePrice > g_bullIDM_Level;
         if(closeBackOk)
         {
            g_bullIDM_Taken = true;
            g_alerts.bullishIDM = true;
         }
      }
   }

   if(g_swingTrend == BEARISH && !g_bearIDM_Taken && g_bearIDM_Level > 0)
   {
      if(highPrice >= g_bearIDM_Level)
      {
         bool closeBackOk = !InpIDM_CloseBack || closePrice < g_bearIDM_Level;
         if(closeBackOk)
         {
            g_bearIDM_Taken = true;
            g_alerts.bearishIDM = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| DISPLACEMENT DETECTION                                            |
//+------------------------------------------------------------------+
void DetectDisplacement()
{
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
   double openPrice  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);

   double candleBody  = MathAbs(closePrice - openPrice);
   double candleRange = highPrice - lowPrice;

   // Calculate average body and range
   double avgBody = 0, avgRange = 0;
   int count = MathMin(InpDispLength, Bars(_Symbol, PERIOD_CURRENT) - 2);
   for(int i = 2; i <= count + 1; i++)
   {
      avgBody  += MathAbs(iClose(_Symbol, PERIOD_CURRENT, i) - iOpen(_Symbol, PERIOD_CURRENT, i));
      avgRange += iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i);
   }
   if(count > 0) { avgBody /= count; avgRange /= count; }

   bool bullishDisp = closePrice > openPrice &&
                      candleBody > avgBody * InpDispBodyFactor &&
                      candleRange > avgRange * InpDispRangeFactor &&
                      candleRange > g_atr14 * InpDispATR_Factor;

   bool bearishDisp = closePrice < openPrice &&
                      candleBody > avgBody * InpDispBodyFactor &&
                      candleRange > avgRange * InpDispRangeFactor &&
                      candleRange > g_atr14 * InpDispATR_Factor;

   if(bullishDisp) g_alerts.bullishDisplacement = true;
   if(bearishDisp) g_alerts.bearishDisplacement = true;
}

//+------------------------------------------------------------------+
//| BREAKER BLOCK DETECTION                                           |
//+------------------------------------------------------------------+
int FindLastBearishCandle(int lookback)
{
   for(int i = 1; i <= lookback && i < Bars(_Symbol, PERIOD_CURRENT); i++)
      if(iClose(_Symbol, PERIOD_CURRENT, i) < iOpen(_Symbol, PERIOD_CURRENT, i))
         return i;
   return -1;
}

int FindLastBullishCandle(int lookback)
{
   for(int i = 1; i <= lookback && i < Bars(_Symbol, PERIOD_CURRENT); i++)
      if(iClose(_Symbol, PERIOD_CURRENT, i) > iOpen(_Symbol, PERIOD_CURRENT, i))
         return i;
   return -1;
}

void CreateBreakerBlock(bool bullish, bool isBreaker)
{
   int originOffset = bullish ? FindLastBearishCandle(InpBreakerSearchBars) :
                                FindLastBullishCandle(InpBreakerSearchBars);
   if(originOffset < 0) return;

   BreakerBlock bb;
   bb.top       = iHigh(_Symbol, PERIOD_CURRENT, originOffset);
   bb.bottom    = iLow(_Symbol, PERIOD_CURRENT, originOffset);
   bb.barTime   = iTime(_Symbol, PERIOD_CURRENT, originOffset);
   bb.bias      = bullish ? BULLISH : BEARISH;
   bb.isBreaker = isBreaker;
   bb.mitigated = false;
   bb.valid     = true;
   bb.objName   = ObjName(isBreaker ? "BRK" : "MIT");

   int sz = ArraySize(g_breakerBlocks);
   ArrayResize(g_breakerBlocks, sz + 1);
   g_breakerBlocks[sz] = bb;

   while(ArraySize(g_breakerBlocks) > InpMaxBreakerBlocks)
   {
      for(int i = 0; i < ArraySize(g_breakerBlocks) - 1; i++)
         g_breakerBlocks[i] = g_breakerBlocks[i+1];
      ArrayResize(g_breakerBlocks, ArraySize(g_breakerBlocks) - 1);
   }
}

void DetectBreakerBlocks()
{
   bool bullCHoCH = g_alerts.internalBullishCHoCH || g_alerts.swingBullishCHoCH;
   bool bearCHoCH = g_alerts.internalBearishCHoCH || g_alerts.swingBearishCHoCH;
   bool bullBOS   = g_alerts.internalBullishBOS || g_alerts.swingBullishBOS;
   bool bearBOS   = g_alerts.internalBearishBOS || g_alerts.swingBearishBOS;

   if(bullCHoCH) CreateBreakerBlock(true, true);
   if(bearCHoCH) CreateBreakerBlock(false, true);
   if(bullBOS)   CreateBreakerBlock(true, false);
   if(bearBOS)   CreateBreakerBlock(false, false);
}

void MitigateBreakers()
{
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   for(int i = ArraySize(g_breakerBlocks) - 1; i >= 0; i--)
   {
      if(!g_breakerBlocks[i].valid) continue;
      if(g_breakerBlocks[i].bias == BULLISH && closePrice < g_breakerBlocks[i].bottom)
         g_breakerBlocks[i].valid = false;
      if(g_breakerBlocks[i].bias == BEARISH && closePrice > g_breakerBlocks[i].top)
         g_breakerBlocks[i].valid = false;
   }
}

//+------------------------------------------------------------------+
//| SESSION HANDLING                                                  |
//+------------------------------------------------------------------+
bool IsInSession(string startStr, string endStr)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int startH = 0, startM = 0, endH = 0, endM = 0;
   ParseTime(startStr, startH, startM);
   ParseTime(endStr, endH, endM);

   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes   = startH * 60 + startM;
   int endMinutes     = endH * 60 + endM;

   if(startMinutes < endMinutes)
      return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
   else
      return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
}

void ParseTime(string timeStr, int &hours, int &minutes)
{
   string parts[];
   int count = StringSplit(timeStr, ':', parts);
   hours   = (count > 0) ? (int)StringToInteger(parts[0]) : 0;
   minutes = (count > 1) ? (int)StringToInteger(parts[1]) : 0;
}

void UpdateSessionState(SessionState &state, string startStr, string endStr, string name, color clr)
{
   bool inSession = IsInSession(startStr, endStr);
   bool sessionStart = inSession && !state.active;
   bool sessionEnd   = !inSession && state.active;

   if(sessionStart)
   {
      state.active    = true;
      state.high      = iHigh(_Symbol, PERIOD_CURRENT, 0);
      state.low       = iLow(_Symbol, PERIOD_CURRENT, 0);
      state.startTime = TimeCurrent();
   }

   if(inSession && state.active)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, 0);
      double l = iLow(_Symbol, PERIOD_CURRENT, 0);
      if(h > state.high) state.high = h;
      if(l < state.low || state.low == 0)  state.low = l;
   }

   if(sessionEnd)
   {
      state.active = false;
      if(InpDrawGraphics)
      {
         string boxName = ObjName("Session_" + name);
         DrawSessionBox(boxName, state.startTime, state.high, TimeCurrent(), state.low, clr, name);
      }
   }
}

void UpdateSessions()
{
   UpdateSessionState(g_asiaSession, InpAsiaStart, InpAsiaEnd, "Asia", InpAsiaColor);
   UpdateSessionState(g_londonSession, InpLondonStart, InpLondonEnd, "London", InpLondonColor);
   UpdateSessionState(g_nySession, InpNYStart, InpNYEnd, "NY", InpNYColor);
}

//+------------------------------------------------------------------+
//| PREVIOUS LEVELS                                                   |
//+------------------------------------------------------------------+
void UpdatePreviousLevels()
{
   MqlRates daily[];
   if(CopyRates(_Symbol, PERIOD_D1, 1, 1, daily) > 0)
   {
      g_prevDayHigh  = daily[0].high;
      g_prevDayLow   = daily[0].low;
      g_prevDayOpen  = daily[0].open;
      g_prevDayClose = daily[0].close;
   }

   MqlRates weekly[];
   if(CopyRates(_Symbol, PERIOD_W1, 1, 1, weekly) > 0)
   {
      g_prevWeekHigh = weekly[0].high;
      g_prevWeekLow  = weekly[0].low;
   }
}

//+------------------------------------------------------------------+
//| TRAILING EXTREMES                                                 |
//+------------------------------------------------------------------+
void UpdateTrailingExtremes()
{
   double h = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l = iLow(_Symbol, PERIOD_CURRENT, 1);
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 1);

   if(g_trailing.top == 0 || h > g_trailing.top)
   {
      g_trailing.top = h;
      g_trailing.topTime = t;
   }
   if(g_trailing.bottom == 0 || l < g_trailing.bottom)
   {
      g_trailing.bottom = l;
      g_trailing.bottomTime = t;
   }
}

//+------------------------------------------------------------------+
//| ================ STRATEGY IMPLEMENTATIONS ================        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Strategy 1: CHoCH + Internal Order Block Retest (85%)             |
//+------------------------------------------------------------------+
TradeSignal Strategy1_CHoCH_OB()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   // Check for new internal CHoCH
   if(g_alerts.internalBullishCHoCH || g_alerts.internalBearishCHoCH)
   {
      // Find the internal OB that preceded the CHoCH
      for(int i = ArraySize(g_internalOB) - 1; i >= 0; i--)
      {
         if(!g_internalOB[i].valid) continue;

         if(g_alerts.internalBullishCHoCH && g_internalOB[i].bias == BULLISH)
         {
            g_chochPending    = true;
            g_chochDirection  = BULLISH;
            g_chochOB_Top     = g_internalOB[i].top;
            g_chochOB_Bottom  = g_internalOB[i].bottom;
            g_chochOB_Time    = g_internalOB[i].barTime;
            g_chochBar        = g_barCount;
            break;
         }
         if(g_alerts.internalBearishCHoCH && g_internalOB[i].bias == BEARISH)
         {
            g_chochPending    = true;
            g_chochDirection  = BEARISH;
            g_chochOB_Top     = g_internalOB[i].top;
            g_chochOB_Bottom  = g_internalOB[i].bottom;
            g_chochOB_Time    = g_internalOB[i].barTime;
            g_chochBar        = g_barCount;
            break;
         }
      }
   }

   // Wait for price to retest the OB zone
   if(g_chochPending && g_barCount - g_chochBar <= 30)
   {
      double lowPrice  = iLow(_Symbol, PERIOD_CURRENT, 1);
      double highPrice = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

      if(g_chochDirection == BULLISH)
      {
         // Price pulled back into bullish OB
         if(lowPrice <= g_chochOB_Top && lowPrice >= g_chochOB_Bottom && closePrice > g_chochOB_Bottom)
         {
            sig.direction  = BULLISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sig.stopLoss   = g_chochOB_Bottom - g_atr14 * 0.2;
            double riskDist = sig.entryPrice - sig.stopLoss;
            sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
            sig.reason     = "S1: CHoCH+OB Retest BUY";
            sig.valid      = true;
            g_chochPending = false;
         }
      }
      else if(g_chochDirection == BEARISH)
      {
         if(highPrice >= g_chochOB_Bottom && highPrice <= g_chochOB_Top && closePrice < g_chochOB_Top)
         {
            sig.direction  = BEARISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            sig.stopLoss   = g_chochOB_Top + g_atr14 * 0.2;
            double riskDist = sig.stopLoss - sig.entryPrice;
            sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
            sig.reason     = "S1: CHoCH+OB Retest SELL";
            sig.valid      = true;
            g_chochPending = false;
         }
      }
   }
   else if(g_chochPending && g_barCount - g_chochBar > 30)
   {
      g_chochPending = false;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 2: SSL/BSL Sweep + BOS Continuation (82%)                |
//+------------------------------------------------------------------+
TradeSignal Strategy2_SweepBOS()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   // Detect sweep events
   if(g_alerts.bullishSweep)
   {
      g_sweepPending   = true;
      g_sweepDirection = BULLISH;
      g_sweepLevel     = iLow(_Symbol, PERIOD_CURRENT, 1);
      g_sweepBar       = g_barCount;
   }
   if(g_alerts.bearishSweep)
   {
      g_sweepPending   = true;
      g_sweepDirection = BEARISH;
      g_sweepLevel     = iHigh(_Symbol, PERIOD_CURRENT, 1);
      g_sweepBar       = g_barCount;
   }

   // Wait for BOS confirmation after sweep
   if(g_sweepPending && g_barCount - g_sweepBar <= 20)
   {
      if(g_sweepDirection == BULLISH && (g_alerts.internalBullishBOS || g_alerts.swingBullishBOS))
      {
         sig.direction  = BULLISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sig.stopLoss   = g_sweepLevel - g_atr14 * 0.3;
         double riskDist = sig.entryPrice - sig.stopLoss;
         sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
         sig.reason     = "S2: SSL Sweep+BOS BUY";
         sig.valid      = true;
         g_sweepPending = false;
      }
      if(g_sweepDirection == BEARISH && (g_alerts.internalBearishBOS || g_alerts.swingBearishBOS))
      {
         sig.direction  = BEARISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sig.stopLoss   = g_sweepLevel + g_atr14 * 0.3;
         double riskDist = sig.stopLoss - sig.entryPrice;
         sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
         sig.reason     = "S2: BSL Sweep+BOS SELL";
         sig.valid      = true;
         g_sweepPending = false;
      }
   }
   else if(g_sweepPending && g_barCount - g_sweepBar > 20)
   {
      g_sweepPending = false;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 3: IDM Taken -> Swing Continuation (80%)                 |
//+------------------------------------------------------------------+
TradeSignal Strategy3_IDM()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   if(g_alerts.bullishIDM && g_swingTrend == BULLISH)
   {
      sig.direction  = BULLISH;
      sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sig.stopLoss   = iLow(_Symbol, PERIOD_CURRENT, 1) - g_atr14 * 0.3;
      double riskDist = sig.entryPrice - sig.stopLoss;
      sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
      sig.reason     = "S3: IDM Taken BUY (Swing Bull)";
      sig.valid      = true;
   }

   if(g_alerts.bearishIDM && g_swingTrend == BEARISH)
   {
      sig.direction  = BEARISH;
      sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sig.stopLoss   = iHigh(_Symbol, PERIOD_CURRENT, 1) + g_atr14 * 0.3;
      double riskDist = sig.stopLoss - sig.entryPrice;
      sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
      sig.reason     = "S3: IDM Taken SELL (Swing Bear)";
      sig.valid      = true;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 4: Swing BOS Retest (78%)                                |
//+------------------------------------------------------------------+
TradeSignal Strategy4_SwingBOS()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   // Detect new swing BOS
   if(g_alerts.swingBullishBOS && g_swingTrend == BULLISH)
   {
      g_bosRetestPending = true;
      g_bosDirection     = BULLISH;
      g_bosLevel         = g_swingHigh.currentLevel;
      g_bosBar           = g_barCount;
   }
   if(g_alerts.swingBearishBOS && g_swingTrend == BEARISH)
   {
      g_bosRetestPending = true;
      g_bosDirection     = BEARISH;
      g_bosLevel         = g_swingLow.currentLevel;
      g_bosBar           = g_barCount;
   }

   // Wait for retest
   if(g_bosRetestPending && g_barCount - g_bosBar <= 40)
   {
      double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
      double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

      if(g_bosDirection == BULLISH)
      {
         // Price retraces to the broken level and rejects
         if(lowPrice <= g_bosLevel + g_atr14 * 0.5 && lowPrice >= g_bosLevel - g_atr14 * 0.5 && closePrice > g_bosLevel)
         {
            sig.direction  = BULLISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sig.stopLoss   = lowPrice - g_atr14 * 0.5;
            double riskDist = sig.entryPrice - sig.stopLoss;
            sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
            sig.reason     = "S4: Swing BOS Retest BUY";
            sig.valid      = true;
            g_bosRetestPending = false;
         }
      }
      else if(g_bosDirection == BEARISH)
      {
         if(highPrice >= g_bosLevel - g_atr14 * 0.5 && highPrice <= g_bosLevel + g_atr14 * 0.5 && closePrice < g_bosLevel)
         {
            sig.direction  = BEARISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            sig.stopLoss   = highPrice + g_atr14 * 0.5;
            double riskDist = sig.stopLoss - sig.entryPrice;
            sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
            sig.reason     = "S4: Swing BOS Retest SELL";
            sig.valid      = true;
            g_bosRetestPending = false;
         }
      }
   }
   else if(g_bosRetestPending && g_barCount - g_bosBar > 40)
   {
      g_bosRetestPending = false;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 5: EQH/EQL Double-Tap Fade (75%)                        |
//+------------------------------------------------------------------+
TradeSignal Strategy5_EQH_EQL()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   // Check EQH sweep (third touch / sweep)
   for(int i = ArraySize(g_equalHighs) - 1; i >= 0; i--)
   {
      if(!g_equalHighs[i].valid) continue;

      // Price swept above equal highs
      if(highPrice > g_equalHighs[i].level + g_atr14 * 0.05 && closePrice < g_equalHighs[i].level)
      {
         sig.direction  = BEARISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sig.stopLoss   = highPrice + g_atr14 * 0.2;
         double riskDist = sig.stopLoss - sig.entryPrice;
         // Conservative target: midpoint of prior range
         sig.takeProfit = sig.entryPrice - riskDist * MathMin(InpRR_Ratio, 1.5);
         sig.reason     = "S5: EQH Sweep Fade SELL";
         sig.valid      = true;
         g_equalHighs[i].valid = false;
         break;
      }
   }

   if(sig.valid) return sig;

   // Check EQL sweep
   for(int i = ArraySize(g_equalLows) - 1; i >= 0; i--)
   {
      if(!g_equalLows[i].valid) continue;

      if(lowPrice < g_equalLows[i].level - g_atr14 * 0.05 && closePrice > g_equalLows[i].level)
      {
         sig.direction  = BULLISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sig.stopLoss   = lowPrice - g_atr14 * 0.2;
         double riskDist = sig.entryPrice - sig.stopLoss;
         sig.takeProfit = sig.entryPrice + riskDist * MathMin(InpRR_Ratio, 1.5);
         sig.reason     = "S5: EQL Sweep Fade BUY";
         sig.valid      = true;
         g_equalLows[i].valid = false;
         break;
      }
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 6: Session Open Liquidity Grab (74%)                     |
//+------------------------------------------------------------------+
TradeSignal Strategy6_SessionGrab()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   // Check if London is active and Asia has completed
   bool inLondon = IsInSession(InpLondonStart, InpLondonEnd);
   bool inNY     = IsInSession(InpNYStart, InpNYEnd);

   if(!inLondon && !inNY) return sig;

   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   // Check if session grab is pending
   if(g_sessionGrabPending && g_barCount - g_sessionGrabBar <= 10)
   {
      sig.direction  = g_sessionGrabDir;
      sig.entryPrice = (g_sessionGrabDir == BULLISH) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sig.stopLoss   = g_sessionGrabStop;
      double riskDist = MathAbs(sig.entryPrice - sig.stopLoss);
      sig.takeProfit = (g_sessionGrabDir == BULLISH) ? sig.entryPrice + riskDist * InpRR_Ratio : sig.entryPrice - riskDist * InpRR_Ratio;
      sig.reason     = "S6: Session Grab " + (g_sessionGrabDir == BULLISH ? "BUY" : "SELL");
      sig.valid      = true;
      g_sessionGrabPending = false;
      return sig;
   }

   // Check Asia range grab during London
   if(inLondon && !g_asiaSession.active && g_asiaSession.high > 0 && g_asiaSession.low > 0)
   {
      // Sweep above Asia high then close back
      if(highPrice > g_asiaSession.high && closePrice < g_asiaSession.high)
      {
         g_sessionGrabPending = true;
         g_sessionGrabDir     = BEARISH;
         g_sessionGrabStop    = highPrice + g_atr14 * 0.3;
         g_sessionGrabBar     = g_barCount;
      }
      // Sweep below Asia low then close back
      if(lowPrice < g_asiaSession.low && closePrice > g_asiaSession.low)
      {
         g_sessionGrabPending = true;
         g_sessionGrabDir     = BULLISH;
         g_sessionGrabStop    = lowPrice - g_atr14 * 0.3;
         g_sessionGrabBar     = g_barCount;
      }
   }

   // Check London range grab during NY
   if(inNY && !g_londonSession.active && g_londonSession.high > 0 && g_londonSession.low > 0)
   {
      if(highPrice > g_londonSession.high && closePrice < g_londonSession.high)
      {
         g_sessionGrabPending = true;
         g_sessionGrabDir     = BEARISH;
         g_sessionGrabStop    = highPrice + g_atr14 * 0.3;
         g_sessionGrabBar     = g_barCount;
      }
      if(lowPrice < g_londonSession.low && closePrice > g_londonSession.low)
      {
         g_sessionGrabPending = true;
         g_sessionGrabDir     = BULLISH;
         g_sessionGrabStop    = lowPrice - g_atr14 * 0.3;
         g_sessionGrabBar     = g_barCount;
      }
   }

   if(g_sessionGrabPending && g_barCount - g_sessionGrabBar > 10)
      g_sessionGrabPending = false;

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 7: Breaker Block Entry After CHoCH (72%)                 |
//+------------------------------------------------------------------+
TradeSignal Strategy7_Breaker()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   // Check for new CHoCH and register breaker pending
   if(g_alerts.internalBullishCHoCH || g_alerts.swingBullishCHoCH)
   {
      for(int i = ArraySize(g_breakerBlocks) - 1; i >= 0; i--)
      {
         if(g_breakerBlocks[i].valid && g_breakerBlocks[i].isBreaker && g_breakerBlocks[i].bias == BULLISH)
         {
            g_breakerPending   = true;
            g_breakerDirection = BULLISH;
            g_breakerTop       = g_breakerBlocks[i].top;
            g_breakerBottom    = g_breakerBlocks[i].bottom;
            g_breakerBar       = g_barCount;
            break;
         }
      }
   }
   if(g_alerts.internalBearishCHoCH || g_alerts.swingBearishCHoCH)
   {
      for(int i = ArraySize(g_breakerBlocks) - 1; i >= 0; i--)
      {
         if(g_breakerBlocks[i].valid && g_breakerBlocks[i].isBreaker && g_breakerBlocks[i].bias == BEARISH)
         {
            g_breakerPending   = true;
            g_breakerDirection = BEARISH;
            g_breakerTop       = g_breakerBlocks[i].top;
            g_breakerBottom    = g_breakerBlocks[i].bottom;
            g_breakerBar       = g_barCount;
            break;
         }
      }
   }

   // Wait for retest of breaker block
   if(g_breakerPending && g_barCount - g_breakerBar <= 30)
   {
      double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
      double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

      if(g_breakerDirection == BULLISH)
      {
         if(lowPrice <= g_breakerTop && lowPrice >= g_breakerBottom && closePrice > g_breakerBottom)
         {
            sig.direction  = BULLISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sig.stopLoss   = g_breakerBottom - g_atr14 * 0.2;
            double riskDist = sig.entryPrice - sig.stopLoss;
            sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
            sig.reason     = "S7: Breaker Retest BUY";
            sig.valid      = true;
            g_breakerPending = false;
         }
      }
      else
      {
         if(highPrice >= g_breakerBottom && highPrice <= g_breakerTop && closePrice < g_breakerTop)
         {
            sig.direction  = BEARISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            sig.stopLoss   = g_breakerTop + g_atr14 * 0.2;
            double riskDist = sig.stopLoss - sig.entryPrice;
            sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
            sig.reason     = "S7: Breaker Retest SELL";
            sig.valid      = true;
            g_breakerPending = false;
         }
      }
   }
   else if(g_breakerPending && g_barCount - g_breakerBar > 30)
   {
      g_breakerPending = false;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 8: PDH/PDL Liquidity Sweep Reversal (70%)                |
//+------------------------------------------------------------------+
TradeSignal Strategy8_PDH_PDL()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   bool inKillzone = IsInSession(InpLondonStart, InpLondonEnd) || IsInSession(InpNYStart, InpNYEnd);
   if(!inKillzone) return sig;

   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   // PDH sweep
   if(g_prevDayHigh > 0 && highPrice > g_prevDayHigh && closePrice < g_prevDayHigh)
   {
      // Bearish reversal after PDH sweep
      if(g_internalTrend == BEARISH || g_swingTrend == BEARISH)
      {
         sig.direction  = BEARISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sig.stopLoss   = highPrice + g_atr14 * 0.3;
         double riskDist = sig.stopLoss - sig.entryPrice;
         sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
         sig.reason     = "S8: PDH Sweep SELL";
         sig.valid      = true;
      }
   }

   // PDL sweep
   if(g_prevDayLow > 0 && lowPrice < g_prevDayLow && closePrice > g_prevDayLow)
   {
      if(g_internalTrend == BULLISH || g_swingTrend == BULLISH)
      {
         sig.direction  = BULLISH;
         sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sig.stopLoss   = lowPrice - g_atr14 * 0.3;
         double riskDist = sig.entryPrice - sig.stopLoss;
         sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
         sig.reason     = "S8: PDL Sweep BUY";
         sig.valid      = true;
      }
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 9: FVG Fill Entry on Pullback (68%)                      |
//+------------------------------------------------------------------+
TradeSignal Strategy9_FVG()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   double highPrice  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double lowPrice   = iLow(_Symbol, PERIOD_CURRENT, 1);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   for(int i = ArraySize(g_fvg) - 1; i >= 0; i--)
   {
      if(!g_fvg[i].valid || g_fvg[i].mitigated) continue;

      double midpoint = (g_fvg[i].top + g_fvg[i].bottom) / 2.0;

      // Bullish FVG fill - only if swing trend is bullish
      if(g_fvg[i].bias == BULLISH && g_swingTrend == BULLISH)
      {
         // Price pulled back into FVG
         if(lowPrice <= g_fvg[i].top && lowPrice >= g_fvg[i].bottom && closePrice > g_fvg[i].bottom)
         {
            sig.direction  = BULLISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sig.stopLoss   = g_fvg[i].bottom - g_atr14 * 0.2;
            double riskDist = sig.entryPrice - sig.stopLoss;
            sig.takeProfit = sig.entryPrice + riskDist * InpRR_Ratio;
            sig.reason     = "S9: Bullish FVG Fill BUY";
            sig.valid      = true;
            g_fvg[i].mitigated = true;
            break;
         }
      }

      // Bearish FVG fill
      if(g_fvg[i].bias == BEARISH && g_swingTrend == BEARISH)
      {
         if(highPrice >= g_fvg[i].bottom && highPrice <= g_fvg[i].top && closePrice < g_fvg[i].top)
         {
            sig.direction  = BEARISH;
            sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            sig.stopLoss   = g_fvg[i].top + g_atr14 * 0.2;
            double riskDist = sig.stopLoss - sig.entryPrice;
            sig.takeProfit = sig.entryPrice - riskDist * InpRR_Ratio;
            sig.reason     = "S9: Bearish FVG Fill SELL";
            sig.valid      = true;
            g_fvg[i].mitigated = true;
            break;
         }
      }
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Strategy 10: Strong/Weak High/Low Structural Trade (65%)          |
//+------------------------------------------------------------------+
TradeSignal Strategy10_StrongWeak()
{
   TradeSignal sig;
   sig.valid = false;

   if(CountOpenTrades() >= InpMaxTrades) return sig;

   if(g_trailing.top == 0 || g_trailing.bottom == 0) return sig;

   // Determine strong/weak labels
   bool isStrongHigh = (g_swingTrend == BEARISH);
   bool isWeakHigh   = (g_swingTrend == BULLISH);
   bool isStrongLow  = (g_swingTrend == BULLISH);
   bool isWeakLow    = (g_swingTrend == BEARISH);

   // In bullish swing: buy pullbacks targeting the Weak High
   if(g_swingTrend == BULLISH && isWeakHigh)
   {
      // Need an internal OB or BOS for entry confirmation
      if(g_alerts.internalBullishBOS || g_alerts.internalBullishCHoCH)
      {
         // Look for internal OB to enter from
         for(int i = ArraySize(g_internalOB) - 1; i >= 0; i--)
         {
            if(!g_internalOB[i].valid || g_internalOB[i].bias != BULLISH) continue;

            double lowPrice = iLow(_Symbol, PERIOD_CURRENT, 1);
            double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

            if(lowPrice <= g_internalOB[i].top && closePrice > g_internalOB[i].bottom)
            {
               sig.direction  = BULLISH;
               sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               sig.stopLoss   = g_internalOB[i].bottom - g_atr14 * 0.2;
               sig.takeProfit = g_trailing.top; // Target weak high
               double riskDist = sig.entryPrice - sig.stopLoss;
               if(riskDist > 0 && (sig.takeProfit - sig.entryPrice) / riskDist >= 1.0)
               {
                  sig.reason = "S10: Weak High Target BUY";
                  sig.valid  = true;
               }
               break;
            }
         }
      }
   }

   // In bearish swing: sell rallies targeting the Weak Low
   if(!sig.valid && g_swingTrend == BEARISH && isWeakLow)
   {
      if(g_alerts.internalBearishBOS || g_alerts.internalBearishCHoCH)
      {
         for(int i = ArraySize(g_internalOB) - 1; i >= 0; i--)
         {
            if(!g_internalOB[i].valid || g_internalOB[i].bias != BEARISH) continue;

            double highPrice = iHigh(_Symbol, PERIOD_CURRENT, 1);
            double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

            if(highPrice >= g_internalOB[i].bottom && closePrice < g_internalOB[i].top)
            {
               sig.direction  = BEARISH;
               sig.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               sig.stopLoss   = g_internalOB[i].top + g_atr14 * 0.2;
               sig.takeProfit = g_trailing.bottom; // Target weak low
               double riskDist = sig.stopLoss - sig.entryPrice;
               if(riskDist > 0 && (sig.entryPrice - sig.takeProfit) / riskDist >= 1.0)
               {
                  sig.reason = "S10: Weak Low Target SELL";
                  sig.valid  = true;
               }
               break;
            }
         }
      }
   }

   return sig;
}

//+------------------------------------------------------------------+
//| TRADE EXECUTION                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(TradeSignal &signal)
{
   if(!signal.valid) return;

   double stopDist = MathAbs(signal.entryPrice - signal.stopLoss) / _Point;
   if(stopDist < 1) return;

   double lots = CalculateLotSize(stopDist);

   // Normalize prices
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   signal.stopLoss   = NormalizeDouble(signal.stopLoss, digits);
   signal.takeProfit = NormalizeDouble(signal.takeProfit, digits);
   signal.entryPrice = NormalizeDouble(signal.entryPrice, digits);

   bool result = false;

   if(signal.direction == BULLISH)
   {
      result = g_trade.Buy(lots, _Symbol, signal.entryPrice, signal.stopLoss, signal.takeProfit, signal.reason);
   }
   else
   {
      result = g_trade.Sell(lots, _Symbol, signal.entryPrice, signal.stopLoss, signal.takeProfit, signal.reason);
   }

   if(result)
   {
      Print("Trade opened: ", signal.reason, " Lots=", lots, " SL=", signal.stopLoss, " TP=", signal.takeProfit);

      if(InpDrawGraphics)
         DrawTradeArrow(signal.direction, signal.entryPrice, iTime(_Symbol, PERIOD_CURRENT, 0));
   }
   else
   {
      Print("Trade failed: ", signal.reason, " Error=", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| TRAILING STOP MANAGEMENT                                          |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(g_atrTrail <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Symbol() != _Symbol || g_posInfo.Magic() != InpMagicNumber) continue;

      double currentSL = g_posInfo.StopLoss();
      double currentPrice = g_posInfo.PriceCurrent();
      double trailDist = g_atrTrail * InpTrailATR_Mult;
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      if(g_posInfo.PositionType() == POSITION_TYPE_BUY)
      {
         double newSL = NormalizeDouble(currentPrice - trailDist, digits);
         if(newSL > currentSL && newSL < currentPrice)
         {
            g_trade.PositionModify(g_posInfo.Ticket(), newSL, g_posInfo.TakeProfit());
         }
      }
      else if(g_posInfo.PositionType() == POSITION_TYPE_SELL)
      {
         double newSL = NormalizeDouble(currentPrice + trailDist, digits);
         if((newSL < currentSL || currentSL == 0) && newSL > currentPrice)
         {
            g_trade.PositionModify(g_posInfo.Ticket(), newSL, g_posInfo.TakeProfit());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ================ GRAPHICAL OBJECT DRAWING ================        |
//+------------------------------------------------------------------+

void DrawStructureObjects()
{
   datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   // Draw internal structure lines
   if(g_alerts.internalBullishBOS)
      DrawStructureLine(g_internalHigh.barTime, g_internalHigh.currentLevel, currentTime, "iBOS", InpBullColor, STYLE_DASH);
   if(g_alerts.internalBearishBOS)
      DrawStructureLine(g_internalLow.barTime, g_internalLow.currentLevel, currentTime, "iBOS", InpBearColor, STYLE_DASH);
   if(g_alerts.internalBullishCHoCH)
      DrawStructureLine(g_internalHigh.barTime, g_internalHigh.currentLevel, currentTime, "iCHoCH", InpBullColor, STYLE_DASH);
   if(g_alerts.internalBearishCHoCH)
      DrawStructureLine(g_internalLow.barTime, g_internalLow.currentLevel, currentTime, "iCHoCH", InpBearColor, STYLE_DASH);

   // Draw swing structure lines
   if(g_alerts.swingBullishBOS)
      DrawStructureLine(g_swingHigh.barTime, g_swingHigh.currentLevel, currentTime, "BOS", InpBullColor, STYLE_SOLID);
   if(g_alerts.swingBearishBOS)
      DrawStructureLine(g_swingLow.barTime, g_swingLow.currentLevel, currentTime, "BOS", InpBearColor, STYLE_SOLID);
   if(g_alerts.swingBullishCHoCH)
      DrawStructureLine(g_swingHigh.barTime, g_swingHigh.currentLevel, currentTime, "CHoCH", InpBullColor, STYLE_SOLID);
   if(g_alerts.swingBearishCHoCH)
      DrawStructureLine(g_swingLow.barTime, g_swingLow.currentLevel, currentTime, "CHoCH", InpBearColor, STYLE_SOLID);
}

void DrawStructureLine(datetime t1, double price, datetime t2, string label, color clr, ENUM_LINE_STYLE style)
{
   string name = ObjName("Struct_" + label);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, style == STYLE_SOLID ? 2 : 1);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);

   // Label
   string lblName = ObjName("StructLbl_" + label);
   datetime midTime = t1 + (t2 - t1) / 2;
   ObjectCreate(0, lblName, OBJ_TEXT, 0, midTime, price);
   ObjectSetString(0, lblName, OBJPROP_TEXT, label);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, lblName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LOWER);
}

void DrawOrderBlockObjects()
{
   // Draw internal OBs
   for(int i = 0; i < ArraySize(g_internalOB); i++)
   {
      if(!g_internalOB[i].valid) continue;

      string name = g_internalOB[i].objName;
      if(ObjectFind(0, name) >= 0) continue; // already drawn

      datetime rightTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      color clr = (g_internalOB[i].bias == BULLISH) ? InpOB_BullColor : InpOB_BearColor;

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, g_internalOB[i].barTime, g_internalOB[i].top, rightTime, g_internalOB[i].bottom);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);

      // Label
      string lblName = name + "_lbl";
      ObjectCreate(0, lblName, OBJ_TEXT, 0, g_internalOB[i].barTime, (g_internalOB[i].top + g_internalOB[i].bottom) / 2.0);
      ObjectSetString(0, lblName, OBJPROP_TEXT, (g_internalOB[i].bias == BULLISH) ? "iOB+" : "iOB-");
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
   }

   // Draw swing OBs
   for(int i = 0; i < ArraySize(g_swingOB); i++)
   {
      if(!g_swingOB[i].valid) continue;

      string name = g_swingOB[i].objName;
      if(ObjectFind(0, name) >= 0) continue;

      datetime rightTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      color clr = (g_swingOB[i].bias == BULLISH) ? InpOB_BullColor : InpOB_BearColor;

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, g_swingOB[i].barTime, g_swingOB[i].top, rightTime, g_swingOB[i].bottom);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);

      string lblName = name + "_lbl";
      ObjectCreate(0, lblName, OBJ_TEXT, 0, g_swingOB[i].barTime, (g_swingOB[i].top + g_swingOB[i].bottom) / 2.0);
      ObjectSetString(0, lblName, OBJPROP_TEXT, (g_swingOB[i].bias == BULLISH) ? "OB+" : "OB-");
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
   }

   // Draw breaker blocks
   for(int i = 0; i < ArraySize(g_breakerBlocks); i++)
   {
      if(!g_breakerBlocks[i].valid) continue;

      string name = g_breakerBlocks[i].objName;
      if(ObjectFind(0, name) >= 0) continue;

      datetime rightTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      color clr;
      string tag;

      if(g_breakerBlocks[i].isBreaker)
      {
         clr = (g_breakerBlocks[i].bias == BULLISH) ? InpBreakerBullColor : InpBreakerBearColor;
         tag = (g_breakerBlocks[i].bias == BULLISH) ? "B-BRK" : "S-BRK";
      }
      else
      {
         clr = (g_breakerBlocks[i].bias == BULLISH) ? clrRoyalBlue : clrOrangeRed;
         tag = (g_breakerBlocks[i].bias == BULLISH) ? "B-MIT" : "S-MIT";
      }

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, g_breakerBlocks[i].barTime, g_breakerBlocks[i].top, rightTime, g_breakerBlocks[i].bottom);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);

      string lblName = name + "_lbl";
      double lblPrice = (g_breakerBlocks[i].bias == BULLISH) ? g_breakerBlocks[i].bottom : g_breakerBlocks[i].top;
      ObjectCreate(0, lblName, OBJ_TEXT, 0, g_breakerBlocks[i].barTime, lblPrice);
      ObjectSetString(0, lblName, OBJPROP_TEXT, tag);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
   }
}

void DrawFVGObjects()
{
   for(int i = 0; i < ArraySize(g_fvg); i++)
   {
      if(!g_fvg[i].valid) continue;

      string name = g_fvg[i].objName;
      if(ObjectFind(0, name) >= 0) continue;

      color clr = (g_fvg[i].bias == BULLISH) ? InpFVG_BullColor : InpFVG_BearColor;
      datetime rightTime = g_fvg[i].barTime + PeriodSeconds() * InpFVGExtendBars;

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, g_fvg[i].barTime, g_fvg[i].top, rightTime, g_fvg[i].bottom);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);

      string lblName = name + "_lbl";
      ObjectCreate(0, lblName, OBJ_TEXT, 0, g_fvg[i].barTime, (g_fvg[i].top + g_fvg[i].bottom) / 2.0);
      ObjectSetString(0, lblName, OBJPROP_TEXT, (g_fvg[i].bias == BULLISH) ? "FVG+" : "FVG-");
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
   }
}

void DrawSweepObjects()
{
   // Sweep labels are drawn in DetectSweeps via DrawSweepLabel
}

void DrawSweepLabel(datetime t, double price, string text, color clr, bool isBelow)
{
   string name = ObjName("Sweep");
   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, isBelow ? ANCHOR_UPPER : ANCHOR_LOWER);
}

void DrawSessionBox(string name, datetime t1, double top, datetime t2, double bottom, color clr, string label)
{
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, top, t2, bottom);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);

   string lblName = name + "_lbl";
   ObjectCreate(0, lblName, OBJ_TEXT, 0, t1, top);
   ObjectSetString(0, lblName, OBJPROP_TEXT, label);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LOWER);
}

void DrawSessionObjects()
{
   // Session boxes are drawn when session ends in UpdateSessionState
}

void DrawPreviousLevels()
{
   if(g_prevDayHigh <= 0) return;

   DrawHorizontalLevel("PDH", g_prevDayHigh, clrGray, STYLE_DOT);
   DrawHorizontalLevel("PDL", g_prevDayLow, clrGray, STYLE_DOT);
   DrawHorizontalLevel("PDO", g_prevDayOpen, clrDarkGray, STYLE_DOT);
   DrawHorizontalLevel("PDC", g_prevDayClose, clrDarkGray, STYLE_DOT);

   if(g_prevWeekHigh > 0)
   {
      DrawHorizontalLevel("PWH", g_prevWeekHigh, clrSilver, STYLE_DOT);
      DrawHorizontalLevel("PWL", g_prevWeekLow, clrSilver, STYLE_DOT);
   }
}

void DrawHorizontalLevel(string label, double price, color clr, ENUM_LINE_STYLE style)
{
   string name = PREFIX + "Level_" + label;
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetString(0, name, OBJPROP_TEXT, label + " " + DoubleToString(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
}

void DrawStrongWeakLevels()
{
   if(g_trailing.top == 0 || g_trailing.bottom == 0) return;

   string strongHighLabel = (g_swingTrend == BEARISH) ? "Strong High" : "Weak High";
   string strongLowLabel  = (g_swingTrend == BULLISH) ? "Strong Low" : "Weak Low";

   color highClr = (g_swingTrend == BEARISH) ? InpBearColor : clrOrange;
   color lowClr  = (g_swingTrend == BULLISH) ? InpBullColor : clrOrange;

   // Strong/Weak High
   string nameH = PREFIX + "SW_High";
   if(ObjectFind(0, nameH) < 0)
      ObjectCreate(0, nameH, OBJ_HLINE, 0, 0, g_trailing.top);
   ObjectSetDouble(0, nameH, OBJPROP_PRICE, g_trailing.top);
   ObjectSetInteger(0, nameH, OBJPROP_COLOR, highClr);
   ObjectSetInteger(0, nameH, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameH, OBJPROP_WIDTH, 1);
   ObjectSetString(0, nameH, OBJPROP_TEXT, strongHighLabel);

   // Label
   string nameLblH = PREFIX + "SW_High_Lbl";
   if(ObjectFind(0, nameLblH) < 0)
      ObjectCreate(0, nameLblH, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), g_trailing.top);
   ObjectSetDouble(0, nameLblH, OBJPROP_PRICE, g_trailing.top);
   ObjectSetInteger(0, nameLblH, OBJPROP_TIME, iTime(_Symbol, PERIOD_CURRENT, 0));
   ObjectSetString(0, nameLblH, OBJPROP_TEXT, strongHighLabel);
   ObjectSetInteger(0, nameLblH, OBJPROP_COLOR, highClr);
   ObjectSetInteger(0, nameLblH, OBJPROP_FONTSIZE, 8);

   // Strong/Weak Low
   string nameL = PREFIX + "SW_Low";
   if(ObjectFind(0, nameL) < 0)
      ObjectCreate(0, nameL, OBJ_HLINE, 0, 0, g_trailing.bottom);
   ObjectSetDouble(0, nameL, OBJPROP_PRICE, g_trailing.bottom);
   ObjectSetInteger(0, nameL, OBJPROP_COLOR, lowClr);
   ObjectSetInteger(0, nameL, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameL, OBJPROP_WIDTH, 1);
   ObjectSetString(0, nameL, OBJPROP_TEXT, strongLowLabel);

   string nameLblL = PREFIX + "SW_Low_Lbl";
   if(ObjectFind(0, nameLblL) < 0)
      ObjectCreate(0, nameLblL, OBJ_TEXT, 0, iTime(_Symbol, PERIOD_CURRENT, 0), g_trailing.bottom);
   ObjectSetDouble(0, nameLblL, OBJPROP_PRICE, g_trailing.bottom);
   ObjectSetInteger(0, nameLblL, OBJPROP_TIME, iTime(_Symbol, PERIOD_CURRENT, 0));
   ObjectSetString(0, nameLblL, OBJPROP_TEXT, strongLowLabel);
   ObjectSetInteger(0, nameLblL, OBJPROP_COLOR, lowClr);
   ObjectSetInteger(0, nameLblL, OBJPROP_FONTSIZE, 8);
}

void DrawTradeArrow(int direction, double price, datetime t)
{
   string name = ObjName("Trade");
   int code = (direction == BULLISH) ? 233 : 234; // Up/Down arrows
   ObjectCreate(0, name, OBJ_ARROW, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (direction == BULLISH) ? InpBullColor : InpBearColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
}

//+------------------------------------------------------------------+
//| DASHBOARD                                                         |
//+------------------------------------------------------------------+
void DrawDashboard()
{
   string name = PREFIX + "Dashboard_BG";
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpDashX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpDashY);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, 220);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 260);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, InpDashBG);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrSlateGray);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);

   CreateDashLabel("Title", "SMC+ Dashboard", InpDashX + 10, InpDashY + 5, clrWhite, 10);
   CreateDashLabel("Strategy", "Strategy: ---", InpDashX + 10, InpDashY + 25, clrSilver, 8);
   CreateDashLabel("Swing", "Swing: ---", InpDashX + 10, InpDashY + 45, clrSilver, 8);
   CreateDashLabel("Internal", "Internal: ---", InpDashX + 10, InpDashY + 65, clrSilver, 8);
   CreateDashLabel("Session", "Session: ---", InpDashX + 10, InpDashY + 85, clrSilver, 8);
   CreateDashLabel("OBs", "Order Blocks: ---", InpDashX + 10, InpDashY + 105, clrSilver, 8);
   CreateDashLabel("FVGs", "FVGs: ---", InpDashX + 10, InpDashY + 125, clrSilver, 8);
   CreateDashLabel("Breakers", "Breakers: ---", InpDashX + 10, InpDashY + 145, clrSilver, 8);
   CreateDashLabel("LastEvent", "Last Event: None", InpDashX + 10, InpDashY + 165, clrSilver, 8);
   CreateDashLabel("PDH_PDL", "PDH/PDL: ---", InpDashX + 10, InpDashY + 185, clrSilver, 8);
   CreateDashLabel("Trades", "Open Trades: 0", InpDashX + 10, InpDashY + 205, clrSilver, 8);
   CreateDashLabel("PnL", "Session P&L: ---", InpDashX + 10, InpDashY + 225, clrSilver, 8);
}

void CreateDashLabel(string id, string text, int x, int y, color clr, int fontSize)
{
   string name = PREFIX + "Dash_" + id;
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}

void UpdateDashLabel(string id, string text, color clr)
{
   string name = PREFIX + "Dash_" + id;
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

void UpdateDashboard()
{
   // Strategy name
   string stratName = "";
   switch(InpStrategy)
   {
      case STRATEGY_1_CHOCH_OB_RETEST:     stratName = "1.CHoCH+OB(85%)";   break;
      case STRATEGY_2_SWEEP_BOS:           stratName = "2.Sweep+BOS(82%)";   break;
      case STRATEGY_3_IDM_CONTINUATION:    stratName = "3.IDM Cont.(80%)";   break;
      case STRATEGY_4_SWING_BOS_RETEST:    stratName = "4.BOS Retest(78%)";  break;
      case STRATEGY_5_EQH_EQL_FADE:        stratName = "5.EQH/EQL(75%)";     break;
      case STRATEGY_6_SESSION_LIQ_GRAB:    stratName = "6.Sess.Grab(74%)";   break;
      case STRATEGY_7_BREAKER_ENTRY:       stratName = "7.Breaker(72%)";     break;
      case STRATEGY_8_PDH_PDL_SWEEP:       stratName = "8.PDH/PDL(70%)";     break;
      case STRATEGY_9_FVG_FILL:            stratName = "9.FVG Fill(68%)";    break;
      case STRATEGY_10_STRONG_WEAK:        stratName = "10.S/W H/L(65%)";   break;
   }

   UpdateDashLabel("Strategy", "Strategy: " + stratName, clrGold);

   // Swing bias
   string swingText = (g_swingTrend == BULLISH) ? "Bullish" : (g_swingTrend == BEARISH) ? "Bearish" : "Neutral";
   color  swingClr  = (g_swingTrend == BULLISH) ? InpBullColor : (g_swingTrend == BEARISH) ? InpBearColor : clrGray;
   UpdateDashLabel("Swing", "Swing: " + swingText, swingClr);

   // Internal bias
   string intText = (g_internalTrend == BULLISH) ? "Bullish" : (g_internalTrend == BEARISH) ? "Bearish" : "Neutral";
   color  intClr  = (g_internalTrend == BULLISH) ? InpBullColor : (g_internalTrend == BEARISH) ? InpBearColor : clrGray;
   UpdateDashLabel("Internal", "Internal: " + intText, intClr);

   // Session
   string sessText = "None";
   color sessClr = clrGray;
   if(g_asiaSession.active)    { sessText = "Asia"; sessClr = InpAsiaColor; }
   if(g_londonSession.active)  { sessText = "London"; sessClr = InpLondonColor; }
   if(g_nySession.active)      { sessText = "New York"; sessClr = InpNYColor; }
   UpdateDashLabel("Session", "Session: " + sessText, sessClr);

   // Counts
   int obCount = 0;
   for(int i = 0; i < ArraySize(g_internalOB); i++) if(g_internalOB[i].valid) obCount++;
   for(int i = 0; i < ArraySize(g_swingOB); i++) if(g_swingOB[i].valid) obCount++;
   UpdateDashLabel("OBs", "Order Blocks: " + IntegerToString(obCount), clrSilver);

   int fvgCount = 0;
   for(int i = 0; i < ArraySize(g_fvg); i++) if(g_fvg[i].valid) fvgCount++;
   UpdateDashLabel("FVGs", "FVGs: " + IntegerToString(fvgCount), clrSilver);

   int brkCount = 0;
   for(int i = 0; i < ArraySize(g_breakerBlocks); i++) if(g_breakerBlocks[i].valid) brkCount++;
   UpdateDashLabel("Breakers", "Breakers: " + IntegerToString(brkCount), clrSilver);

   // Last event
   string lastEvt = "None";
   color evtClr = clrGray;
   if(g_alerts.internalBullishCHoCH)     { lastEvt = "Bull iCHoCH"; evtClr = InpBullColor; }
   else if(g_alerts.internalBearishCHoCH){ lastEvt = "Bear iCHoCH"; evtClr = InpBearColor; }
   else if(g_alerts.swingBullishBOS)     { lastEvt = "Bull BOS"; evtClr = InpBullColor; }
   else if(g_alerts.swingBearishBOS)     { lastEvt = "Bear BOS"; evtClr = InpBearColor; }
   else if(g_alerts.bullishSweep)        { lastEvt = "SSL Sweep"; evtClr = InpSweepBullColor; }
   else if(g_alerts.bearishSweep)        { lastEvt = "BSL Sweep"; evtClr = InpSweepBearColor; }
   else if(g_alerts.bullishIDM)          { lastEvt = "Bull IDM"; evtClr = clrDodgerBlue; }
   else if(g_alerts.bearishIDM)          { lastEvt = "Bear IDM"; evtClr = clrDodgerBlue; }
   else if(g_alerts.bullishDisplacement) { lastEvt = "Bull DISP"; evtClr = InpBullColor; }
   else if(g_alerts.bearishDisplacement) { lastEvt = "Bear DISP"; evtClr = InpBearColor; }
   UpdateDashLabel("LastEvent", "Last Event: " + lastEvt, evtClr);

   // PDH/PDL
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(g_prevDayHigh > 0)
      UpdateDashLabel("PDH_PDL", "PDH:" + DoubleToString(g_prevDayHigh, digits) + " PDL:" + DoubleToString(g_prevDayLow, digits), clrSilver);

   // Trades
   int trades = CountOpenTrades();
   UpdateDashLabel("Trades", "Open Trades: " + IntegerToString(trades), trades > 0 ? clrGold : clrSilver);

   // P&L
   double pnl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_posInfo.SelectByIndex(i))
         if(g_posInfo.Symbol() == _Symbol && g_posInfo.Magic() == InpMagicNumber)
            pnl += g_posInfo.Profit();
   }
   color pnlClr = pnl >= 0 ? InpBullColor : InpBearColor;
   UpdateDashLabel("PnL", "Session P&L: " + DoubleToString(pnl, 2), pnlClr);

   ChartRedraw(0);
}
//+------------------------------------------------------------------+
