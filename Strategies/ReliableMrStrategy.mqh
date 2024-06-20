//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#ifndef CReliableMR_MQH
#define CReliableMR_MQH
#include "..\Data\Strategy.mqh"

namespace ReliableInput {
input group "Reliable - [MR]";
input bool InpFlag_Re = true;                      // On/Off
input ulong InpMagic_Re = 200;                     // Magic
input double InpRisk_Re = 1.0;                     // Risk
input double InpSlCoef_Re = 1.5;                   // Stop Loss
input double InpTpCoef_Re = 1.5;                   // Take Profit
input ETradeSide InpSide_Re = ETradeSide::Both;    // Trades
input ETakeProfitMethod InpTakeProfit_Re = ETakeProfitMethod::Manual; // Take Profit Method
input int InpMaPeriod_Re = 20;                    // Fast MA Period
input int InpFilterMaPeriod_Re = 200;             // Filter MA Period
input double InpPercent_Re = 0.2;             // Candle Percent
}

class CReliableMrParams : public CStrategyParams {
public:
   int MaPeriod;
   int FilterMaPeriod;
   double Percent;
public:
   CReliableMrParams(CStrategyParams& basic,
                   int maPeriod, int filterMaPeriod, double percent)
      : CStrategyParams(basic),
        MaPeriod(maPeriod), FilterMaPeriod(filterMaPeriod), Percent(percent) {
   }
};

class CReliableMR : public CStrategy {

public:
   CReliableMrParams* AsReliableMr() {
      return (CReliableMrParams*)(this.params);
   }
   
   int reliableHandle;
   int GetMrSignal() {
      double arr[];
      // Copy MR Indicator signal result
      int num = CopyBuffer(reliableHandle, 0, 0, 5, arr);
      if(num != 5) {
         PrintFormat("Failed to obtain ReliableMR buffer! (%d)", num);
         return 0;
      }

      // Return previous (closed) candle data
      return (int)(arr[1]);
   }
public:
   CReliableMR(CReliableMrParams* strategyParams) : CStrategy(strategyParams) {
      CReliableMR::Init();
   }
   
    static CReliableMR* Build() {
      if(ReliableInput::InpFlag_Re) {
         return new CReliableMR(new CReliableMrParams(
                                 CStrategyParams(
                                    ReliableInput::InpSide_Re,
                                    ReliableInput::InpTakeProfit_Re,
                                    ReliableInput::InpTpCoef_Re,
                                    ReliableInput::InpMagic_Re,
                                    ReliableInput::InpRisk_Re,
                                    14,
                                    ReliableInput::InpSlCoef_Re,
                                    "Larry RSI(2)"),
                                 ReliableInput::InpMaPeriod_Re,
                                 ReliableInput::InpFilterMaPeriod_Re,
                                 ReliableInput::InpPercent_Re
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
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::Init() {
   if(!CStrategy::Init()) {
      return false;
   }
   string sym = Symbol();
   CReliableMrParams* customParams = AsReliableMr();

   reliableHandle = iCustom(sym, PERIOD_CURRENT, "Barotrauma\\ReliableMR",
      customParams.FilterMaPeriod,
      customParams.MaPeriod,
      customParams.Percent);

   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::Deinit()  {
   IndicatorRelease(reliableHandle);
   return CStrategy::Deinit();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::CanBuy() {
   return GetMrSignal() == 1;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::CanSell() {
   return GetMrSignal() == 3;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::CanCloseBuy() {
   return GetMrSignal() == 2;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CReliableMR::CanCloseSell() {
   return GetMrSignal() == 4;
}
//+------------------------------------------------------------------+

#endif // CReliableMR_MQH
//+------------------------------------------------------------------+
