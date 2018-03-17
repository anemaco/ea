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
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   double   CCITimeFrame          = 24;
//extern   double   CCIControl        = 100;
extern   double   CCIChangeTrend        = 100;
extern   int      MaxOrder              = 5;
extern   int      MinSpaceOrder         = 3;
extern   int      FastMA                = 3;
extern   int      MidMa                 = 4;
extern   int      SlowMa                = 200;
extern   int      MinSpaceFastAndSlow   = 250;
extern   int      MaxSpaceFastAndSlow   = 1000;
extern   int      StopLoss              = 500;
extern   bool     StopLossOptimize      = false;
extern   int      TakeProfit            = 100;
extern   int      StopTrail             = 1;
extern   int      Slippage              = 3;


int  CurrentOrder = 0;
int  cnt,ticket,total;
int  lastOpen = 0;

int  StatusCCI = 0;
int  AQ = 0;

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

int start()
 {
    if(Bars<50+SlowMa) return;

    int Order = SIGNAL_NONE;
    int Sideway = false;

    double PrevFastMaValue2 = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevMidMaValue2  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 2);
    double PrevSlowMaValue2 = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 2);

    double PrevFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 1);

    double CurrentFastMaValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentMidMaValue  = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);

    double PrevPrevSlowMaValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 10);
    double PrevPrevMidMaValue = iMA(Symbol(), PERIOD_CURRENT, MidMa, 0, MODE_SMA, PRICE_CLOSE, 3);

    double PrevVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 5);
    double CurrentVeryFastMaValue = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 0);

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
           &&Space>MinSpaceFastAndSlow
           &&Space<MaxSpaceFastAndSlow
           &&StatusCCI==CCI_TO_TOP
           ) Order = SIGNAL_BUY;

       if (
           PrevFastMaValue >= PrevMidMaValue
           &&CurrentFastMaValue < CurrentMidMaValue
           &&CurrentMidMaValue < CurrentSlowMaValue
           &&PrevMidMaValue > CurrentMidMaValue
           &&Space>MinSpaceFastAndSlow
           &&Space<MaxSpaceFastAndSlow
           &&StatusCCI==CCI_TO_BOT
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
                        }else{
                          sl=NormalizeDouble(OrderStopLoss(),Digits);
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
                         }else{
                           sl=NormalizeDouble(OrderStopLoss(),Digits);
                         }
                    }else if(prevStopLost == 1000 && CurrentSlowMaValue>Ask){
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
        && Anomali<(50*Point)
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,MinSpaceOrder)
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
