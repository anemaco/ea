//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define POSITION_HOLD    0
#define POSITION_BUY     1
#define POSITION_SELL   2

extern   int      InitialBalance        = 1000;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 50;
extern   int      SpacePerOrder         = 10;
extern   int      StepPip               = 25;
extern   int      FastMA                = 3;
extern   int      SlowMa                = 800;
extern   int      VerySlowMa            = 1600;
extern   int      MinSpaceFastAndVerySlow   = 0;
extern   int      StopLoss              = 10000;
extern   int      TakeProfit            = 50;
extern   int      StopTrail             = 5;
extern   int      Slippage              = 3;

int     lastOpen           = 0;
int     Position           = 0;
double  HLposition         = 0;
double  RHLposition         = 0;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

int init(){

}

void closeAll(){
   while(OrdersTotal()>=1){
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
}

int start()
 {
    if(Bars<50+VerySlowMa) return;

    int Order = SIGNAL_NONE;

    double FastMAValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double SlowMAValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double VerySlowMAValue = iMA(Symbol(), PERIOD_CURRENT, VerySlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);

    double PrevFastMAValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevVerySlowMAValue = iMA(Symbol(), PERIOD_CURRENT, VerySlowMa, 0, MODE_SMA, PRICE_CLOSE, 1);

    double Space =  MathAbs(FastMAValue-VerySlowMAValue)/Point;

//    if(
//        (PrevFastMAValue <= PrevVerySlowMAValue
//         &&FastMAValue > VerySlowMAValue)
//         ||
//        (PrevFastMAValue <= PrevVerySlowMAValue
//         &&FastMAValue > VerySlowMAValue)
//    ){
//        closeAll();
//    }

    //tentukan posisi
      if(Bid>FastMAValue && Bid>SlowMAValue && Bid>VerySlowMAValue){
          Position=POSITION_BUY;
          if(Position!=POSITION_BUY){
              HLposition = Bid;
              RHLposition=Bid;
          }else if(HLposition<Bid){
              HLposition = Bid;
          }

          if(RHLposition<Bid){
              RHLposition=Bid;
          }
      }else if(Bid<FastMAValue && Bid<SlowMAValue && Bid<VerySlowMAValue){
          Position=POSITION_SELL;
          if(Position!=POSITION_SELL){
             HLposition = Bid;
             RHLposition=Bid;
          }else if(HLposition>Bid){
              HLposition = Bid;
          }

          if(RHLposition>Bid){
              RHLposition=Bid;
          }

      }else{
          Position=POSITION_HOLD;
          HLposition = 0;
      }

    //tentukan signal
    if(Position==POSITION_BUY  && Space<MinSpaceFastAndVerySlow && RHLposition==Bid){
       if(HLposition>Bid+StepPip*Point){
           Order = SIGNAL_BUY;
       }
    }

    if(Position==POSITION_SELL  && Space<MinSpaceFastAndVerySlow){
       if(HLposition<Bid-StepPip*Point){
           Order = SIGNAL_SELL;
       }
    }

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
        OrdersTotal()<MaxOrder
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder)
    ){
        if (Order==SIGNAL_BUY)
        {
              lastOpen = iTime(Symbol(),0,0);
                 HLposition = Bid;
           OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
        }
        else if (Order==SIGNAL_SELL)
        {
          lastOpen = iTime(Symbol(),0,0);
             HLposition = Bid;
          OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
        }
    }

    return(0);
 }
