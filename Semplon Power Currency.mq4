//+------------------------------------------------------------------+
//| Power Curency EA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define POSITION_HOLD    0
#define POSITION_BUY     1
#define POSITION_SELL   2
#define POSITION_HOLD    0

extern   int      InitialBalance        = 500;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      StopLoss              = 300;
extern   int      TakeProfit            = 100;
extern   int      StopTrail             = 30;
extern   int      Slippage              = 3;
extern   int      MaxDailyProfit        = 5;


double  DailyProfitTaget   = 0;
int     day                = 0;
int     i,j,k,l            = 0;
double  point              = 0;

double pnt;
double dig;

bool    ReachProfit       = true;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

void closeAll(){
   while(totalOpenOrder()>=1){
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

void closeOpositOrder(int typeOrder){
   int r = 0;
    for (r=0; r<=3; r++){
     for (i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(typeOrder==OP_SELL && OrderType()==OP_BUY)
                OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
            if(typeOrder==OP_BUY && OrderType()==OP_SELL)
                OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
         }
      }
   }
}

bool allowDistanceToOpen(int buyOrSell){
    if(!(MathAbs(HLposition-Bid)>distance*pnt)) return false;

    for (i=0; i<OrdersTotal(); i++){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(buyOrSell==POSITION_SELL){
                if(MathAbs(OrderOpenPrice()-Bid)<distance*pnt) return false;
            }else if(buyOrSell==POSITION_BUY){
                if(MathAbs(OrderOpenPrice()-Ask)<distance*pnt) return false;
            }
        }
     }

     return true;
}

bool setTopestAndLowest(){
      lowestOrTopest=0;
      if(OrdersTotal()>=1){
          for (i=0; i<OrdersTotal(); i++){
               if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
               {
                  if(OrderType()==OP_BUY && Position==POSITION_BUY){
                     if((lowestOrTopest==0 || lowestOrTopest>OrderOpenPrice()+LowOrTopSpread*pnt)){
                          lowestOrTopest = OrderOpenPrice()+LowOrTopSpread*pnt;
                     }
                  }else if(OrderType()==OP_SELL && Position==POSITION_SELL){
                     if((lowestOrTopest==0 || lowestOrTopest<OrderOpenPrice()-LowOrTopSpread*pnt)){
                          lowestOrTopest = OrderOpenPrice()-LowOrTopSpread*pnt;
                     }
                  }
               }
          }
      }
}

int init(){

   pnt = Point;
   dig = MarketInfo(Symbol(),MODE_DIGITS);

   if (dig == 2 || dig == 4) {
     pnt /= 10;
   }

  if (initial==1)
       {
          lastOpen = iTime(Symbol(),0,0);
          HLposition = Bid;
          OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
       }
 else if (initial==2)
       {
         lastOpen = iTime(Symbol(),0,0);
         HLposition = Bid;
         OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
       }
}

int start(){

   //Update HL Position
   if(HLposition==0){
       HLposition=Bid;
   }

   if(OpenOnStepUp && !OpenOnStepDown){
        if(HLposition>Bid){
            HLposition=Bid;
        }
   }

   if(!OpenOnStepUp && OpenOnStepDown){
        if(HLposition<Bid){
            HLposition=Bid;
        }
   }

   setTopestAndLowest();

   //ChHECK FORCE STOP LOSS
   if(!Otomation && ReachProfit == false){
     for (i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType()==OP_BUYLIMIT && OrderLots()==11){
               closeAll();
               ReachProfit = true;
               Position=POSITION_HOLD;
               lowestOrTopest     = 0;
            }
         }
      }
   }

   //manual open position
   if(ReachProfit == true && totalOpenOrder()==1){
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
        lowestOrTopest     = 0;
    }

    //STOP LOSS
    if(AccountEquity()<=DailyStopLoss){
       closeAll();
       ReachProfit = true;
       Position=POSITION_HOLD;
       lowestOrTopest     = 0;
    }

    int Order = SIGNAL_NONE;

    double FastMAValue = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double SlowMAValue = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);
    double VerySlowMAValue = iMA(Symbol(), PERIOD_CURRENT, VerySlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);

    if(Otomation){
    //tentukan posisi
      if(
      Bid>FastMAValue && Bid>SlowMAValue && Bid>VerySlowMAValue
      &&FastMAValue>SlowMAValue && SlowMAValue>VerySlowMAValue
      ){
          Position=POSITION_BUY;
          if(Position!=POSITION_BUY){
              HLposition = Bid;
          }else if(HLposition<Bid){
              HLposition = Bid;
          }
      }else if(
      Bid<FastMAValue && Bid<SlowMAValue && Bid<VerySlowMAValue
      &&FastMAValue<SlowMAValue && SlowMAValue<VerySlowMAValue
      ){
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

       //close oposit order

    }

    //tentukan signal
    if(Position==POSITION_BUY && allowDistanceToOpen(POSITION_BUY)){
        Order = SIGNAL_BUY;
    }

    if(Position==POSITION_SELL && allowDistanceToOpen(POSITION_SELL)){
        Order = SIGNAL_SELL;
    }



    if(OrdersTotal()>=1){
        double sl=0;
        double nextStopLost=0;
        double prevStopLost=0;

        int tp = TakeProfit;

        if (dig == 2 || dig == 4) {
          tp = ceil(TakeProfit/10);
        }

        for (i=0; i<OrdersTotal(); i++){
             if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
             {
                sl=OrderStopLoss();
                if(OrderType()==OP_BUY){

                   prevStopLost = OrderStopLoss()==0?(-1000):OrderStopLoss();
                   if(OrderProfit()> tp*OrderLots()){
                    nextStopLost = Bid-StopTrail*pnt;
                       if(nextStopLost > prevStopLost){
                         sl=NormalizeDouble(nextStopLost, Digits);
                       }
                   }else if(prevStopLost == -1000){
                        sl=NormalizeDouble(Bid-(StopLossPerOrder*pnt),Digits);
                   }

                   if(lowestOrTopest>OrderOpenPrice() && HoldLowestOrTopest && !Otomation){
                        continue;
                   }

                   if(prevStopLost!=sl && nextStopLost != -1000){
                        OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                   }
                }

                if(OrderType()==OP_SELL){

                   prevStopLost = OrderStopLoss()==0?1000:OrderStopLoss();
                   if(OrderProfit()> tp*OrderLots()){
                        nextStopLost = Ask+StopTrail*pnt;
                        if(nextStopLost<prevStopLost){
                          sl=NormalizeDouble(nextStopLost,Digits);
                        }
                   }else if(prevStopLost == 1000){
                       sl=NormalizeDouble(Ask+(StopLossPerOrder*pnt),Digits);
                   }

                   if(lowestOrTopest<OrderOpenPrice() && HoldLowestOrTopest && !Otomation){
                        continue;
                   }

                   if(prevStopLost!=sl && nextStopLost != 1000){
                        OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                   }
                }
             }
        }
   }

   if (
       totalOpenOrder()<MaxOrder
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
