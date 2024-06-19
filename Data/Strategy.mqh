//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#ifndef CStrategy_MQH
#define CStrategy_MQH

#include <Object.mqh>
#include <Trade\Trade.mqh>
#include <Arrays\ArrayLong.mqh>

enum ETradeSide {
   Both,
   Buy,
   Sell,
   None
};

enum EClosePositions {
   Both,
   Buy,
   Sell
};

class CStrategyParams {
public:
   ETradeSide        TradeSide;
   ulong             Magic;
   double            Risk;
   int               AtrPeriod;
   double            SlCoef;
   string            Comment;

public:
   CStrategyParams(ETradeSide side, ulong magic, double risk, int atrPeriod, double slCoef, string comment = "")
      :              TradeSide(side), Magic(magic), Risk(risk), AtrPeriod(atrPeriod), SlCoef(slCoef),
                     Comment(comment) {

   }

   // Copy constructor
   CStrategyParams(const CStrategyParams &other)
      : TradeSide(other.TradeSide), Magic(other.Magic), Risk(other.Risk), AtrPeriod(other.AtrPeriod), SlCoef(other.SlCoef), Comment(other.Comment) {
   }
};

class CStrategy : public CObject {
protected:
   CStrategyParams*  params;
   CTrade            trade;

   int               atrHandle;
public:
   CStrategy(CStrategyParams* strategyParams) {
      this.params = strategyParams;
      trade.SetExpertMagicNumber(this.params.Magic);
      Init();
   }
   ~CStrategy() {
      Deinit();
      delete params;
      params = NULL;
   }

public:
   virtual double    NormalizePrice(double v) {
      return NormalizeDouble(v, Digits());
   }
   //virtual double NormalizeLots(string sym, double v);

   virtual bool      IsBuyAllowed() {
      return this.params.TradeSide == ETradeSide::Both ||
             this.params.TradeSide == ETradeSide::Buy;
   }

   virtual bool      IsSellAllowed() {
      return this.params.TradeSide == ETradeSide::Both ||
             this.params.TradeSide == ETradeSide::Sell;
   }

   virtual bool      CanBuy() {
      return true;
   }
   virtual bool      CanSell() {
      return false;
   }

   virtual bool      CanCloseBuy() {
      return false;
   }
   virtual bool      CanCloseSell() {
      return false;
   }

   virtual double    GetCurrentAtr();
   virtual double    CalcLots(double slDistance);
   virtual bool      BuyLong(MqlTick& tick);
   virtual bool      SellShort(MqlTick& tick);
   virtual double    CalcBuySl(double ask, double atr);
   virtual double    CalcSellSl(double bid, double atr);

   virtual void      ClosePositions(string sym, EClosePositions side);
   virtual void      ClosePosition(ulong ticket);
   virtual bool      CountOpenPositions(string sym, int &cntBuy, int &cntSell);
   virtual void      GetOpenPositions(string sym, CArrayLong& OutResult);
   virtual void      Tick(MqlTick& tick);
   virtual bool      Init();
   virtual bool      Deinit();


};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Closes certain position byt its ticket                           |
//+------------------------------------------------------------------+
void CStrategy::ClosePosition(ulong ticket) {
   trade.PositionClose(ticket);
}

//+------------------------------------------------------------------+
//| Calculate lots for stop los based on risk                        |
//+------------------------------------------------------------------+
double CStrategy::CalcLots(double slDistance) {
   string sym = Symbol();
   double tickSize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);

   if(tickSize == 0.0 || tickValue == 0.0 || lotStep == 0.0) {
      return 0.0;
   }

   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * (params.Risk/100);
   double moneyLotStep = (slDistance / tickSize) * tickValue * lotStep;
   if(moneyLotStep == 0.0) {
      return 0.0;
   }
   double lots = MathFloor(riskMoney / moneyLotStep) * lotStep;
   
   double minVolume = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   
   if(lots >= maxVolume)
      lots = maxVolume;
      
   if(lots <= minVolume)
      lots = minVolume;

   return lots;
}
//+------------------------------------------------------------------+
//| Calculates atr of current candle                                 |
//+------------------------------------------------------------------+
double CStrategy::GetCurrentAtr() {
   double atrBuffer[];
   static int cnt = 2;
   int res = CopyBuffer(atrHandle, 0, 0, cnt, atrBuffer);
   if(res != cnt) {
      return 0.0;
   }
   return atrBuffer[0];
}
//+------------------------------------------------------------------+
//| Enter long positions with stop loss based on risk                |
//+------------------------------------------------------------------+
bool CStrategy::BuyLong(MqlTick& tick) {
   double atr = GetCurrentAtr();
   if(atr == 0.0) {
      return false;
   }
   PrintFormat("Tick ask: %f, tick atr: %f", tick.ask, atr);
   double sl = CalcBuySl(tick.ask, atr);
   double lots = CalcLots(tick.ask - sl);
   trade.Buy(lots, Symbol(), tick.ask, sl, 0.0, params.Comment);
   return true;
}

//+------------------------------------------------------------------+
//| Enter short position with stop loss based on risk                |
//+------------------------------------------------------------------+
bool CStrategy::SellShort(MqlTick& tick) {
   double atr = GetCurrentAtr();
   if(atr == 0.0) {
      return false;
   }
   double sl = CalcSellSl(tick.bid, atr);
   double lots = CalcLots(sl - tick.bid);
   trade.Sell(lots, Symbol(), tick.bid, sl, 0.0, params.Comment);
   return true;
}


