//+------------------------------------------------------------------+
//|                                           SMC_Ultimate_EA.mq5    |
//|                     Smart Money Concepts - 10 Strategy EA        |
//|          Ported from TradingView LuxAlgo SMC+ Indicator          |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property link      ""
#property version   "2.00"
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
input color           InpIDMColor          = clrDodgerBlue;  // IDM Level Color
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
#define PREFIX    "SMC_"
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
   string   boxName;
   string   lblName;
};

struct FairValueGap
{
   double   top;
   double   bottom;
   int      bias;
   datetime barTime;
   bool     valid;
   bool     mitigated;
   string   boxName;
   string   lblName;
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
   string   boxName;
   string   lblName;
};

struct EqualLevel
{
   double   level;
   datetime time1;
   datetime time2;
   int      touchCount;
   bool     valid;
   string   lineName;
   string   lblName;
};

struct SessionState
{
   bool     active;
   double   high;
   double   low;
   datetime startTime;
   string   boxName;
   string   lblName;
   string   highLineName;
   string   lowLineName;
   string   highLblName;
   string   lowLblName;
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

PivotPoint     g_swingHigh, g_swingLow;
PivotPoint     g_internalHigh, g_internalLow;
PivotPoint     g_eqHigh, g_eqLow;

int            g_swingTrend  = NEUTRAL;
int            g_internalTrend = NEUTRAL;

OrderBlock     g_internalOB[];
OrderBlock     g_swingOB[];
FairValueGap   g_fvg[];
BreakerBlock   g_breakerBlocks[];
EqualLevel     g_equalHighs[];
EqualLevel     g_equalLows[];

SessionState   g_asiaSession, g_londonSession, g_nySession;
TrailingExtremes g_trailing;
StructureAlert g_alerts;

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
int            g_atrHandle200, g_atrHandle14, g_atrHandleDisp, g_atrTrailHandle;
double         g_atr200 = 0, g_atr14 = 0, g_atrDisp = 0, g_atrTrail = 0;

// Bar tracking
datetime       g_lastBarTime = 0;
int            g_barCount    = 0;
int            g_objCounter  = 0;

// Strategy state variables
bool           g_chochPending = false;
int            g_chochDirection = 0;
double         g_chochOB_Top = 0, g_chochOB_Bottom = 0;
datetime       g_chochOB_Time = 0;
int            g_chochBar = 0;

bool           g_sweepPending = false;
int            g_sweepDirection = 0;
double         g_sweepLevel = 0;
int            g_sweepBar = 0;

bool           g_bosRetestPending = false;
int            g_bosDirection = 0;
double         g_bosLevel = 0;
int            g_bosBar = 0;

bool           g_breakerPending = false;
int            g_breakerDirection = 0;
double         g_breakerTop = 0, g_breakerBottom = 0;
int            g_breakerBar = 0;

bool           g_sessionGrabPending = false;
int            g_sessionGrabDir = 0;
double         g_sessionGrabEntry = 0, g_sessionGrabStop = 0;
int            g_sessionGrabBar = 0;

//+------------------------------------------------------------------+
//| GRAPHICAL HELPER: Create or move objects safely                    |
//+------------------------------------------------------------------+
bool ObjEnsureCreated(string name, ENUM_OBJECT type, datetime t1, double p1,
                      datetime t2=0, double p2=0)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, type, 0, t1, p1, t2, p2))
      {
         // Silently fail - object limit may be reached
         return false;
      }
   }
   return true;
}

void ObjSetRect(string name, datetime t1, double p1, datetime t2, double p2,
                color clr, bool fill=true, int width=1, bool back=true)
{
   if(!ObjEnsureCreated(name, OBJ_RECTANGLE, t1, p1, t2, p2)) return;
   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL,  fill);
   ObjectSetInteger(0, name, OBJPROP_BACK,  back);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetTrend(string name, datetime t1, double p1, datetime t2, double p2,
                 color clr, ENUM_LINE_STYLE style=STYLE_SOLID, int width=1, bool ray=false)
{
   if(!ObjEnsureCreated(name, OBJ_TREND, t1, p1, t2, p2)) return;
   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME,  1, t2);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, ray);
   ObjectSetInteger(0, name, OBJPROP_BACK,  true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetHLine(string name, double price, color clr, ENUM_LINE_STYLE style=STYLE_DOT, int width=1)
{
   if(!ObjEnsureCreated(name, OBJ_HLINE, 0, price)) return;
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK,  true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetText(string name, datetime t, double price, string text, color clr,
                int fontSize=8, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT)
{
   if(!ObjEnsureCreated(name, OBJ_TEXT, t, price)) return;
   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE, 0, price);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0,  name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetArrow(string name, datetime t, double price, int code, color clr, int width=2)
{
   if(!ObjEnsureCreated(name, OBJ_ARROW, t, price)) return;
   ObjectSetInteger(0, name, OBJPROP_TIME,     0, t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,    0, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetLabel(string name, int x, int y, string text, color clr,
                 int fontSize=8, ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0,  name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjSetRectLabel(string name, int x, int y, int xSize, int ySize,
                     color bgClr, color borderClr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, xSize);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, ySize);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void ObjDelete(string name)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

string UniqueObjName(string type)
{
   g_objCounter++;
   return PREFIX + type + IntegerToString(g_objCounter);
}

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_symInfo.Name(_Symbol);
   g_symInfo.Refresh();

   g_atrHandle200   = iATR(_Symbol, PERIOD_CURRENT, InpOB_ATR_Period);
   g_atrHandle14    = iATR(_Symbol, PERIOD_CURRENT, 14);
   g_atrHandleDisp  = iATR(_Symbol, PERIOD_CURRENT, InpDispLength);
   g_atrTrailHandle = iATR(_Symbol, PERIOD_CURRENT, InpTrailATR_Period);
   if(g_atrHandle200==INVALID_HANDLE || g_atrHandle14==INVALID_HANDLE)
   { Print("ATR indicator failed"); return INIT_FAILED; }

   InitPivot(g_swingHigh); InitPivot(g_swingLow);
   InitPivot(g_internalHigh); InitPivot(g_internalLow);
   InitPivot(g_eqHigh); InitPivot(g_eqLow);
   InitSession(g_asiaSession); InitSession(g_londonSession); InitSession(g_nySession);
   g_trailing.top=0; g_trailing.bottom=0; g_trailing.topTime=0; g_trailing.bottomTime=0;

   ArrayResize(g_internalOB,0); ArrayResize(g_swingOB,0);
   ArrayResize(g_fvg,0); ArrayResize(g_breakerBlocks,0);
   ArrayResize(g_equalHighs,0); ArrayResize(g_equalLows,0);

   Print("SMC Ultimate EA v2 initialized. Strategy: ", EnumToString(InpStrategy));
   return INIT_SUCCEEDED;
}

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
      if(InpTrailStop) ManageTrailingStop();
      return;
   }
   g_barCount++;
   g_symInfo.Refresh();
   if(g_symInfo.Spread() > InpMaxSpread) return;

   UpdateATR();
   if(g_atr200 <= 0 || g_atr14 <= 0) return;

   ResetAlerts();
   UpdatePreviousLevels();
   UpdateSessions();
   DetectStructure();
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
      GfxDrawStructureEvents();
      GfxDrawSwingPointLabels();
      GfxUpdateOrderBlocks();
      GfxUpdateFVGs();
      GfxUpdateBreakerBlocks();
      GfxUpdateEqualLevels();
      GfxUpdateSessions();
      GfxUpdatePreviousLevels();
      GfxUpdateStrongWeakLevels();
      GfxUpdateIDMLines();
      GfxDrawDisplacementLabels();
      GfxUpdateDashboard();
      ChartRedraw(0);
   }

   TradeSignal signal;
   signal.valid = false;
   switch(InpStrategy)
   {
      case STRATEGY_1_CHOCH_OB_RETEST:   signal = Strategy1_CHoCH_OB();    break;
      case STRATEGY_2_SWEEP_BOS:         signal = Strategy2_SweepBOS();    break;
      case STRATEGY_3_IDM_CONTINUATION:  signal = Strategy3_IDM();         break;
      case STRATEGY_4_SWING_BOS_RETEST:  signal = Strategy4_SwingBOS();    break;
      case STRATEGY_5_EQH_EQL_FADE:      signal = Strategy5_EQH_EQL();    break;
      case STRATEGY_6_SESSION_LIQ_GRAB:  signal = Strategy6_SessionGrab(); break;
      case STRATEGY_7_BREAKER_ENTRY:     signal = Strategy7_Breaker();     break;
      case STRATEGY_8_PDH_PDL_SWEEP:     signal = Strategy8_PDH_PDL();     break;
      case STRATEGY_9_FVG_FILL:          signal = Strategy9_FVG();         break;
      case STRATEGY_10_STRONG_WEAK:      signal = Strategy10_StrongWeak(); break;
   }
   if(signal.valid) ExecuteTrade(signal);
   if(InpTrailStop) ManageTrailingStop();
}

//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                  |
//+------------------------------------------------------------------+
void InitPivot(PivotPoint &p)
{ p.currentLevel=0; p.lastLevel=0; p.crossed=false; p.barTime=0; p.barIndex=-1; }

void InitSession(SessionState &s)
{ s.active=false; s.high=0; s.low=0; s.startTime=0; s.boxName=""; s.lblName="";
  s.highLineName=""; s.lowLineName=""; s.highLblName=""; s.lowLblName=""; }

void ResetAlerts() { ZeroMemory(g_alerts); }

bool IsNewBar()
{
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t == g_lastBarTime) return false;
   g_lastBarTime = t;
   return true;
}

void UpdateATR()
{
   double buf[];
   if(CopyBuffer(g_atrHandle200, 0, 1, 1, buf)>0) g_atr200=buf[0];
   if(CopyBuffer(g_atrHandle14,  0, 1, 1, buf)>0) g_atr14=buf[0];
   if(CopyBuffer(g_atrHandleDisp,0, 1, 1, buf)>0) g_atrDisp=buf[0];
   if(CopyBuffer(g_atrTrailHandle,0,1, 1, buf)>0) g_atrTrail=buf[0];
}

