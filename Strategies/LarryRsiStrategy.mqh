//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#ifndef CLarryRsi_MQH
#define CLarryRsi_MQH
#include "..\Data\Strategy.mqh"

namespace LarryInput {
input group "Larry - [RSI]";
input bool InpFlag_Larry = true;                      // On/Off
input ulong InpMagic_Larry = 200;                     // Magic
input double InpRisk_Larry = 1.0;                     // Risk
input double InpSlCoef_Larry = 1.5;                   // Stop Loss
input double InpTpCoef_Larry = 1.5;                   // Take Profit
input ETradeSide InpSide_Larry = ETradeSide::Both;    // Trades
input ETakeProfitMethod InpTakeProfit_Larry = ETakeProfitMethod::Manual; // Take Profit Method
input int InpMaPeriod_Larry = 200;                    // Filter Period
input double InpRsiLower_Larry = 25.0;                // Lower RSI
input double InpRsiUpper_Larry = 75.0;                // Upper RSI
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
      if(LarryInput::InpFlag_Larry) {
         return new CLarryRsi(new CLarryRsiParams(
                                 CStrategyParams(
                                    LarryInput::InpSide_Larry,
                                    LarryInput::InpTakeProfit_Larry,
                                    LarryInput::InpTpCoef_Larry,
                                    LarryInput::InpMagic_Larry,
                                    LarryInput::InpRisk_Larry,
                                    14,
                                    LarryInput::InpSlCoef_Larry,
                                    "Larry RSI(2)"),
                                 LarryInput::InpMaPeriod_Larry,
                                 LarryInput::InpRsiLower_Larry,
                                 LarryInput::InpRsiUpper_Larry
                              ));
      } else {
         return NULL;
      }
   }
   virtual bool      CanBuy() override;
   virtual bool      CanSell() override;
   virtual bool      CanCloseBuy() override;
   virtual bool      CanCloseSell() override;

   virtual bool      Init() override;
   virtual bool      Deinit() override;
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLarryRsi::Deinit()  {
   IndicatorRelease(larryHandle);
   return CStrategy::Deinit();
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

#endif // CLarryRsi_MQH
//+------------------------------------------------------------------+
