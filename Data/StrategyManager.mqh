//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#ifndef CStrategyManager_MQH
#define CStrategyManager_MQH

#include <Object.mqh>
#include <Generic\ArrayList.mqh>
#include "Strategy.mqh"

class CStrategyManager : public CObject {
protected:
   CArrayList<CStrategy*> strategies;
public:
   CStrategyManager() {

   }
   ~CStrategyManager() {
      FreeStrategies();
   }
   void FreeStrategies();
   void AddStrategy(CStrategy* strat);
   void Tick(MqlTick& tick);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyManager::FreeStrategies() {
   int n = strategies.Count();
   for(int i = 0; i < n; ++i) {
      CStrategy* strat;
      if(strategies.TryGetValue(i, strat)) {
         delete strat;
      }
      strategies.TrySetValue(i, NULL);
   }
   strategies.Clear();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyManager::AddStrategy(CStrategy* strat) {
   if(strat != NULL) {
      strategies.Add(strat);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyManager::Tick(MqlTick& tick) {
   int n = strategies.Count();
   for(int i = 0; i < n; ++i) {
      CStrategy* strat;
      if(strategies.TryGetValue(i, strat)) {
         strat.Tick(tick);
      }
   }
}

#endif // CStrategyManager_MQH
//+------------------------------------------------------------------+