int CountOpenTrades()
{
   int c=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(g_posInfo.SelectByIndex(i))
         if(g_posInfo.Symbol()==_Symbol && g_posInfo.Magic()==InpMagicNumber) c++;
   return c;
}

double CalculateLotSize(double stopDistPoints)
{
   if(InpRiskMode==RISK_FIXED_LOT) return MathMin(InpFixedLot, InpMaxLots);
   double tv=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double ts=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double ls=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double ml=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(tv<=0||ts<=0||stopDistPoints<=0) return ml;
   double risk=AccountInfoDouble(ACCOUNT_BALANCE)*InpRiskPercent/100.0;
   double pv=tv/ts*_Point;
   double lots=risk/(stopDistPoints*pv);
   lots=MathFloor(lots/ls)*ls;
   lots=MathMax(lots,ml);
   lots=MathMin(lots,InpMaxLots);
   return NormalizeDouble(lots,2);
}

//+------------------------------------------------------------------+
//| STRUCTURE DETECTION                                               |
//+------------------------------------------------------------------+
int DetectLeg(int size, int shift)
{
   double pH=iHigh(_Symbol,PERIOD_CURRENT,shift+size);
   double pL=iLow(_Symbol,PERIOD_CURRENT,shift+size);
   double highest=pH, lowest=pL;
   for(int i=shift; i<shift+size; i++)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,i);
      double l=iLow(_Symbol,PERIOD_CURRENT,i);
      if(h>highest) highest=h;
      if(l<lowest)  lowest=l;
   }
   if(pH>highest) return BEARISH_LEG;
   if(pL<lowest)  return BULLISH_LEG;
   return -1;
}

void DetectPivots(int size, PivotPoint &highPivot, PivotPoint &lowPivot, bool isInternal)
{
   int leg=DetectLeg(size,1);
   if(leg<0) return;
   int prevLeg=DetectLeg(size,2);
   if(leg==prevLeg || prevLeg<0) return;

   if(leg==BULLISH_LEG)
   {
      double v=iLow(_Symbol,PERIOD_CURRENT,1+size);
      datetime t=iTime(_Symbol,PERIOD_CURRENT,1+size);
      int idx=g_barCount-(1+size);
      lowPivot.lastLevel=lowPivot.currentLevel;
      lowPivot.currentLevel=v; lowPivot.crossed=false;
      lowPivot.barTime=t; lowPivot.barIndex=idx;
      if(!isInternal) { g_trailing.bottom=v; g_trailing.bottomTime=t; }
   }
   else
   {
      double v=iHigh(_Symbol,PERIOD_CURRENT,1+size);
      datetime t=iTime(_Symbol,PERIOD_CURRENT,1+size);
      int idx=g_barCount-(1+size);
      highPivot.lastLevel=highPivot.currentLevel;
      highPivot.currentLevel=v; highPivot.crossed=false;
      highPivot.barTime=t; highPivot.barIndex=idx;
      if(!isInternal) { g_trailing.top=v; g_trailing.topTime=t; }
   }
}

void DetectStructureBreak(PivotPoint &highPivot, PivotPoint &lowPivot, int &trend, bool isInternal)
{
   double c=iClose(_Symbol,PERIOD_CURRENT,1);

   if(highPivot.currentLevel>0 && !highPivot.crossed && c>highPivot.currentLevel)
   {
      bool isCHoCH=(trend==BEARISH);
      highPivot.crossed=true; trend=BULLISH;
      if(isInternal) { if(isCHoCH) g_alerts.internalBullishCHoCH=true; else g_alerts.internalBullishBOS=true; }
      else           { if(isCHoCH) g_alerts.swingBullishCHoCH=true;    else g_alerts.swingBullishBOS=true; }
      StoreOrderBlock(highPivot, isInternal, BULLISH);
   }
   if(lowPivot.currentLevel>0 && !lowPivot.crossed && c<lowPivot.currentLevel)
   {
      bool isCHoCH=(trend==BULLISH);
      lowPivot.crossed=true; trend=BEARISH;
      if(isInternal) { if(isCHoCH) g_alerts.internalBearishCHoCH=true; else g_alerts.internalBearishBOS=true; }
      else           { if(isCHoCH) g_alerts.swingBearishCHoCH=true;    else g_alerts.swingBearishBOS=true; }
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
//| ORDER BLOCK STORAGE                                               |
//+------------------------------------------------------------------+
void StoreOrderBlock(PivotPoint &pivot, bool isInternal, int bias)
{
   if(pivot.barIndex<0) return;
   int lookback=g_barCount-pivot.barIndex;
   if(lookback<1 || lookback>500) return;

   int bestBar=lookback;
   if(bias==BEARISH)
   {
      double maxH=0;
      for(int i=1; i<=lookback && i<Bars(_Symbol,PERIOD_CURRENT); i++)
      { double h=iHigh(_Symbol,PERIOD_CURRENT,i); if(h>maxH){maxH=h; bestBar=i;} }
   }
   else
   {
      double minL=DBL_MAX;
      for(int i=1; i<=lookback && i<Bars(_Symbol,PERIOD_CURRENT); i++)
      { double l=iLow(_Symbol,PERIOD_CURRENT,i); if(l<minL){minL=l; bestBar=i;} }
   }
   if(bestBar>=Bars(_Symbol,PERIOD_CURRENT)) return;

   double obH=iHigh(_Symbol,PERIOD_CURRENT,bestBar);
   double obL=iLow(_Symbol,PERIOD_CURRENT,bestBar);
   double barRange=obH-obL;
   if(barRange>=2.0*g_atr200)
   { if(bias==BEARISH) obL=obH; else obH=obL; }

   OrderBlock ob;
   ob.top=obH; ob.bottom=obL;
   ob.barTime=iTime(_Symbol,PERIOD_CURRENT,bestBar);
   ob.bias=bias; ob.valid=true; ob.touched=false;
   ob.boxName=UniqueObjName(isInternal?"iOB":"sOB");
   ob.lblName=ob.boxName+"L";

   if(isInternal)
   {
      int sz=ArraySize(g_internalOB); ArrayResize(g_internalOB,sz+1); g_internalOB[sz]=ob;
      if(ArraySize(g_internalOB)>InpMaxOB*2)
      { ObjDelete(g_internalOB[0].boxName); ObjDelete(g_internalOB[0].lblName);
        for(int i=0;i<ArraySize(g_internalOB)-1;i++) g_internalOB[i]=g_internalOB[i+1];
        ArrayResize(g_internalOB,ArraySize(g_internalOB)-1); }
   }
   else
   {
      int sz=ArraySize(g_swingOB); ArrayResize(g_swingOB,sz+1); g_swingOB[sz]=ob;
      if(ArraySize(g_swingOB)>InpMaxOB*2)
      { ObjDelete(g_swingOB[0].boxName); ObjDelete(g_swingOB[0].lblName);
        for(int i=0;i<ArraySize(g_swingOB)-1;i++) g_swingOB[i]=g_swingOB[i+1];
        ArrayResize(g_swingOB,ArraySize(g_swingOB)-1); }
   }
}

void MitigateOrderBlocks()
{
   double c=iClose(_Symbol,PERIOD_CURRENT,1);
   double h=iHigh(_Symbol,PERIOD_CURRENT,1);
   double l=iLow(_Symbol,PERIOD_CURRENT,1);
   for(int i=ArraySize(g_internalOB)-1; i>=0; i--)
   {
      if(!g_internalOB[i].valid) continue;
      if(g_internalOB[i].bias==BEARISH && h>g_internalOB[i].top)
      { g_internalOB[i].valid=false; ObjDelete(g_internalOB[i].boxName); ObjDelete(g_internalOB[i].lblName); }
      if(g_internalOB[i].bias==BULLISH && l<g_internalOB[i].bottom)
      { g_internalOB[i].valid=false; ObjDelete(g_internalOB[i].boxName); ObjDelete(g_internalOB[i].lblName); }
   }
   for(int i=ArraySize(g_swingOB)-1; i>=0; i--)
   {
      if(!g_swingOB[i].valid) continue;
      if(g_swingOB[i].bias==BEARISH && h>g_swingOB[i].top)
      { g_swingOB[i].valid=false; ObjDelete(g_swingOB[i].boxName); ObjDelete(g_swingOB[i].lblName); }
      if(g_swingOB[i].bias==BULLISH && l<g_swingOB[i].bottom)
      { g_swingOB[i].valid=false; ObjDelete(g_swingOB[i].boxName); ObjDelete(g_swingOB[i].lblName); }
   }
}

//+------------------------------------------------------------------+
//| FAIR VALUE GAP DETECTION                                          |
//+------------------------------------------------------------------+
void DetectFVG()
{
   if(Bars(_Symbol,PERIOD_CURRENT)<4) return;
   double h0=iHigh(_Symbol,PERIOD_CURRENT,1), l0=iLow(_Symbol,PERIOD_CURRENT,1);
   double c1=iClose(_Symbol,PERIOD_CURRENT,2), o1=iOpen(_Symbol,PERIOD_CURRENT,2);
   double h2=iHigh(_Symbol,PERIOD_CURRENT,3), l2=iLow(_Symbol,PERIOD_CURRENT,3);
   double bd=c1-o1;
   bool thOk=true;
   if(InpAutoFVGThreshold && g_atr200>0)
     thOk=(MathAbs(bd)/(o1>0?o1:1)*100>0.01);

   if(l0>h2 && c1>h2 && bd>0 && thOk)
   {
      FairValueGap fvg;
      fvg.top=l0; fvg.bottom=h2; fvg.bias=BULLISH;
      fvg.barTime=iTime(_Symbol,PERIOD_CURRENT,2);
      fvg.valid=true; fvg.mitigated=false;
      fvg.boxName=UniqueObjName("FVG"); fvg.lblName=fvg.boxName+"L";
      int sz=ArraySize(g_fvg); ArrayResize(g_fvg,sz+1); g_fvg[sz]=fvg;
   }
   if(h0<l2 && c1<l2 && bd<0 && thOk)
   {
      FairValueGap fvg;
      fvg.top=l2; fvg.bottom=h0; fvg.bias=BEARISH;
      fvg.barTime=iTime(_Symbol,PERIOD_CURRENT,2);
      fvg.valid=true; fvg.mitigated=false;
      fvg.boxName=UniqueObjName("FVG"); fvg.lblName=fvg.boxName+"L";
      int sz=ArraySize(g_fvg); ArrayResize(g_fvg,sz+1); g_fvg[sz]=fvg;
   }
   while(ArraySize(g_fvg)>30)
   { ObjDelete(g_fvg[0].boxName); ObjDelete(g_fvg[0].lblName);
     for(int i=0;i<ArraySize(g_fvg)-1;i++) g_fvg[i]=g_fvg[i+1];
     ArrayResize(g_fvg,ArraySize(g_fvg)-1); }
}

void MitigateFVG()
{
   double l=iLow(_Symbol,PERIOD_CURRENT,1), h=iHigh(_Symbol,PERIOD_CURRENT,1);
   for(int i=ArraySize(g_fvg)-1; i>=0; i--)
   {
      if(!g_fvg[i].valid) continue;
      if(g_fvg[i].bias==BULLISH && l<g_fvg[i].bottom)
      { g_fvg[i].valid=false; ObjDelete(g_fvg[i].boxName); ObjDelete(g_fvg[i].lblName); }
      if(g_fvg[i].bias==BEARISH && h>g_fvg[i].top)
      { g_fvg[i].valid=false; ObjDelete(g_fvg[i].boxName); ObjDelete(g_fvg[i].lblName); }
   }
}

//+------------------------------------------------------------------+
//| EQUAL HIGHS/LOWS                                                  |
//+------------------------------------------------------------------+
void DetectEqualLevels()
{
   if(g_eqHigh.currentLevel>0 && g_eqHigh.lastLevel>0)
   {
      double diff=MathAbs(g_eqHigh.currentLevel-g_eqHigh.lastLevel);
      if(diff<InpEQL_Threshold*g_atr200 && diff>0)
      {
         EqualLevel eq;
         eq.level=(g_eqHigh.currentLevel+g_eqHigh.lastLevel)/2.0;
         eq.time1=g_eqHigh.barTime; eq.time2=iTime(_Symbol,PERIOD_CURRENT,1);
         eq.touchCount=2; eq.valid=true;
         eq.lineName=UniqueObjName("EQH"); eq.lblName=eq.lineName+"L";
         int sz=ArraySize(g_equalHighs); ArrayResize(g_equalHighs,sz+1); g_equalHighs[sz]=eq;
      }
   }
   if(g_eqLow.currentLevel>0 && g_eqLow.lastLevel>0)
   {
      double diff=MathAbs(g_eqLow.currentLevel-g_eqLow.lastLevel);
      if(diff<InpEQL_Threshold*g_atr200 && diff>0)
      {
         EqualLevel eq;
         eq.level=(g_eqLow.currentLevel+g_eqLow.lastLevel)/2.0;
         eq.time1=g_eqLow.barTime; eq.time2=iTime(_Symbol,PERIOD_CURRENT,1);
         eq.touchCount=2; eq.valid=true;
         eq.lineName=UniqueObjName("EQL"); eq.lblName=eq.lineName+"L";
         int sz=ArraySize(g_equalLows); ArrayResize(g_equalLows,sz+1); g_equalLows[sz]=eq;
      }
   }
   while(ArraySize(g_equalHighs)>20)
   { ObjDelete(g_equalHighs[0].lineName); ObjDelete(g_equalHighs[0].lblName);
     for(int i=0;i<ArraySize(g_equalHighs)-1;i++) g_equalHighs[i]=g_equalHighs[i+1];
     ArrayResize(g_equalHighs,ArraySize(g_equalHighs)-1); }
   while(ArraySize(g_equalLows)>20)
   { ObjDelete(g_equalLows[0].lineName); ObjDelete(g_equalLows[0].lblName);
     for(int i=0;i<ArraySize(g_equalLows)-1;i++) g_equalLows[i]=g_equalLows[i+1];
     ArrayResize(g_equalLows,ArraySize(g_equalLows)-1); }
}

//+------------------------------------------------------------------+
//| LIQUIDITY SWEEP DETECTION                                         |
//+------------------------------------------------------------------+
void DetectSweeps()
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1);
   double c=iClose(_Symbol,PERIOD_CURRENT,1);
   datetime t=iTime(_Symbol,PERIOD_CURRENT,1);
   double minP=g_atr14*InpSweepMinATR;

   // Swing high sweep (BSL)
   if(g_swingHigh.currentLevel>0 && g_swingHigh.barIndex>0)
   {
      int age=g_barCount-g_swingHigh.barIndex;
      if(age>0 && age<=InpSweepMaxAge && h>g_swingHigh.currentLevel+minP)
      {
         bool ok=!InpSweepCloseBack || c<g_swingHigh.currentLevel;
         if(ok)
         {
            g_alerts.bearishSweep=true;
            if(InpDrawGraphics)
            {
               string ln=UniqueObjName("SwpL"); string lb=UniqueObjName("SwpB");
               ObjSetTrend(ln, g_swingHigh.barTime, g_swingHigh.currentLevel, t, g_swingHigh.currentLevel,
                           InpSweepBearColor, STYLE_DOT, 1);
               ObjSetText(lb, t, h, "BSL Sweep", InpSweepBearColor, 8, ANCHOR_LOWER);
            }
         }
      }
   }
   // Swing low sweep (SSL)
   if(g_swingLow.currentLevel>0 && g_swingLow.barIndex>0)
   {
      int age=g_barCount-g_swingLow.barIndex;
      if(age>0 && age<=InpSweepMaxAge && l<g_swingLow.currentLevel-minP)
      {
         bool ok=!InpSweepCloseBack || c>g_swingLow.currentLevel;
         if(ok)
         {
            g_alerts.bullishSweep=true;
            if(InpDrawGraphics)
            {
               string ln=UniqueObjName("SwpL"); string lb=UniqueObjName("SwpB");
               ObjSetTrend(ln, g_swingLow.barTime, g_swingLow.currentLevel, t, g_swingLow.currentLevel,
                           InpSweepBullColor, STYLE_DOT, 1);
               ObjSetText(lb, t, l, "SSL Sweep", InpSweepBullColor, 8, ANCHOR_UPPER);
            }
         }
      }
   }
   // Internal sweeps
   if(g_internalHigh.currentLevel>0 && g_internalHigh.barIndex>0)
   {
      int age=g_barCount-g_internalHigh.barIndex;
      if(age>0 && age<=InpSweepMaxAge && h>g_internalHigh.currentLevel+minP)
      {
         bool ok=!InpSweepCloseBack || c<g_internalHigh.currentLevel;
         if(ok) g_alerts.bearishSweep=true;
      }
   }
   if(g_internalLow.currentLevel>0 && g_internalLow.barIndex>0)
   {
      int age=g_barCount-g_internalLow.barIndex;
      if(age>0 && age<=InpSweepMaxAge && l<g_internalLow.currentLevel-minP)
      {
         bool ok=!InpSweepCloseBack || c>g_internalLow.currentLevel;
         if(ok) g_alerts.bullishSweep=true;
      }
   }
}

