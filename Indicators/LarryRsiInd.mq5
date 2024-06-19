//+------------------------------------------------------------------+
//|                                                         IndexBot |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

// Indicator buffers
double signalBuffer[];

// Input parameters
input int MaPeriod = 200;     // MA period
input int RsiPeriod = 2;      // RSI period

// Indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 clrDodgerBlue

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   // Indicator buffer mapping
   SetIndexBuffer(0, signalBuffer);

   // Set the indicator label
   IndicatorSetString(INDICATOR_SHORTNAME, "Larry RSI");

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
