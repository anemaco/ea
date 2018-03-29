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
#define POSITION_HOLD    0

extern   bool     Otomation             = false;
extern   int      InitialBalance        = 1000;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 50;
extern   int      SpacePerOrder         = 0;
extern   int      StepPip               = 25;
extern   int      FastMA                = 3;
extern   int      SlowMa                = 50;
extern   int      VerySlowMa            = 100;
extern   int      StopLossPerOrder      = 1000;
extern   int      TakeProfit            = 50;
extern   int      StopTrail             = 5;
extern   int      Slippage              = 3;
extern   int      MaxDailyStopLoss      = 50;
extern   int      MaxDailyProfit        = 5;

int     lastOpen           = 0;
int     Position           = 0;
double  HLposition         = 0;
double  AB                 = 0;
double  DailyProfitTaget   = 0;
double  DailyStopLoss      = 0;
int     day                = 0;
int     i                  = 0;

bool    ReachProfit       = true;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

void closeAll(){
   while(OrdersTotal()>=1){
     for (i=0; i<OrdersTotal(); i++){
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

int init(){

}

int start(){

   //ChHECK FORCE STOP LOSS
   if(!Otomation && ReachProfit == false){
     for (i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(Position==POSITION_SELL && OrderType()==OP_BUY){
               closeAll();
               ReachProfit = true;
               Position=POSITION_HOLD;
            }

            if(Position==POSITION_BUY && OrderType()==OP_SELL){
               closeAll();
               ReachProfit = true;
               Position=POSITION_HOLD;
            }
         }
      }
   }

   if(ReachProfit == true && OrdersTotal()==1){
       OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
       ReachProfit = false;
       if(OrderType()==OP_BUY){
            Position=POSITION_BUY;
            HLposition = Bid;
       }

       if(OrderType()==OP_SELL){
            Position=POSITION_SELL;
            HLposition = Bid;
       }

       AB = AccountBalance();
       DailyProfitTaget = AB+(AB/100*MaxDailyProfit);
       DailyStopLoss    = AB-(AB/100*MaxDailyStopLoss);
   }

    //check change day
    if(day<floor(iTime(Symbol(),PERIOD_CURRENT,0)/86400) &&  ReachProfit == true){
        day = floor(iTime(Symbol(),PERIOD_CURRENT,0)/86400);

        AB = AccountBalance();
        DailyProfitTaget = AB+(AB/100*MaxDailyProfit);
        DailyStopLoss    = AB-(AB/100*MaxDailyStopLoss);

        if(Otomation){
           ReachProfit = false;
        }
    }

    if(!Otomation){
        if(Bars<50+VerySlowMa) return;
    }


    if(ReachProfit){
        closeAll();
        return;
    }

    //TAKE PROFIT
    if(AccountEquity()>=DailyProfitTaget){
        closeAll();
        ReachProfit = true;
        Position=POSITION_HOLD;
    }

    //STOP LOSS
    if(AccountEquity()<=DailyStopLoss){
       closeAll();
       ReachProfit = true;
       Position=POSITION_HOLD;
    }

    int Order = SIGNAL_NONE;

    double FastMAValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double SlowMAValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double VerySlowMAValue = iMA(Symbol(), PERIOD_CURRENT, VerySlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);

    if(Otomation){
    //tentukan posisi
      if(Bid>FastMAValue && Bid>SlowMAValue && Bid>VerySlowMAValue){
          Position=POSITION_BUY;
          if(Position!=POSITION_BUY){
              HLposition = Bid;
          }else if(HLposition<Bid){
              HLposition = Bid;
          }
      }else if(Bid<FastMAValue && Bid<SlowMAValue && Bid<VerySlowMAValue){
          Position=POSITION_SELL;
          if(Position!=POSITION_SELL){
             HLposition = Bid;
          }else if(HLposition>Bid){
              HLposition = Bid;
          }
      }else{
          Position=POSITION_HOLD;
          HLposition = 0;
      }
    }

    //tentukan signal
    if(HLposition>Bid+StepPip*Point || HLposition<Bid-StepPip*Point){
        if(Position==POSITION_BUY){
            Order = SIGNAL_BUY;
        }

        if(Position==POSITION_SELL){
            Order = SIGNAL_SELL;
        }
    }



    if(OrdersTotal()>=1){
        double sl=0;
        double nextStopLost=0;
        double prevStopLost=0;
        for (i=0; i<OrdersTotal(); i++){
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
                        sl=NormalizeDouble(Bid-(StopLossPerOrder*Point),Digits);
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
                       sl=NormalizeDouble(Ask+(StopLossPerOrder*Point),Digits);
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
       && lastOpen<=iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder)
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