//+------------------------------------------------------------------+
//| INDUCEMENT (IDM) DETECTION                                        |
//+------------------------------------------------------------------+
void DetectIDM()
{
   if(g_swingTrend==BULLISH && g_internalLow.currentLevel>0)
   {
      int age=g_barCount-g_internalLow.barIndex;
      if(age>0 && age<=InpIDM_MaxAge && (g_bullIDM_Taken || g_bullIDM_Level==0))
      { g_bullIDM_Level=g_internalLow.currentLevel; g_bullIDM_Time=g_internalLow.barTime;
        g_bullIDM_Bar=g_internalLow.barIndex; g_bullIDM_Taken=false; }
   }
   if(g_swingTrend!=BULLISH && g_bullIDM_Level>0 && !g_bullIDM_Taken)
      g_bullIDM_Taken=true;
   if(g_swingTrend==BEARISH && g_internalHigh.currentLevel>0)
   {
      int age=g_barCount-g_internalHigh.barIndex;
      if(age>0 && age<=InpIDM_MaxAge && (g_bearIDM_Taken || g_bearIDM_Level==0))
      { g_bearIDM_Level=g_internalHigh.currentLevel; g_bearIDM_Time=g_internalHigh.barTime;
        g_bearIDM_Bar=g_internalHigh.barIndex; g_bearIDM_Taken=false; }
   }
   if(g_swingTrend!=BEARISH && g_bearIDM_Level>0 && !g_bearIDM_Taken)
      g_bearIDM_Taken=true;

   double l=iLow(_Symbol,PERIOD_CURRENT,1), h=iHigh(_Symbol,PERIOD_CURRENT,1);
   double c=iClose(_Symbol,PERIOD_CURRENT,1);
   if(g_swingTrend==BULLISH && !g_bullIDM_Taken && g_bullIDM_Level>0 && l<=g_bullIDM_Level)
   {
      bool ok=!InpIDM_CloseBack || c>g_bullIDM_Level;
      if(ok) { g_bullIDM_Taken=true; g_alerts.bullishIDM=true; }
   }
   if(g_swingTrend==BEARISH && !g_bearIDM_Taken && g_bearIDM_Level>0 && h>=g_bearIDM_Level)
   {
      bool ok=!InpIDM_CloseBack || c<g_bearIDM_Level;
      if(ok) { g_bearIDM_Taken=true; g_alerts.bearishIDM=true; }
   }
}

//+------------------------------------------------------------------+
//| DISPLACEMENT DETECTION                                            |
//+------------------------------------------------------------------+
void DetectDisplacement()
{
   double c=iClose(_Symbol,PERIOD_CURRENT,1), o=iOpen(_Symbol,PERIOD_CURRENT,1);
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1);
   double body=MathAbs(c-o), range=h-l;
   double avgB=0, avgR=0;
   int cnt=MathMin(InpDispLength, Bars(_Symbol,PERIOD_CURRENT)-2);
   for(int i=2; i<=cnt+1; i++)
   { avgB+=MathAbs(iClose(_Symbol,PERIOD_CURRENT,i)-iOpen(_Symbol,PERIOD_CURRENT,i));
     avgR+=iHigh(_Symbol,PERIOD_CURRENT,i)-iLow(_Symbol,PERIOD_CURRENT,i); }
   if(cnt>0) { avgB/=cnt; avgR/=cnt; }

   if(c>o && body>avgB*InpDispBodyFactor && range>avgR*InpDispRangeFactor && range>g_atr14*InpDispATR_Factor)
      g_alerts.bullishDisplacement=true;
   if(c<o && body>avgB*InpDispBodyFactor && range>avgR*InpDispRangeFactor && range>g_atr14*InpDispATR_Factor)
      g_alerts.bearishDisplacement=true;
}

