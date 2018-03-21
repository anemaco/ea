//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE 0

#define SIGNAL_TOP 1
#define SIGNAL_TO_SELL   2
#define SIGNAL_VALIDATTING_TO_SELL 3
#define SIGNAL_SELL 4

#define SIGNAL_BOT 5
#define SIGNAL_TO_BUY 6
#define SIGNAL_VALIDATTING_TO_BUY 7
#define SIGNAL_BUY 8


extern   int      BbPeriod              = 50;
extern   int      BbDeviation           = 2;
extern   int      InvalidIn             = 15;
extern   int      ValidCounter          = 20;

extern   int      InitialBalance        = 100;
extern   double   InitialLots           = 0.05;
extern   bool     LotsOptimize          = true;
extern   int      StopLoss              = 50;
extern   int      TakeProfit            = 25;
extern   int      StopTrail             = 5;
extern   int      Slippage              = 3;
extern   int      MaxDailyProfit        = 2;
extern   int      MaxDailyLoss          = 5;

//global var
int     lastOpen       = 0;
int     OpenDay        = 0;
double  ProfitTaget    = 0;
double  MaxLoss        = 0;
double  AQ             = 0;

//BB indicator
double  StartBreakoutAt   = 0;
double  StartValidatingAt   = 0;
double  BreakoutCounter     = 0;
int     Order               = 0;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

int init(){

}

int start()
 {
    if(OpenDay+86400<iTime(Symbol(),PERIOD_CURRENT,0)){
        ProfitTaget = AQ+(AQ/100*MaxDailyProfit);
        MaxLoss = AQ-(AQ/100*MaxDailyLoss);
        OpenDay = iTime(Symbol(),PERIOD_CURRENT,0);
    }

    if(Bars<50+BbPeriod) return;
    int Sideway = false;
       //+------------------------------------------------------------------+
       //| BB INDICATOR                                                     |
       //+------------------------------------------------------------------+

       double BbTopLine  = iBands(NULL, 0, BbPeriod, 2, 0, PRICE_CLOSE, MODE_UPPER,0);
       double BbMainLine = iBands(NULL, 0, BbPeriod, 2, 0, PRICE_CLOSE, MODE_MAIN,0);
       double BbBotLine  = iBands(NULL, 0, BbPeriod, 2, 0, PRICE_CLOSE, MODE_LOWER,0);

       //+------------------------------------------------------------------+
       //| Signal Begin(Entry)                                              |
       //+------------------------------------------------------------------+
       if (High[0]>=BbTopLine) Order = SIGNAL_TOP;
       //----
       if (
       Order==SIGNAL_TOP
       &&High[0]<=BbMainLine
       ){
          BreakoutCounter   = 1000;
          StartValidatingAt = iTime(Symbol(),0,0);
          StartBreakoutAt   = BbMainLine;
          Order             = SIGNAL_TO_SELL;
       }
       //----
       if(Order == SIGNAL_TO_SELL && High[0]<BreakoutCounter){
            BreakoutCounter = High[0];
       }
       //----
       if (
           Order == SIGNAL_TO_SELL
           &&StartBreakoutAt-BreakoutCounter>=ValidCounter*Point
           &&High[0]>=BbMainLine
       ) Order = SIGNAL_VALIDATTING_TO_SELL;
       //----
       if (
           Order == SIGNAL_VALIDATTING_TO_SELL
           &&Low[0]<BbMainLine
           &&BbTopLine-BbBotLine >200*Point
       ) Order = SIGNAL_SELL;
       //----
       //---------
       //----
       if (
           Low[0]<=BbBotLine
       ) Order = SIGNAL_BOT;
       //----
       if (
           Order==SIGNAL_BOT
           &&Low[0]>=BbMainLine
       ){
            BreakoutCounter   = -1000;
            StartValidatingAt = iTime(Symbol(),0,0);
            StartBreakoutAt   = BbMainLine;
            Order             = SIGNAL_TO_BUY;
         }
       //----
       if(Order == SIGNAL_TO_BUY && Low[0]>BreakoutCounter){
            BreakoutCounter = Low[0];
       }
       //----
       if (
           Order == SIGNAL_TO_BUY
           &&BreakoutCounter-StartBreakoutAt>=ValidCounter*Point
           &&Low[0]<=BbMainLine
       ) Order = SIGNAL_VALIDATTING_TO_BUY;
       //----
       if (
           Order == SIGNAL_VALIDATTING_TO_BUY
           &&High[0]>BbMainLine
           &&BbTopLine-BbBotLine >200*Point
       ) Order = SIGNAL_BUY;
       //----
       if (
           (Order==SIGNAL_VALIDATTING_TO_SELL || Order==SIGNAL_VALIDATTING_TO_BUY)
           &&StartValidatingAt<iTime(Symbol(),0,InvalidIn)
       ) Order = SIGNAL_NONE;

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
                        sl=NormalizeDouble(Ask+(StopLoss*Point),Digits);
                    }

                    if(prevStopLost!=sl && nextStopLost != 1000){
                         OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                    }
                 }
              }
         }
    }

    if (
        OrdersTotal()<5
        && AQ <= ProfitTaget
        && AQ >= MaxLoss
    ){
        if (Order==SIGNAL_BUY)
        {
          Order=SIGNAL_NONE;
          lastOpen = iTime(Symbol(),0,0);
          OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
        }
        else if (Order==SIGNAL_SELL)
        {
          Order=SIGNAL_NONE;
          lastOpen = iTime(Symbol(),0,0);
          OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
        }
    }

    return(0);
 }
