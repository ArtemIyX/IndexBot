//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "..\Data\Strategy.mqh"
namespace LarryInput {
   input group "Larry - [RSI]";
   input ulong InpMagic = 200;                     // Magic
   input double InpRisk = 1.0;                     // Risk
   input double InpSlCoef = 1.5;                   // Stop Loss
   input double InpTpCoef = 1.5;                   // Take Profit
   input ETradeSide InpSide = ETradeSide::Both;    // Trades
   input ETakeProfitMethod InpTakeProfit = ETakeProfitMethod::Manual; // Take Profit Method
   input int InpMaPeriod = 200;                    // Filter Period
   input double InpRsiLower = 25.0;                // Lower RSI
   input double InpRsiUpper = 75.0;                // Upper RSI
}


class CLarryRsiParams : public CStrategyParams {
public:
   int MaPeriod;
   double RsiLower;
   double RsiUpper;
public:
   CLarryRsiParams(CStrategyParams& basic,
                   int maPeriod, double rsiLower, double rsiUpper)
      : CStrategyParams(basic),
        MaPeriod(maPeriod), RsiLower(rsiLower), RsiUpper(rsiUpper) {
   }
};

class CLarryRsi : public CStrategy {
protected:
   CLarryRsiParams* AsLarry() {
      return (CLarryRsiParams*)(this.params);
   }
   
   int GetLarrySignal() {
      double arr[];
      // Copy Larry RSI Indicator signal result
      int num = CopyBuffer(larryHandle, 0, 0, 5, arr);
      if(num != 5) {
         PrintFormat("Failed to obtain larry buffer! (%d)", num);
         return 0;
      }
      
      // Return previous (closed) candle data
      return (int)(arr[1]);
   }
   
   int larryHandle;
public:
   CLarryRsi(CLarryRsiParams* strategyParams) : CStrategy(strategyParams) {
      CLarryRsi::Init();
   }

   static CLarryRsi* Build() {
      return new CLarryRsi(new CLarryRsiParams(
         CStrategyParams(
            LarryInput::InpSide,
            LarryInput::InpTakeProfit,
            LarryInput::InpTpCoef,
            LarryInput::InpMagic,
            LarryInput::InpRisk,
            14,
            LarryInput::InpSlCoef,
            "Larry RSI(2)"), 
         LarryInput::InpMaPeriod, 
         LarryInput::InpRsiLower,
         LarryInput::InpRsiUpper
      ));
   }
   virtual bool      CanBuy() override;
   virtual bool      CanSell() override;
   virtual bool      CanCloseBuy() override;
   virtual bool      CanCloseSell() override;

   virtual bool      Init() override;
   virtual bool      Deinit() override;
};
//+------------------------------------------------------------------+

bool CLarryRsi::Init() {
   if(!CStrategy::Init()) {
      return false;
   }
   string sym = Symbol();
   CLarryRsiParams* customParams = AsLarry();
   
   larryHandle = iCustom(sym, PERIOD_CURRENT, "Barotrauma\\LarryRsi", 
      customParams.MaPeriod,
      2,
      customParams.RsiLower,
      customParams.RsiUpper);
      
   return true;
}
bool CLarryRsi::Deinit()  {
   IndicatorRelease(larryHandle);
   return CLarryRsi::Deinit();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLarryRsi::CanBuy() {
   return GetLarrySignal() == 1;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLarryRsi::CanSell() {
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLarryRsi::CanCloseBuy() {
   return GetLarrySignal() == 2;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLarryRsi::CanCloseSell() {
   return false;
}
//+------------------------------------------------------------------+