//+------------------------------------------------------------------+
//| BREAKER BLOCK DETECTION                                           |
//+------------------------------------------------------------------+
int FindLastBearishCandle(int lb)
{ for(int i=1; i<=lb && i<Bars(_Symbol,PERIOD_CURRENT); i++) if(iClose(_Symbol,PERIOD_CURRENT,i)<iOpen(_Symbol,PERIOD_CURRENT,i)) return i; return -1; }
int FindLastBullishCandle(int lb)
{ for(int i=1; i<=lb && i<Bars(_Symbol,PERIOD_CURRENT); i++) if(iClose(_Symbol,PERIOD_CURRENT,i)>iOpen(_Symbol,PERIOD_CURRENT,i)) return i; return -1; }

void CreateBreakerBlock(bool bullish, bool isBreaker)
{
   int off=bullish?FindLastBearishCandle(InpBreakerSearchBars):FindLastBullishCandle(InpBreakerSearchBars);
   if(off<0) return;
   BreakerBlock bb;
   bb.top=iHigh(_Symbol,PERIOD_CURRENT,off); bb.bottom=iLow(_Symbol,PERIOD_CURRENT,off);
   bb.barTime=iTime(_Symbol,PERIOD_CURRENT,off); bb.bias=bullish?BULLISH:BEARISH;
   bb.isBreaker=isBreaker; bb.mitigated=false; bb.valid=true;
   bb.boxName=UniqueObjName(isBreaker?"BRK":"MIT"); bb.lblName=bb.boxName+"L";
   int sz=ArraySize(g_breakerBlocks); ArrayResize(g_breakerBlocks,sz+1); g_breakerBlocks[sz]=bb;
   while(ArraySize(g_breakerBlocks)>InpMaxBreakerBlocks)
   { ObjDelete(g_breakerBlocks[0].boxName); ObjDelete(g_breakerBlocks[0].lblName);
     for(int i=0;i<ArraySize(g_breakerBlocks)-1;i++) g_breakerBlocks[i]=g_breakerBlocks[i+1];
     ArrayResize(g_breakerBlocks,ArraySize(g_breakerBlocks)-1); }
}

void DetectBreakerBlocks()
{
   if(g_alerts.internalBullishCHoCH||g_alerts.swingBullishCHoCH) CreateBreakerBlock(true,true);
   if(g_alerts.internalBearishCHoCH||g_alerts.swingBearishCHoCH) CreateBreakerBlock(false,true);
   if(g_alerts.internalBullishBOS||g_alerts.swingBullishBOS)     CreateBreakerBlock(true,false);
   if(g_alerts.internalBearishBOS||g_alerts.swingBearishBOS)     CreateBreakerBlock(false,false);
}

void MitigateBreakers()
{
   double c=iClose(_Symbol,PERIOD_CURRENT,1);
   for(int i=ArraySize(g_breakerBlocks)-1; i>=0; i--)
   {
      if(!g_breakerBlocks[i].valid) continue;
      if(g_breakerBlocks[i].bias==BULLISH && c<g_breakerBlocks[i].bottom)
      { g_breakerBlocks[i].valid=false; ObjDelete(g_breakerBlocks[i].boxName); ObjDelete(g_breakerBlocks[i].lblName); }
      if(g_breakerBlocks[i].bias==BEARISH && c>g_breakerBlocks[i].top)
      { g_breakerBlocks[i].valid=false; ObjDelete(g_breakerBlocks[i].boxName); ObjDelete(g_breakerBlocks[i].lblName); }
   }
}

//+------------------------------------------------------------------+
//| SESSION HANDLING                                                  |
//+------------------------------------------------------------------+
bool IsInSession(string startStr, string endStr)
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int sH=0,sM=0,eH=0,eM=0; ParseTime(startStr,sH,sM); ParseTime(endStr,eH,eM);
   int cur=dt.hour*60+dt.min, st=sH*60+sM, en=eH*60+eM;
   return (st<en) ? (cur>=st && cur<en) : (cur>=st || cur<en);
}

void ParseTime(string ts, int &h, int &m)
{ string p[]; int c=StringSplit(ts,':',p); h=(c>0)?(int)StringToInteger(p[0]):0; m=(c>1)?(int)StringToInteger(p[1]):0; }

void UpdateSessionState(SessionState &state, string startStr, string endStr, string name, color clr)
{
   bool inSess=IsInSession(startStr,endStr);
   bool sessStart=inSess && !state.active;
   bool sessEnd=!inSess && state.active;

   if(sessStart)
   {
      state.active=true;
      state.high=iHigh(_Symbol,PERIOD_CURRENT,0);
      state.low=iLow(_Symbol,PERIOD_CURRENT,0);
      state.startTime=iTime(_Symbol,PERIOD_CURRENT,0);
      state.boxName=UniqueObjName("Sess"+name);
      state.lblName=state.boxName+"L";
      state.highLineName=state.boxName+"HL";
      state.lowLineName=state.boxName+"LL";
      state.highLblName=state.boxName+"HB";
      state.lowLblName=state.boxName+"LB";
   }
   if(inSess && state.active)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,0), l=iLow(_Symbol,PERIOD_CURRENT,0);
      if(h>state.high) state.high=h;
      if(l<state.low || state.low==0) state.low=l;
      if(InpDrawGraphics && state.boxName!="")
      {
         ObjSetRect(state.boxName, state.startTime, state.high,
                    iTime(_Symbol,PERIOD_CURRENT,0), state.low, clr, true, 1, true);
         ObjSetText(state.lblName, state.startTime, state.high, name, clr, 7, ANCHOR_LOWER);
      }
   }
   if(sessEnd)
   {
      state.active=false;
      if(InpDrawGraphics && state.boxName!="")
      {
         datetime rightTime=iTime(_Symbol,PERIOD_CURRENT,0)+(datetime)(PeriodSeconds()*20);
         ObjSetTrend(state.highLineName, state.startTime, state.high, rightTime, state.high, clr, STYLE_DOT, 1);
         ObjSetTrend(state.lowLineName,  state.startTime, state.low,  rightTime, state.low,  clr, STYLE_DOT, 1);
         ObjSetText(state.highLblName, rightTime, state.high, name+" H", clr, 7, ANCHOR_LEFT);
         ObjSetText(state.lowLblName,  rightTime, state.low,  name+" L", clr, 7, ANCHOR_LEFT);
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
   MqlRates d[]; if(CopyRates(_Symbol,PERIOD_D1,1,1,d)>0)
   { g_prevDayHigh=d[0].high; g_prevDayLow=d[0].low; g_prevDayOpen=d[0].open; g_prevDayClose=d[0].close; }
   MqlRates w[]; if(CopyRates(_Symbol,PERIOD_W1,1,1,w)>0)
   { g_prevWeekHigh=w[0].high; g_prevWeekLow=w[0].low; }
}

void UpdateTrailingExtremes()
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1);
   datetime t=iTime(_Symbol,PERIOD_CURRENT,1);
   if(g_trailing.top==0 || h>g_trailing.top) { g_trailing.top=h; g_trailing.topTime=t; }
   if(g_trailing.bottom==0 || l<g_trailing.bottom) { g_trailing.bottom=l; g_trailing.bottomTime=t; }
}

//+------------------------------------------------------------------+
//| ============== GRAPHICAL DRAWING FUNCTIONS ==============          |
//+------------------------------------------------------------------+

