//+------------------------------------------------------------------+
//|                                                     IndexBot.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include "Data\StrategyManager.mqh"
#include "Data\Strategy.mqh"
#include "Strategies\LarryRsiStrategy.mqh"

CStrategyManager* manager;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
//---
   manager = new CStrategyManager();
   InitStrategies();
//---
   return(INIT_SUCCEEDED);
}

void InitStrategies() {
   manager.AddStrategy(CLarryRsi::Build());
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   delete manager;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

   MqlTick lastTick;
   if(SymbolInfoTick(Symbol(), lastTick)) {
      manager.Tick(lastTick);
   }
   
}
//+------------------------------------------------------------------+
