//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

extern   int      InitialBalance        = 100;
extern   double   InitialLots           = 0.10;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 10;
extern   int      MinSpaceOrder         = 10;
extern   int      FastMA                = 4;
extern   int      MidMa                 = 5;
extern   int      StopLoss              = 20;
extern   bool     StopLossOptimize      = false;
extern   int      TakeProfit            = 10;
extern   int      StopTrail             = 3;
extern   int      Slippage              = 3;
extern   int      MaxDailyProfit = 10;


int  lastOpen       = 0;
int  OpenDay        = 0;
int  ProfitTaget    = 0;
int  Ticket    = 0;

int  AQ = 0;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountBalance()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

int optimizeStopLoss(){
    AQ = AccountBalance();
    if(StopLossOptimize && AQ>InitialBalance){
        return NormalizeDouble(AccountBalance()/InitialBalance*StopLoss,0);
    }
    return StopLoss;
}

void closeAll(){
   for (int i=0; i<OrdersTotal(); i++){
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType()==OP_BUY)
             OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
         if(OrderType()==OP_SELL)
             OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
      }
   }
}

double RealEquity(){
     AQ = AccountBalance();

     for (int i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            AQ+=OrderProfit();
        }
     }
     return AQ;
}

int start()
 {
    AQ = AccountBalance();
    if(OpenDay+86400<iTime(Symbol(),PERIOD_CURRENT,0)){
        ProfitTaget = AQ+(AQ/100*MaxDailyProfit);
        OpenDay = iTime(Symbol(),PERIOD_CURRENT,0);
    }

    if(Bars<50+MidMa) return;

    int Order = SIGNAL_NONE;
    int Sideway = false;

    double PrevFastMaValue2 = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevMidMaValue2  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 2);

    double PrevFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 1);

    double CurrentFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 0);

    double PrevPrevMidMaValue = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 3);

    double PrevVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 5);
    double CurrentVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 0);


       //+------------------------------------------------------------------+
       //| Signal Begin(Entry)                                              |
       //+------------------------------------------------------------------+

       if (
           PrevFastMaValue >= PrevMidMaValue
           &&CurrentFastMaValue < CurrentMidMaValue
           ) Order = SIGNAL_BUY;

       if (
           PrevFastMaValue <= PrevMidMaValue
           &&CurrentFastMaValue > CurrentMidMaValue
           ) Order = SIGNAL_SELL;


       if(OrdersTotal()>=1){
         double sl=0;
         double nextStopLost=0;
         double prevStopLost=0;
         for (int i=0; i<OrdersTotal(); i++){
              if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
              {
                 sl=OrderStopLoss();
                 if(OrderType()==OP_BUY){
                    prevStopLost = OrderStopLoss()==0?(-1000):OrderStopLoss();
                    if(OrderProfit()> TakeProfit*OrderLots()){
                     nextStopLost = Bid-((TakeProfit+StopTrail)*InitialLots*Point);
                        if(nextStopLost > prevStopLost){
                          sl=NormalizeDouble(nextStopLost, Digits);
                        }
                    }else if(prevStopLost == -1000){
                         sl=NormalizeDouble(Bid-(StopLoss*Point),Digits);
                    }

                    if(prevStopLost!=sl && nextStopLost != -1000){
                         OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                    }
                 }

                 if(OrderType()==OP_SELL){
                    prevStopLost = OrderStopLoss()==0?1000:OrderStopLoss();
                    if(OrderProfit()> TakeProfit*OrderLots()){
                         nextStopLost = Ask+((TakeProfit+StopTrail)*InitialLots*Point);
                         if(nextStopLost<prevStopLost){
                           sl=NormalizeDouble(nextStopLost,Digits);
                         }
                    }else if(prevStopLost == 1000){
                        sl=NormalizeDouble(Ask+(optimizeStopLoss()*Point),Digits);
                    }

                    if(prevStopLost!=sl && nextStopLost != 1000){
                         OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                    }
                 }
              }
         }
    }

    if (
        OrdersTotal()<MaxOrder
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,MinSpaceOrder)
        && AQ<=ProfitTaget
    ){
        if (Order==SIGNAL_BUY)
        {
           lastOpen = iTime(Symbol(),0,0);
           Ticket = OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
        }
        else if (Order==SIGNAL_SELL)
        {
          lastOpen = iTime(Symbol(),0,0);
          Ticket = OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
        }
    }

    return(0);
 }