// Draw BOS/CHoCH structure lines + labels when events fire
void GfxDrawStructureEvents()
{
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);

   if(g_alerts.internalBullishBOS && g_internalHigh.barTime>0)
   {
      string n=UniqueObjName("iBOS"); string nl=n+"L";
      ObjSetTrend(n, g_internalHigh.barTime, g_internalHigh.currentLevel, now, g_internalHigh.currentLevel,
                  InpBullColor, STYLE_DASH, 1);
      datetime mid=g_internalHigh.barTime+(now-g_internalHigh.barTime)/2;
      ObjSetText(nl, mid, g_internalHigh.currentLevel, "iBOS", InpBullColor, 7, ANCHOR_LOWER);
   }
   if(g_alerts.internalBearishBOS && g_internalLow.barTime>0)
   {
      string n=UniqueObjName("iBOS"); string nl=n+"L";
      ObjSetTrend(n, g_internalLow.barTime, g_internalLow.currentLevel, now, g_internalLow.currentLevel,
                  InpBearColor, STYLE_DASH, 1);
      datetime mid=g_internalLow.barTime+(now-g_internalLow.barTime)/2;
      ObjSetText(nl, mid, g_internalLow.currentLevel, "iBOS", InpBearColor, 7, ANCHOR_UPPER);
   }
   if(g_alerts.internalBullishCHoCH && g_internalHigh.barTime>0)
   {
      string n=UniqueObjName("iCHoCH"); string nl=n+"L";
      ObjSetTrend(n, g_internalHigh.barTime, g_internalHigh.currentLevel, now, g_internalHigh.currentLevel,
                  InpBullColor, STYLE_DASH, 1);
      datetime mid=g_internalHigh.barTime+(now-g_internalHigh.barTime)/2;
      ObjSetText(nl, mid, g_internalHigh.currentLevel, "CHoCH", InpBullColor, 7, ANCHOR_LOWER);
   }
   if(g_alerts.internalBearishCHoCH && g_internalLow.barTime>0)
   {
      string n=UniqueObjName("iCHoCH"); string nl=n+"L";
      ObjSetTrend(n, g_internalLow.barTime, g_internalLow.currentLevel, now, g_internalLow.currentLevel,
                  InpBearColor, STYLE_DASH, 1);
      datetime mid=g_internalLow.barTime+(now-g_internalLow.barTime)/2;
      ObjSetText(nl, mid, g_internalLow.currentLevel, "CHoCH", InpBearColor, 7, ANCHOR_UPPER);
   }
   if(g_alerts.swingBullishBOS && g_swingHigh.barTime>0)
   {
      string n=UniqueObjName("BOS"); string nl=n+"L";
      ObjSetTrend(n, g_swingHigh.barTime, g_swingHigh.currentLevel, now, g_swingHigh.currentLevel,
                  InpBullColor, STYLE_SOLID, 2);
      datetime mid=g_swingHigh.barTime+(now-g_swingHigh.barTime)/2;
      ObjSetText(nl, mid, g_swingHigh.currentLevel, "BOS", InpBullColor, 9, ANCHOR_LOWER);
   }
   if(g_alerts.swingBearishBOS && g_swingLow.barTime>0)
   {
      string n=UniqueObjName("BOS"); string nl=n+"L";
      ObjSetTrend(n, g_swingLow.barTime, g_swingLow.currentLevel, now, g_swingLow.currentLevel,
                  InpBearColor, STYLE_SOLID, 2);
      datetime mid=g_swingLow.barTime+(now-g_swingLow.barTime)/2;
      ObjSetText(nl, mid, g_swingLow.currentLevel, "BOS", InpBearColor, 9, ANCHOR_UPPER);
   }
   if(g_alerts.swingBullishCHoCH && g_swingHigh.barTime>0)
   {
      string n=UniqueObjName("CHoCH"); string nl=n+"L";
      ObjSetTrend(n, g_swingHigh.barTime, g_swingHigh.currentLevel, now, g_swingHigh.currentLevel,
                  InpBullColor, STYLE_SOLID, 2);
      datetime mid=g_swingHigh.barTime+(now-g_swingHigh.barTime)/2;
      ObjSetText(nl, mid, g_swingHigh.currentLevel, "CHoCH", InpBullColor, 9, ANCHOR_LOWER);
   }
   if(g_alerts.swingBearishCHoCH && g_swingLow.barTime>0)
   {
      string n=UniqueObjName("CHoCH"); string nl=n+"L";
      ObjSetTrend(n, g_swingLow.barTime, g_swingLow.currentLevel, now, g_swingLow.currentLevel,
                  InpBearColor, STYLE_SOLID, 2);
      datetime mid=g_swingLow.barTime+(now-g_swingLow.barTime)/2;
      ObjSetText(nl, mid, g_swingLow.currentLevel, "CHoCH", InpBearColor, 9, ANCHOR_UPPER);
   }
}

// Draw swing point labels: HH, HL, LH, LL
void GfxDrawSwingPointLabels()
{
   // When a new swing high/low forms, label it
   static double lastSwingH=0, lastSwingL=0;

   if(g_swingHigh.currentLevel!=lastSwingH && g_swingHigh.currentLevel>0 && g_swingHigh.barTime>0)
   {
      lastSwingH=g_swingHigh.currentLevel;
      string tag=(g_swingHigh.currentLevel>g_swingHigh.lastLevel && g_swingHigh.lastLevel>0) ? "HH" : "LH";
      string n=UniqueObjName("SwPt");
      ObjSetText(n, g_swingHigh.barTime, g_swingHigh.currentLevel, tag, InpBearColor, 8, ANCHOR_LOWER);
   }
   if(g_swingLow.currentLevel!=lastSwingL && g_swingLow.currentLevel>0 && g_swingLow.barTime>0)
   {
      lastSwingL=g_swingLow.currentLevel;
      string tag=(g_swingLow.currentLevel<g_swingLow.lastLevel && g_swingLow.lastLevel>0) ? "LL" : "HL";
      string n=UniqueObjName("SwPt");
      ObjSetText(n, g_swingLow.barTime, g_swingLow.currentLevel, tag, InpBullColor, 8, ANCHOR_UPPER);
   }
}

// Update Order Block rectangles - extend right edge to current bar each tick
void GfxUpdateOrderBlocks()
{
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
   for(int i=0; i<ArraySize(g_internalOB); i++)
   {
      if(!g_internalOB[i].valid) continue;
      color clr=(g_internalOB[i].bias==BULLISH)?InpOB_BullColor:InpOB_BearColor;
      ObjSetRect(g_internalOB[i].boxName, g_internalOB[i].barTime, g_internalOB[i].top,
                 now, g_internalOB[i].bottom, clr, true, 1, true);
      string tag=(g_internalOB[i].bias==BULLISH)?"iOB+":"iOB-";
      double mid=(g_internalOB[i].top+g_internalOB[i].bottom)/2.0;
      ObjSetText(g_internalOB[i].lblName, g_internalOB[i].barTime, mid, tag, clr, 7, ANCHOR_RIGHT);
   }
   for(int i=0; i<ArraySize(g_swingOB); i++)
   {
      if(!g_swingOB[i].valid) continue;
      color clr=(g_swingOB[i].bias==BULLISH)?InpOB_BullColor:InpOB_BearColor;
      ObjSetRect(g_swingOB[i].boxName, g_swingOB[i].barTime, g_swingOB[i].top,
                 now, g_swingOB[i].bottom, clr, true, 2, true);
      string tag=(g_swingOB[i].bias==BULLISH)?"OB+":"OB-";
      double mid=(g_swingOB[i].top+g_swingOB[i].bottom)/2.0;
      ObjSetText(g_swingOB[i].lblName, g_swingOB[i].barTime, mid, tag, clr, 8, ANCHOR_RIGHT);
   }
}

// Update FVG rectangles - extend right
void GfxUpdateFVGs()
{
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
   datetime ext=now+(datetime)(PeriodSeconds()*InpFVGExtendBars);
   for(int i=0; i<ArraySize(g_fvg); i++)
   {
      if(!g_fvg[i].valid) continue;
      color clr=(g_fvg[i].bias==BULLISH)?InpFVG_BullColor:InpFVG_BearColor;
      ObjSetRect(g_fvg[i].boxName, g_fvg[i].barTime, g_fvg[i].top,
                 ext, g_fvg[i].bottom, clr, true, 1, true);
      string tag=(g_fvg[i].bias==BULLISH)?"FVG+":"FVG-";
      double mid=(g_fvg[i].top+g_fvg[i].bottom)/2.0;
      ObjSetText(g_fvg[i].lblName, g_fvg[i].barTime, mid, tag, clr, 7, ANCHOR_RIGHT);
   }
}

// Update Breaker Block rectangles - extend right
void GfxUpdateBreakerBlocks()
{
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
   for(int i=0; i<ArraySize(g_breakerBlocks); i++)
   {
      if(!g_breakerBlocks[i].valid) continue;
      color clr;
      string tag;
      if(g_breakerBlocks[i].isBreaker)
      { clr=(g_breakerBlocks[i].bias==BULLISH)?InpBreakerBullColor:InpBreakerBearColor;
        tag=(g_breakerBlocks[i].bias==BULLISH)?"B-BRK":"S-BRK"; }
      else
      { clr=(g_breakerBlocks[i].bias==BULLISH)?clrRoyalBlue:clrOrangeRed;
        tag=(g_breakerBlocks[i].bias==BULLISH)?"B-MIT":"S-MIT"; }
      ObjSetRect(g_breakerBlocks[i].boxName, g_breakerBlocks[i].barTime, g_breakerBlocks[i].top,
                 now, g_breakerBlocks[i].bottom, clr, true, 1, true);
      double lp=(g_breakerBlocks[i].bias==BULLISH)?g_breakerBlocks[i].bottom:g_breakerBlocks[i].top;
      ObjSetText(g_breakerBlocks[i].lblName, g_breakerBlocks[i].barTime, lp, tag, clr, 7,
                 (g_breakerBlocks[i].bias==BULLISH)?ANCHOR_UPPER:ANCHOR_LOWER);
   }
}

// Update EQH/EQL lines
void GfxUpdateEqualLevels()
{
   for(int i=0; i<ArraySize(g_equalHighs); i++)
   {
      if(!g_equalHighs[i].valid) continue;
      ObjSetTrend(g_equalHighs[i].lineName, g_equalHighs[i].time1, g_equalHighs[i].level,
                  g_equalHighs[i].time2, g_equalHighs[i].level, InpBearColor, STYLE_DOT, 1);
      datetime mid=g_equalHighs[i].time1+(g_equalHighs[i].time2-g_equalHighs[i].time1)/2;
      ObjSetText(g_equalHighs[i].lblName, mid, g_equalHighs[i].level, "EQH", InpBearColor, 7, ANCHOR_LOWER);
   }
   for(int i=0; i<ArraySize(g_equalLows); i++)
   {
      if(!g_equalLows[i].valid) continue;
      ObjSetTrend(g_equalLows[i].lineName, g_equalLows[i].time1, g_equalLows[i].level,
                  g_equalLows[i].time2, g_equalLows[i].level, InpBullColor, STYLE_DOT, 1);
      datetime mid=g_equalLows[i].time1+(g_equalLows[i].time2-g_equalLows[i].time1)/2;
      ObjSetText(g_equalLows[i].lblName, mid, g_equalLows[i].level, "EQL", InpBullColor, 7, ANCHOR_UPPER);
   }
}

// Sessions are drawn/updated in UpdateSessionState
void GfxUpdateSessions() { /* handled in UpdateSessionState */ }

