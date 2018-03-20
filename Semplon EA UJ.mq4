//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define CCI_TO_BOT  1
#define CCI_TO_TOP  2

extern   int      InitialBalance        = 100;
extern   double   InitialLots           = 0.02;
extern   bool     LotsOptimize          = true;
extern   double   CCITimeFrame          = 24;
extern   double   CCIChangeTrend        = 100;
extern   int      MaxOrder              = 3;
extern   int      MinSpaceOrder         = 3;
extern   int      FastMA                = 3;
extern   int      MidMa                 = 4;
extern   int      MidTrend              = 1;
extern   int      SlowMa                = 200;
extern   int      MinSpaceFastAndSlow   = 250;
extern   int      MaxSpaceFastAndSlow   = 1000;
extern   int      StopLoss              = 500;
extern   bool     StopLossOptimize      = false;
extern   int      TakeProfit            = 100;
extern   int      StopTrail             = 1;
extern   int      Slippage              = 3;
extern   int      MaxDailyProfit        = 10;


int  CurrentOrder = 0;
int  cnt,ticket,total;
int  lastOpen   = 0;
int  OpenDay        = 0;
int  ProfitTaget    = 0;

int  StatusCCI = 0;
int  AQ = 0;

double  Top         = 0;
double  Bot         = 1000;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

int optimizeStopLoss(){
    AQ = AccountEquity();
    if(StopLossOptimize && AQ>InitialBalance){
        return NormalizeDouble(AccountEquity()/InitialBalance*StopLoss,0);
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

int init(){

}

void setBotAndTop(int position){
    if(High[position]>Top){
       Top = High[position];
     }

    if(Low[position]<Bot){
       Bot = Low[position];
    }
}

double RealEquity(){
     AQ = AccountEquity();

     for (int i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            AQ+=OrderProfit();
        }
     }
     return AQ;
}

void resetTopAndBot(){
    Top         = 0;
    Bot         = 1000;
    int i;
    for(i=100;i<=0;i--){
       setBotAndTop(i);
    }
}

int start()
 {
    resetTopAndBot();
    AQ = AccountEquity();
    if(OpenDay+86400<iTime(Symbol(),PERIOD_CURRENT,0)){
        ProfitTaget = AQ+(AQ/100*MaxDailyProfit);
        OpenDay = iTime(Symbol(),PERIOD_CURRENT,0);
    }

    if(Bars<50+SlowMa) return;

    int Order = SIGNAL_NONE;
    int Sideway = false;

    double PrevFastMaValue2 = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevMidMaValue2  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevMidTrendMaValue2 = iMA(Symbol(), PERIOD_CURRENT, MidTrend, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevSlowMaValue2 = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 2);

    double PrevFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevMidTrendMaValue = iMA(Symbol(), PERIOD_CURRENT, MidTrend, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 1);

    double CurrentFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrenMidTrendMaValue = iMA(Symbol(), PERIOD_CURRENT, MidTrend, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentDoubleSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa*2, 0, MODE_SMA, PRICE_CLOSE, 0);

    double PrevPrevSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 10);
    double PrevPrevMidMaValue = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 3);

    double PrevVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 5);
    double CurrentVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 0);

    double PrevtCCI = iCCI(Symbol(), 0, CCITimeFrame, PRICE_TYPICAL, 2);
    double CurrentCCI = iCCI(Symbol(), 0, CCITimeFrame, PRICE_TYPICAL, 0);

    if(CurrentCCI>CCIChangeTrend){
        StatusCCI=CCI_TO_BOT;
    }else if(CurrentCCI<-CCIChangeTrend){
        StatusCCI=CCI_TO_TOP;
    }


    double SlowTrend = CurrentSlowMaValue-PrevPrevSlowMaValue;

    double MidTrend = PrevPrevMidMaValue-CurrentMidMaValue;

    double Anomali = MathAbs(PrevVeryFastMaValue-CurrentVeryFastMaValue);

    double Space =  MathAbs(PrevFastMaValue-PrevSlowMaValue)/Point;


       //+------------------------------------------------------------------+
       //| Signal Begin(Entry)                                              |
       //+------------------------------------------------------------------+

       if (
           PrevFastMaValue <= PrevMidMaValue
           &&CurrentFastMaValue > CurrentMidMaValue
           &&CurrentMidMaValue > CurrentSlowMaValue
           &&PrevMidMaValue < CurrentMidMaValue
           &&PrevMidTrendMaValue2 < PrevMidTrendMaValue
           &&PrevMidTrendMaValue < CurrenMidTrendMaValue
           &&Space>MinSpaceFastAndSlow
           &&Space<MaxSpaceFastAndSlow
           &&StatusCCI==CCI_TO_TOP
           &&PrevtCCI<CurrentCCI
//           &&Top>High[0]
           ) Order = SIGNAL_BUY;

       if (
           PrevFastMaValue >= PrevMidMaValue
           &&CurrentFastMaValue < CurrentMidMaValue
           &&CurrentMidMaValue < CurrentSlowMaValue
           &&PrevMidMaValue > CurrentMidMaValue
           &&PrevMidTrendMaValue2 > PrevMidTrendMaValue
           &&PrevMidTrendMaValue > CurrenMidTrendMaValue
           &&Space>MinSpaceFastAndSlow
           &&Space<MaxSpaceFastAndSlow
           &&StatusCCI==CCI_TO_BOT
           &&PrevtCCI>CurrentCCI
//           &&Bot<Low[0]
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
                    }else if(prevStopLost == -1000 && CurrentSlowMaValue<Bid){
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
                    }else if(prevStopLost == 1000 && CurrentSlowMaValue>Ask){
                        sl=NormalizeDouble(Ask+(optimizeStopLoss()*Point),Digits);
                    }

                    if(prevStopLost!=sl && nextStopLost != 1000){
                         OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                    }
                 }

//                 if(OrderProfit() <= -(AccountBalance()/100*30)){
//                      if(OrderType()==OP_BUY && (CurrentFastMaValue-CurrentDoubleSlowMaValue)<0)
//                        OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
//                      if(OrderType()==OP_SELL && (CurrentFastMaValue-CurrentDoubleSlowMaValue)>0)
//                        OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
//                 }

//                 if(OrderProfit() <= -(AccountBalance()/100*20)){
//                      if(OrderType()==OP_BUY)
//                        OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
//                      if(OrderType()==OP_SELL)
//                        OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
//                 }
              }
         }
    }

    if (
        OrdersTotal()<MaxOrder
        && Anomali<(50*Point)
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,MinSpaceOrder)
        && AQ<=ProfitTaget
    ){
        if (Order==SIGNAL_BUY)
        {
           lastOpen = iTime(Symbol(),0,0);
           ticket = OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
        }
        else if (Order==SIGNAL_SELL)
        {
          lastOpen = iTime(Symbol(),0,0);
          ticket = OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
        }
    }

    return(0);
 }