//+------------------------------------------------------------------+
//| Initialize indicators                                            |
//+------------------------------------------------------------------+
bool CStrategy::Init(void) {
   atrHandle = iATR(Symbol(), PERIOD_CURRENT, params.AtrPeriod);
   return true;
}

//+------------------------------------------------------------------+
//| Release indicators                                               |
//+------------------------------------------------------------------+
bool CStrategy::Deinit(void) {
   IndicatorRelease(atrHandle);
   return true;
}

//+------------------------------------------------------------------+
//| Calculate stop loss for BUY positions (ask - sl)                 |
//+------------------------------------------------------------------+
double CStrategy::CalcBuySl(double ask, double atr) {
   PrintFormat("Calc buy sl: %f - %f * %f", ask, atr, params.SlCoef);
   return NormalizePrice(ask - (atr * params.SlCoef));
}
//+------------------------------------------------------------------+
//| Calculate stop loss for SELL positions (bid + sl)                |
//+------------------------------------------------------------------+
double CStrategy::CalcSellSl(double bid, double atr) {
   return NormalizePrice(bid + atr * params.SlCoef);
}

//+------------------------------------------------------------------+
//| Grab all open positions for this strategy on selected symbol     |
//| (Array of tickets)                                               |
//+------------------------------------------------------------------+
void CStrategy::GetOpenPositions(string sym, CArrayLong& OutResult) {
   OutResult.Clear();
   int total = PositionsTotal();
   for (int i = total - 1; i >= 0; --i) {
      // Get position ticket
      ulong ticket = PositionGetTicket(i);
      if (ticket <= 0) {
         Print("[" + __FUNCTION__ + "] ERROR: Failed to get position ticket");
         continue;
      }

      // Select positions
      if (!PositionSelectByTicket(ticket)) {
         Print("[" + __FUNCTION__ + "] ERROR: Failed to select position by ticket");
         continue;
      }

      // Obtain magic numbers of positions
      long magicNumber;
      if (!PositionGetInteger(POSITION_MAGIC, magicNumber)) {
         Print("[" + __FUNCTION__ + "] ERROR: Failed to get position magic number");
         continue;
      }

      // Compare magic numbers
      if (magicNumber == params.Magic) {
         // Compare symbols
         string positionSymbol;
         if(!PositionGetString(POSITION_SYMBOL, positionSymbol)) {
            Print("[" + __FUNCTION__ + "] ERROR: Failed to get position symbol");
            continue;
         }
         if(positionSymbol == sym) {
            OutResult.Add(ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Count amount of open buy and sell positions                      |
//+------------------------------------------------------------------+
bool CStrategy::CountOpenPositions(string sym,int &cntBuy,int &cntSell) {
   cntBuy = 0;
   cntSell = 0;
   CArrayLong pos;
   GetOpenPositions(sym, pos);
   for(int i = 0; i < pos.Total(); ++i) {
      ulong ticket = pos.At(i);
      if(!PositionSelectByTicket(ticket)) {
         Print("[" + __FUNCTION__ + "] ERROR: Failed to select position" + IntegerToString(ticket));
         return false;
      }
      long type;
      PositionGetInteger(POSITION_TYPE, type);
      if (type == POSITION_TYPE_BUY) {
         cntBuy++;
      } else if (type == POSITION_TYPE_SELL) {
         cntSell++;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Close all positions for this strategy                            |
//+------------------------------------------------------------------+
void CStrategy::ClosePositions(string sym, EClosePositions side) {
   CArrayLong pos;
   GetOpenPositions(sym, pos);
   for(int i = 0; i < pos.Total(); ++i) {
      ulong ticket = pos.At(i);
      if(!PositionSelectByTicket(ticket)) {
         Print("[" + __FUNCTION__ + "] ERROR: Failed to select position" + IntegerToString(ticket));
         continue;
      }
      long type;
      PositionGetInteger(POSITION_TYPE, type);
      if (type == POSITION_TYPE_BUY && (side == EClosePositions::Both || side == EClosePositions::Buy)) {
         // Close buy
         ClosePosition(ticket);
      } else if (type == POSITION_TYPE_SELL && (side == EClosePositions::Both || side == EClosePositions::Sell)) {
         // Close sell
         ClosePosition(ticket);
      }
   }
}


//+------------------------------------------------------------------+
//| Main logic of EA                                                 |
//+------------------------------------------------------------------+
void CStrategy::Tick(MqlTick& tick) {
   string sym = Symbol();
   int cntBuy, cntSell;

// Count positions
   CountOpenPositions(sym, cntBuy, cntSell);

// Can we close something?
   if((cntBuy + cntSell) > 0) {
      if(cntBuy > 0 && CanCloseBuy()) {
         ClosePositions(sym, EClosePositions::Buy);
      }

      if(cntSell > 0 && CanCloseSell()) {
         ClosePositions(sym, EClosePositions::Sell);
      }
      return;
   } else {
      //PrintFormat("%s tick.. buy allowed: %d", params.Comment, IsBuyAllowed());
// Enter buy if can
      if(IsBuyAllowed() && CanBuy()) {
         BuyLong(tick);
         return;
      }

// Enter sell if can
      if(IsSellAllowed() && CanSell()) {
         SellShort(tick);
         return;
      }
   }
}


#endif // CStrategy_MQH
//+------------------------------------------------------------------+