// Previous Day/Week Levels
void GfxUpdatePreviousLevels()
{
   int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   if(g_prevDayHigh>0)
   {
      ObjSetHLine(PREFIX+"PDH", g_prevDayHigh, clrGray, STYLE_DOT, 1);
      ObjSetHLine(PREFIX+"PDL", g_prevDayLow,  clrGray, STYLE_DOT, 1);
      ObjSetHLine(PREFIX+"PDO", g_prevDayOpen, clrDarkGray, STYLE_DOT, 1);
      ObjSetHLine(PREFIX+"PDC", g_prevDayClose,clrDarkGray, STYLE_DOT, 1);
      // Labels using OBJ_TEXT at the right edge of the chart
      datetime rt=iTime(_Symbol,PERIOD_CURRENT,0)+(datetime)(PeriodSeconds()*5);
      ObjSetText(PREFIX+"PDH_L", rt, g_prevDayHigh, "PDH "+DoubleToString(g_prevDayHigh,d), clrGray, 7, ANCHOR_LEFT);
      ObjSetText(PREFIX+"PDL_L", rt, g_prevDayLow,  "PDL "+DoubleToString(g_prevDayLow,d),  clrGray, 7, ANCHOR_LEFT);
      ObjSetText(PREFIX+"PDO_L", rt, g_prevDayOpen, "PDO "+DoubleToString(g_prevDayOpen,d),  clrDarkGray, 7, ANCHOR_LEFT);
      ObjSetText(PREFIX+"PDC_L", rt, g_prevDayClose,"PDC "+DoubleToString(g_prevDayClose,d), clrDarkGray, 7, ANCHOR_LEFT);
   }
   if(g_prevWeekHigh>0)
   {
      ObjSetHLine(PREFIX+"PWH", g_prevWeekHigh, clrSilver, STYLE_DOT, 1);
      ObjSetHLine(PREFIX+"PWL", g_prevWeekLow,  clrSilver, STYLE_DOT, 1);
      datetime rt=iTime(_Symbol,PERIOD_CURRENT,0)+(datetime)(PeriodSeconds()*5);
      ObjSetText(PREFIX+"PWH_L", rt, g_prevWeekHigh, "PWH "+DoubleToString(g_prevWeekHigh,d), clrSilver, 7, ANCHOR_LEFT);
      ObjSetText(PREFIX+"PWL_L", rt, g_prevWeekLow,  "PWL "+DoubleToString(g_prevWeekLow,d),  clrSilver, 7, ANCHOR_LEFT);
   }
}

// Strong / Weak High / Low
void GfxUpdateStrongWeakLevels()
{
   if(g_trailing.top==0 || g_trailing.bottom==0) return;
   string hTag=(g_swingTrend==BEARISH)?"Strong High":"Weak High";
   string lTag=(g_swingTrend==BULLISH)?"Strong Low":"Weak Low";
   color hClr=(g_swingTrend==BEARISH)?InpBearColor:clrOrange;
   color lClr=(g_swingTrend==BULLISH)?InpBullColor:clrOrange;

   ObjSetHLine(PREFIX+"SWH", g_trailing.top, hClr, STYLE_SOLID, 1);
   ObjSetHLine(PREFIX+"SWL", g_trailing.bottom, lClr, STYLE_SOLID, 1);

   datetime rt=iTime(_Symbol,PERIOD_CURRENT,0)+(datetime)(PeriodSeconds()*5);
   ObjSetText(PREFIX+"SWH_L", rt, g_trailing.top, hTag, hClr, 8, ANCHOR_LEFT);
   ObjSetText(PREFIX+"SWL_L", rt, g_trailing.bottom, lTag, lClr, 8, ANCHOR_LEFT);
}

// IDM level lines
void GfxUpdateIDMLines()
{
   datetime rt=iTime(_Symbol,PERIOD_CURRENT,0)+(datetime)(PeriodSeconds()*10);

   // Bullish IDM
   if(!g_bullIDM_Taken && g_bullIDM_Level>0 && g_bullIDM_Time>0)
   {
      ObjSetTrend(PREFIX+"IDM_BullLine", g_bullIDM_Time, g_bullIDM_Level, rt, g_bullIDM_Level,
                  InpIDMColor, STYLE_DASH, 1);
      ObjSetText(PREFIX+"IDM_BullLbl", rt, g_bullIDM_Level, "IDM", InpIDMColor, 7, ANCHOR_LEFT);
   }
   else
   {
      ObjDelete(PREFIX+"IDM_BullLine"); ObjDelete(PREFIX+"IDM_BullLbl");
   }

   // Bearish IDM
   if(!g_bearIDM_Taken && g_bearIDM_Level>0 && g_bearIDM_Time>0)
   {
      ObjSetTrend(PREFIX+"IDM_BearLine", g_bearIDM_Time, g_bearIDM_Level, rt, g_bearIDM_Level,
                  InpIDMColor, STYLE_DASH, 1);
      ObjSetText(PREFIX+"IDM_BearLbl", rt, g_bearIDM_Level, "IDM", InpIDMColor, 7, ANCHOR_LEFT);
   }
   else
   {
      ObjDelete(PREFIX+"IDM_BearLine"); ObjDelete(PREFIX+"IDM_BearLbl");
   }

   // IDM Taken labels
   if(g_alerts.bullishIDM)
   {
      datetime t=iTime(_Symbol,PERIOD_CURRENT,1);
      string n=UniqueObjName("IDMTkn");
      ObjSetText(n, t, iLow(_Symbol,PERIOD_CURRENT,1), "IDM Taken", InpIDMColor, 8, ANCHOR_UPPER);
   }
   if(g_alerts.bearishIDM)
   {
      datetime t=iTime(_Symbol,PERIOD_CURRENT,1);
      string n=UniqueObjName("IDMTkn");
      ObjSetText(n, t, iHigh(_Symbol,PERIOD_CURRENT,1), "IDM Taken", InpIDMColor, 8, ANCHOR_LOWER);
   }
}

// Displacement candle labels
void GfxDrawDisplacementLabels()
{
   datetime t=iTime(_Symbol,PERIOD_CURRENT,1);
   if(g_alerts.bullishDisplacement)
   {
      string n=UniqueObjName("DISP");
      ObjSetText(n, t, iLow(_Symbol,PERIOD_CURRENT,1), "DISP", InpBullColor, 8, ANCHOR_UPPER);
   }
   if(g_alerts.bearishDisplacement)
   {
      string n=UniqueObjName("DISP");
      ObjSetText(n, t, iHigh(_Symbol,PERIOD_CURRENT,1), "DISP", InpBearColor, 8, ANCHOR_LOWER);
   }
   // MSS labels when displacement + CHoCH align
   bool bullMSS=g_alerts.bullishDisplacement && (g_alerts.internalBullishCHoCH||g_alerts.swingBullishCHoCH);
   bool bearMSS=g_alerts.bearishDisplacement && (g_alerts.internalBearishCHoCH||g_alerts.swingBearishCHoCH);
   if(bullMSS)
   {
      string n=UniqueObjName("MSS");
      ObjSetText(n, t, iLow(_Symbol,PERIOD_CURRENT,1), "MSS", InpBullColor, 9, ANCHOR_UPPER);
   }
   if(bearMSS)
   {
      string n=UniqueObjName("MSS");
      ObjSetText(n, t, iHigh(_Symbol,PERIOD_CURRENT,1), "MSS", InpBearColor, 9, ANCHOR_LOWER);
   }
}

// Dashboard
void GfxUpdateDashboard()
{
   int x=InpDashX, y=InpDashY;
   ObjSetRectLabel(PREFIX+"DashBG", x, y, 230, 275, InpDashBG, clrSlateGray);

   string sn="";
   switch(InpStrategy)
   {
      case STRATEGY_1_CHOCH_OB_RETEST:  sn="1.CHoCH+OB(85%)"; break;
      case STRATEGY_2_SWEEP_BOS:        sn="2.Sweep+BOS(82%)"; break;
      case STRATEGY_3_IDM_CONTINUATION: sn="3.IDM Cont(80%)";  break;
      case STRATEGY_4_SWING_BOS_RETEST: sn="4.BOS Ret(78%)";   break;
      case STRATEGY_5_EQH_EQL_FADE:     sn="5.EQH/EQL(75%)";  break;
      case STRATEGY_6_SESSION_LIQ_GRAB: sn="6.SessGrab(74%)";  break;
      case STRATEGY_7_BREAKER_ENTRY:    sn="7.Breaker(72%)";   break;
      case STRATEGY_8_PDH_PDL_SWEEP:    sn="8.PDH/PDL(70%)";   break;
      case STRATEGY_9_FVG_FILL:         sn="9.FVGFill(68%)";   break;
      case STRATEGY_10_STRONG_WEAK:     sn="10.S/W HL(65%)";   break;
   }

   ObjSetLabel(PREFIX+"D_Title",   x+10, y+8,   "SMC+ Dashboard", clrWhite, 10);
   ObjSetLabel(PREFIX+"D_Strat",   x+10, y+30,  "Strategy: "+sn, clrGold, 8);

   string sw=(g_swingTrend==BULLISH)?"Bullish":(g_swingTrend==BEARISH)?"Bearish":"Neutral";
   color sc=(g_swingTrend==BULLISH)?InpBullColor:(g_swingTrend==BEARISH)?InpBearColor:clrGray;
   ObjSetLabel(PREFIX+"D_Swing",   x+10, y+50,  "Swing: "+sw, sc, 8);

   string it=(g_internalTrend==BULLISH)?"Bullish":(g_internalTrend==BEARISH)?"Bearish":"Neutral";
   color ic=(g_internalTrend==BULLISH)?InpBullColor:(g_internalTrend==BEARISH)?InpBearColor:clrGray;
   ObjSetLabel(PREFIX+"D_Int",     x+10, y+70,  "Internal: "+it, ic, 8);

   string ss="None"; color ssc=clrGray;
   if(g_asiaSession.active)   {ss="Asia"; ssc=InpAsiaColor;}
   if(g_londonSession.active) {ss="London"; ssc=InpLondonColor;}
   if(g_nySession.active)     {ss="New York"; ssc=InpNYColor;}
   ObjSetLabel(PREFIX+"D_Sess",    x+10, y+90,  "Session: "+ss, ssc, 8);

   int obc=0;
   for(int i=0;i<ArraySize(g_internalOB);i++) if(g_internalOB[i].valid) obc++;
   for(int i=0;i<ArraySize(g_swingOB);i++) if(g_swingOB[i].valid) obc++;
   ObjSetLabel(PREFIX+"D_OB",      x+10, y+110, "Order Blocks: "+IntegerToString(obc), clrSilver, 8);

   int fc=0; for(int i=0;i<ArraySize(g_fvg);i++) if(g_fvg[i].valid) fc++;
   ObjSetLabel(PREFIX+"D_FVG",     x+10, y+130, "FVGs: "+IntegerToString(fc), clrSilver, 8);

   int bc=0; for(int i=0;i<ArraySize(g_breakerBlocks);i++) if(g_breakerBlocks[i].valid) bc++;
   ObjSetLabel(PREFIX+"D_BRK",     x+10, y+150, "Breakers: "+IntegerToString(bc), clrSilver, 8);

   string le="None"; color lec=clrGray;
   if(g_alerts.internalBullishCHoCH)      {le="Bull iCHoCH"; lec=InpBullColor;}
   else if(g_alerts.internalBearishCHoCH) {le="Bear iCHoCH"; lec=InpBearColor;}
   else if(g_alerts.swingBullishBOS)      {le="Bull BOS"; lec=InpBullColor;}
   else if(g_alerts.swingBearishBOS)      {le="Bear BOS"; lec=InpBearColor;}
   else if(g_alerts.bullishSweep)         {le="SSL Sweep"; lec=InpSweepBullColor;}
   else if(g_alerts.bearishSweep)         {le="BSL Sweep"; lec=InpSweepBearColor;}
   else if(g_alerts.bullishIDM)           {le="Bull IDM"; lec=InpIDMColor;}
   else if(g_alerts.bearishIDM)           {le="Bear IDM"; lec=InpIDMColor;}
   else if(g_alerts.bullishDisplacement)  {le="Bull DISP"; lec=InpBullColor;}
   else if(g_alerts.bearishDisplacement)  {le="Bear DISP"; lec=InpBearColor;}
   ObjSetLabel(PREFIX+"D_Event",   x+10, y+170, "Last Event: "+le, lec, 8);

   int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   string pdl_s="---";
   if(g_prevDayHigh>0) pdl_s="PDH:"+DoubleToString(g_prevDayHigh,d)+" PDL:"+DoubleToString(g_prevDayLow,d);
   ObjSetLabel(PREFIX+"D_PDH",     x+10, y+190, pdl_s, clrSilver, 7);

   int tc=CountOpenTrades();
   ObjSetLabel(PREFIX+"D_Trades",  x+10, y+210, "Open Trades: "+IntegerToString(tc), tc>0?clrGold:clrSilver, 8);

   double pnl=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(g_posInfo.SelectByIndex(i) && g_posInfo.Symbol()==_Symbol && g_posInfo.Magic()==InpMagicNumber)
         pnl+=g_posInfo.Profit();
   ObjSetLabel(PREFIX+"D_PnL",     x+10, y+230, "Session P&L: "+DoubleToString(pnl,2), pnl>=0?InpBullColor:InpBearColor, 8);

   string sw_lbl=(g_swingTrend==BULLISH)?"UP":(g_swingTrend==BEARISH)?"DN":"--";
   ObjSetLabel(PREFIX+"D_Pulse",   x+10, y+250, "Pulse: Swing="+sw_lbl+" Int="+(string)((g_internalTrend==BULLISH)?"UP":(g_internalTrend==BEARISH)?"DN":"--"), clrSilver, 7);
}

void GfxDrawTradeArrow(int dir, double price, datetime t)
{
   string n=UniqueObjName("Trd");
   int code=(dir==BULLISH)?233:234;
   ObjSetArrow(n, t, price, code, (dir==BULLISH)?InpBullColor:InpBearColor, 3);
}

//+------------------------------------------------------------------+
//| ================ STRATEGY IMPLEMENTATIONS ================        |
//+------------------------------------------------------------------+

TradeSignal Strategy1_CHoCH_OB()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;

   if(g_alerts.internalBullishCHoCH || g_alerts.internalBearishCHoCH)
   {
      for(int i=ArraySize(g_internalOB)-1; i>=0; i--)
      {
         if(!g_internalOB[i].valid) continue;
         if(g_alerts.internalBullishCHoCH && g_internalOB[i].bias==BULLISH)
         { g_chochPending=true; g_chochDirection=BULLISH;
           g_chochOB_Top=g_internalOB[i].top; g_chochOB_Bottom=g_internalOB[i].bottom;
           g_chochOB_Time=g_internalOB[i].barTime; g_chochBar=g_barCount; break; }
         if(g_alerts.internalBearishCHoCH && g_internalOB[i].bias==BEARISH)
         { g_chochPending=true; g_chochDirection=BEARISH;
           g_chochOB_Top=g_internalOB[i].top; g_chochOB_Bottom=g_internalOB[i].bottom;
           g_chochOB_Time=g_internalOB[i].barTime; g_chochBar=g_barCount; break; }
      }
   }
   if(g_chochPending && g_barCount-g_chochBar<=30)
   {
      double l=iLow(_Symbol,PERIOD_CURRENT,1), h=iHigh(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
      if(g_chochDirection==BULLISH && l<=g_chochOB_Top && l>=g_chochOB_Bottom && c>g_chochOB_Bottom)
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=g_chochOB_Bottom-g_atr14*0.2;
        sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
        sig.reason="S1:CHoCH+OB BUY"; sig.valid=true; g_chochPending=false; }
      if(g_chochDirection==BEARISH && h>=g_chochOB_Bottom && h<=g_chochOB_Top && c<g_chochOB_Top)
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=g_chochOB_Top+g_atr14*0.2;
        sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
        sig.reason="S1:CHoCH+OB SELL"; sig.valid=true; g_chochPending=false; }
   }
   else if(g_chochPending && g_barCount-g_chochBar>30) g_chochPending=false;
   return sig;
}

TradeSignal Strategy2_SweepBOS()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(g_alerts.bullishSweep) { g_sweepPending=true; g_sweepDirection=BULLISH; g_sweepLevel=iLow(_Symbol,PERIOD_CURRENT,1); g_sweepBar=g_barCount; }
   if(g_alerts.bearishSweep) { g_sweepPending=true; g_sweepDirection=BEARISH; g_sweepLevel=iHigh(_Symbol,PERIOD_CURRENT,1); g_sweepBar=g_barCount; }
   if(g_sweepPending && g_barCount-g_sweepBar<=20)
   {
      if(g_sweepDirection==BULLISH && (g_alerts.internalBullishBOS||g_alerts.swingBullishBOS))
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=g_sweepLevel-g_atr14*0.3;
        sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
        sig.reason="S2:Sweep+BOS BUY"; sig.valid=true; g_sweepPending=false; }
      if(g_sweepDirection==BEARISH && (g_alerts.internalBearishBOS||g_alerts.swingBearishBOS))
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=g_sweepLevel+g_atr14*0.3;
        sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
        sig.reason="S2:Sweep+BOS SELL"; sig.valid=true; g_sweepPending=false; }
   }
   else if(g_sweepPending && g_barCount-g_sweepBar>20) g_sweepPending=false;
   return sig;
}

TradeSignal Strategy3_IDM()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(g_alerts.bullishIDM && g_swingTrend==BULLISH)
   { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     sig.stopLoss=iLow(_Symbol,PERIOD_CURRENT,1)-g_atr14*0.3;
     sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
     sig.reason="S3:IDM BUY"; sig.valid=true; }
   if(g_alerts.bearishIDM && g_swingTrend==BEARISH)
   { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     sig.stopLoss=iHigh(_Symbol,PERIOD_CURRENT,1)+g_atr14*0.3;
     sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
     sig.reason="S3:IDM SELL"; sig.valid=true; }
   return sig;
}

TradeSignal Strategy4_SwingBOS()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(g_alerts.swingBullishBOS && g_swingTrend==BULLISH)
   { g_bosRetestPending=true; g_bosDirection=BULLISH; g_bosLevel=g_swingHigh.currentLevel; g_bosBar=g_barCount; }
   if(g_alerts.swingBearishBOS && g_swingTrend==BEARISH)
   { g_bosRetestPending=true; g_bosDirection=BEARISH; g_bosLevel=g_swingLow.currentLevel; g_bosBar=g_barCount; }
   if(g_bosRetestPending && g_barCount-g_bosBar<=40)
   {
      double l=iLow(_Symbol,PERIOD_CURRENT,1), h=iHigh(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
      if(g_bosDirection==BULLISH && l<=g_bosLevel+g_atr14*0.5 && l>=g_bosLevel-g_atr14*0.5 && c>g_bosLevel)
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=l-g_atr14*0.5; sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
        sig.reason="S4:BOS Retest BUY"; sig.valid=true; g_bosRetestPending=false; }
      if(g_bosDirection==BEARISH && h>=g_bosLevel-g_atr14*0.5 && h<=g_bosLevel+g_atr14*0.5 && c<g_bosLevel)
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=h+g_atr14*0.5; sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
        sig.reason="S4:BOS Retest SELL"; sig.valid=true; g_bosRetestPending=false; }
   }
   else if(g_bosRetestPending && g_barCount-g_bosBar>40) g_bosRetestPending=false;
   return sig;
}

TradeSignal Strategy5_EQH_EQL()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
   for(int i=ArraySize(g_equalHighs)-1; i>=0; i--)
   {
      if(!g_equalHighs[i].valid) continue;
      if(h>g_equalHighs[i].level+g_atr14*0.05 && c<g_equalHighs[i].level)
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=h+g_atr14*0.2;
        sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*MathMin(InpRR_Ratio,1.5);
        sig.reason="S5:EQH Fade SELL"; sig.valid=true; g_equalHighs[i].valid=false; break; }
   }
   if(sig.valid) return sig;
   for(int i=ArraySize(g_equalLows)-1; i>=0; i--)
   {
      if(!g_equalLows[i].valid) continue;
      if(l<g_equalLows[i].level-g_atr14*0.05 && c>g_equalLows[i].level)
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=l-g_atr14*0.2;
        sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*MathMin(InpRR_Ratio,1.5);
        sig.reason="S5:EQL Fade BUY"; sig.valid=true; g_equalLows[i].valid=false; break; }
   }
   return sig;
}

TradeSignal Strategy6_SessionGrab()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   bool inLon=IsInSession(InpLondonStart,InpLondonEnd);
   bool inNY=IsInSession(InpNYStart,InpNYEnd);
   if(!inLon && !inNY) return sig;

   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);

   if(g_sessionGrabPending && g_barCount-g_sessionGrabBar<=10)
   {
      sig.direction=g_sessionGrabDir;
      sig.entryPrice=(g_sessionGrabDir==BULLISH)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
      sig.stopLoss=g_sessionGrabStop;
      double rd=MathAbs(sig.entryPrice-sig.stopLoss);
      sig.takeProfit=(g_sessionGrabDir==BULLISH)?sig.entryPrice+rd*InpRR_Ratio:sig.entryPrice-rd*InpRR_Ratio;
      sig.reason="S6:SessGrab "+(string)((g_sessionGrabDir==BULLISH)?"BUY":"SELL");
      sig.valid=true; g_sessionGrabPending=false; return sig;
   }
   if(inLon && !g_asiaSession.active && g_asiaSession.high>0 && g_asiaSession.low>0)
   {
      if(h>g_asiaSession.high && c<g_asiaSession.high)
      { g_sessionGrabPending=true; g_sessionGrabDir=BEARISH; g_sessionGrabStop=h+g_atr14*0.3; g_sessionGrabBar=g_barCount; }
      if(l<g_asiaSession.low && c>g_asiaSession.low)
      { g_sessionGrabPending=true; g_sessionGrabDir=BULLISH; g_sessionGrabStop=l-g_atr14*0.3; g_sessionGrabBar=g_barCount; }
   }
   if(inNY && !g_londonSession.active && g_londonSession.high>0 && g_londonSession.low>0)
   {
      if(h>g_londonSession.high && c<g_londonSession.high)
      { g_sessionGrabPending=true; g_sessionGrabDir=BEARISH; g_sessionGrabStop=h+g_atr14*0.3; g_sessionGrabBar=g_barCount; }
      if(l<g_londonSession.low && c>g_londonSession.low)
      { g_sessionGrabPending=true; g_sessionGrabDir=BULLISH; g_sessionGrabStop=l-g_atr14*0.3; g_sessionGrabBar=g_barCount; }
   }
   if(g_sessionGrabPending && g_barCount-g_sessionGrabBar>10) g_sessionGrabPending=false;
   return sig;
}

TradeSignal Strategy7_Breaker()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(g_alerts.internalBullishCHoCH||g_alerts.swingBullishCHoCH)
   {
      for(int i=ArraySize(g_breakerBlocks)-1; i>=0; i--)
         if(g_breakerBlocks[i].valid && g_breakerBlocks[i].isBreaker && g_breakerBlocks[i].bias==BULLISH)
         { g_breakerPending=true; g_breakerDirection=BULLISH;
           g_breakerTop=g_breakerBlocks[i].top; g_breakerBottom=g_breakerBlocks[i].bottom;
           g_breakerBar=g_barCount; break; }
   }
   if(g_alerts.internalBearishCHoCH||g_alerts.swingBearishCHoCH)
   {
      for(int i=ArraySize(g_breakerBlocks)-1; i>=0; i--)
         if(g_breakerBlocks[i].valid && g_breakerBlocks[i].isBreaker && g_breakerBlocks[i].bias==BEARISH)
         { g_breakerPending=true; g_breakerDirection=BEARISH;
           g_breakerTop=g_breakerBlocks[i].top; g_breakerBottom=g_breakerBlocks[i].bottom;
           g_breakerBar=g_barCount; break; }
   }
   if(g_breakerPending && g_barCount-g_breakerBar<=30)
   {
      double l=iLow(_Symbol,PERIOD_CURRENT,1), h=iHigh(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
      if(g_breakerDirection==BULLISH && l<=g_breakerTop && l>=g_breakerBottom && c>g_breakerBottom)
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=g_breakerBottom-g_atr14*0.2;
        sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
        sig.reason="S7:Breaker BUY"; sig.valid=true; g_breakerPending=false; }
      if(g_breakerDirection==BEARISH && h>=g_breakerBottom && h<=g_breakerTop && c<g_breakerTop)
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=g_breakerTop+g_atr14*0.2;
        sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
        sig.reason="S7:Breaker SELL"; sig.valid=true; g_breakerPending=false; }
   }
   else if(g_breakerPending && g_barCount-g_breakerBar>30) g_breakerPending=false;
   return sig;
}

TradeSignal Strategy8_PDH_PDL()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(!IsInSession(InpLondonStart,InpLondonEnd) && !IsInSession(InpNYStart,InpNYEnd)) return sig;
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
   if(g_prevDayHigh>0 && h>g_prevDayHigh && c<g_prevDayHigh && (g_internalTrend==BEARISH||g_swingTrend==BEARISH))
   { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     sig.stopLoss=h+g_atr14*0.3; sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
     sig.reason="S8:PDH Sweep SELL"; sig.valid=true; }
   if(g_prevDayLow>0 && l<g_prevDayLow && c>g_prevDayLow && (g_internalTrend==BULLISH||g_swingTrend==BULLISH))
   { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     sig.stopLoss=l-g_atr14*0.3; sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
     sig.reason="S8:PDL Sweep BUY"; sig.valid=true; }
   return sig;
}

TradeSignal Strategy9_FVG()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   double h=iHigh(_Symbol,PERIOD_CURRENT,1), l=iLow(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
   for(int i=ArraySize(g_fvg)-1; i>=0; i--)
   {
      if(!g_fvg[i].valid || g_fvg[i].mitigated) continue;
      if(g_fvg[i].bias==BULLISH && g_swingTrend==BULLISH && l<=g_fvg[i].top && l>=g_fvg[i].bottom && c>g_fvg[i].bottom)
      { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        sig.stopLoss=g_fvg[i].bottom-g_atr14*0.2;
        sig.takeProfit=sig.entryPrice+(sig.entryPrice-sig.stopLoss)*InpRR_Ratio;
        sig.reason="S9:FVG BUY"; sig.valid=true; g_fvg[i].mitigated=true; break; }
      if(g_fvg[i].bias==BEARISH && g_swingTrend==BEARISH && h>=g_fvg[i].bottom && h<=g_fvg[i].top && c<g_fvg[i].top)
      { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        sig.stopLoss=g_fvg[i].top+g_atr14*0.2;
        sig.takeProfit=sig.entryPrice-(sig.stopLoss-sig.entryPrice)*InpRR_Ratio;
        sig.reason="S9:FVG SELL"; sig.valid=true; g_fvg[i].mitigated=true; break; }
   }
   return sig;
}

TradeSignal Strategy10_StrongWeak()
{
   TradeSignal sig; sig.valid=false;
   if(CountOpenTrades()>=InpMaxTrades) return sig;
   if(g_trailing.top==0||g_trailing.bottom==0) return sig;

   if(g_swingTrend==BULLISH && (g_alerts.internalBullishBOS||g_alerts.internalBullishCHoCH))
   {
      for(int i=ArraySize(g_internalOB)-1; i>=0; i--)
      {
         if(!g_internalOB[i].valid || g_internalOB[i].bias!=BULLISH) continue;
         double l=iLow(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
         if(l<=g_internalOB[i].top && c>g_internalOB[i].bottom)
         { sig.direction=BULLISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
           sig.stopLoss=g_internalOB[i].bottom-g_atr14*0.2;
           sig.takeProfit=g_trailing.top;
           double rd=sig.entryPrice-sig.stopLoss;
           if(rd>0 && (sig.takeProfit-sig.entryPrice)/rd>=1.0)
           { sig.reason="S10:Weak High BUY"; sig.valid=true; } break; }
      }
   }
   if(!sig.valid && g_swingTrend==BEARISH && (g_alerts.internalBearishBOS||g_alerts.internalBearishCHoCH))
   {
      for(int i=ArraySize(g_internalOB)-1; i>=0; i--)
      {
         if(!g_internalOB[i].valid || g_internalOB[i].bias!=BEARISH) continue;
         double h=iHigh(_Symbol,PERIOD_CURRENT,1), c=iClose(_Symbol,PERIOD_CURRENT,1);
         if(h>=g_internalOB[i].bottom && c<g_internalOB[i].top)
         { sig.direction=BEARISH; sig.entryPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
           sig.stopLoss=g_internalOB[i].top+g_atr14*0.2;
           sig.takeProfit=g_trailing.bottom;
           double rd=sig.stopLoss-sig.entryPrice;
           if(rd>0 && (sig.entryPrice-sig.takeProfit)/rd>=1.0)
           { sig.reason="S10:Weak Low SELL"; sig.valid=true; } break; }
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
   double sd=MathAbs(signal.entryPrice-signal.stopLoss)/_Point;
   if(sd<1) return;
   double lots=CalculateLotSize(sd);
   int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   signal.stopLoss=NormalizeDouble(signal.stopLoss,d);
   signal.takeProfit=NormalizeDouble(signal.takeProfit,d);
   signal.entryPrice=NormalizeDouble(signal.entryPrice,d);

   bool ok=false;
   if(signal.direction==BULLISH) ok=g_trade.Buy(lots,_Symbol,signal.entryPrice,signal.stopLoss,signal.takeProfit,signal.reason);
   else                          ok=g_trade.Sell(lots,_Symbol,signal.entryPrice,signal.stopLoss,signal.takeProfit,signal.reason);

   if(ok)
   {
      Print("Trade: ",signal.reason," Lots=",lots," SL=",signal.stopLoss," TP=",signal.takeProfit);
      if(InpDrawGraphics) GfxDrawTradeArrow(signal.direction, signal.entryPrice, iTime(_Symbol,PERIOD_CURRENT,0));
   }
   else Print("Trade FAILED: ",signal.reason," Err=",GetLastError());
}

//+------------------------------------------------------------------+
//| TRAILING STOP                                                     |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(g_atrTrail<=0) return;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!g_posInfo.SelectByIndex(i)) continue;
      if(g_posInfo.Symbol()!=_Symbol || g_posInfo.Magic()!=InpMagicNumber) continue;
      double sl=g_posInfo.StopLoss(), cp=g_posInfo.PriceCurrent();
      double td=g_atrTrail*InpTrailATR_Mult;
      int d=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
      if(g_posInfo.PositionType()==POSITION_TYPE_BUY)
      { double ns=NormalizeDouble(cp-td,d); if(ns>sl && ns<cp) g_trade.PositionModify(g_posInfo.Ticket(),ns,g_posInfo.TakeProfit()); }
      else
      { double ns=NormalizeDouble(cp+td,d); if((ns<sl||sl==0) && ns>cp) g_trade.PositionModify(g_posInfo.Ticket(),ns,g_posInfo.TakeProfit()); }
   }
}
//+------------------------------------------------------------------+
