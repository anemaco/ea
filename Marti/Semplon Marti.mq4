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

extern   int      InitialBalance        = 500;
extern   double   InitialLots           = 0.01;
extern   int      SaveEquityPercent     = 30;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 2;
extern   int      SpacePerOrder         = 1;
extern   int      distance              = 250;
extern   bool     OpenOnStepUp          = true;
extern   bool     OpenOnStepDown        = true;
extern   bool     HoldLowestOrTopest    = false;
extern   bool     TradeInFriday         = false;
extern   bool     TradeInMonday         = true;
extern   int      LowOrTopSpread        = 50;
extern   string   xxxxxxxxxx            = "Marti Setting";
extern   double   MartiMultiple         = 5;
extern   int      MartiInitialTakeProfit= 100;
extern   string   xxxxxxxxxxxx          = "dalam harga";
extern   double   BuyTakeProfit         = 1000;
extern   double   BuyStopLoss           = 0;
extern   string   xxxxxxxxxxx           = "-------------";
extern   double   SellTakeProfit        = 0;
extern   double   SellStopLoss          = 1000;
extern   string   xxxxxxxxxxxxx         = "dalam point";
extern   int      StopLossPerOrder      = 500;
extern   int      InitialTakeProfit     = 500;
extern   int      StartStopTrail        = 500;
extern   int      StopTrail             = 30;
extern   int      Slippage              = 3;
extern   string   xxxxxxxxxxxxxx        = "dalam persen";
extern   int      MaxDailyStopLoss      = 100;
extern   int      MaxDailyProfit        = 10000;
extern   int      initial               = 1;

bool     Otomation         = false;
int      FastMA            = 3;
int      SlowMa            = 50;
int      VerySlowMa        = 100;


int     lastOpen           = 0;
int     Position           = 0;
double  HLposition         = 0;
double  AB                 = 0;
double  ABToday            = 0;
double  DailyProfitTaget   = 0;
double  DailyStopLoss      = 0;
int     day                = 0;
int     i                  = 0;
double  lowestOrTopest     = 0;
double  point              = 0;
double  today              = 0;

double pnt;
double dig;

bool    ReachProfit       = true;

double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble((AccountEquity()-AccountEquity()*SaveEquityPercent/100)/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
}

int totalOpenOrder(){
    int totalOpen = 0;

    for (i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
          if(Symbol()==OrderSymbol()){
            if(OrderType()==OP_BUY || OrderType()==OP_SELL)
              totalOpen++;
          }
       }
    }

   return totalOpen;
}

void closeAll(){
   while(totalOpenOrder()>=1){
     for (i=0; i<OrdersTotal(); i++){
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(Symbol()==OrderSymbol()){
                if(OrderType()==OP_BUY)
                    OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
                else if(OrderType()==OP_SELL)
                    OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
            }
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
            if(Symbol()==OrderSymbol()){
              if(typeOrder==OP_SELL && OrderType()==OP_BUY)
                  OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
              if(typeOrder==OP_BUY && OrderType()==OP_SELL)
                  OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
           }
         }
      }
   }
}

bool allowDistanceToOpen(int buyOrSell){
    if(!(MathAbs(HLposition-Bid)>distance*pnt)) return false;

    for (i=0; i<OrdersTotal(); i++){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(Symbol()==OrderSymbol()){
                if(buyOrSell==POSITION_SELL){
                    if(MathAbs(OrderOpenPrice()-Bid)<distance*pnt) return false;
                }else if(buyOrSell==POSITION_BUY){
                    if(MathAbs(OrderOpenPrice()-Ask)<distance*pnt) return false;
                }
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
                   if(Symbol()==OrderSymbol()){
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
}

int init(){

   pnt = Point;
   dig = MarketInfo(Symbol(),MODE_DIGITS);

   if (dig == 2 || dig == 4) {
     pnt /= 10;
   }

  AB = AccountBalance();

  if (initial==1)
       {
          Position=POSITION_BUY;
          HLposition = Bid;
          ReachProfit = false;
          lastOpen = iTime(Symbol(),0,0);
          HLposition = Bid;
          OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
       }
 else{
         Position=POSITION_BUY;
         HLposition = Bid;
         ReachProfit = false;
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
           if(Symbol()==OrderSymbol()){
             if(OrderType()==OP_BUYLIMIT && OrderLots()==1.23){
                closeAll();
                ReachProfit = true;
                Position=POSITION_HOLD;
                lowestOrTopest     = 0;
             }
           }
         }
      }
   }

    //TAKE PROFIT
    if(AccountEquity()>=AB+(AB/100*MaxDailyProfit)){
        closeAll();
        ReachProfit = true;
        Position=POSITION_HOLD;
        lowestOrTopest     = 0;
    }

    //BUY REACH PROFIT BY PRICE
    if(Position == POSITION_BUY && Bid >= BuyTakeProfit){
       closeAll();
       ReachProfit = true;
       Position = POSITION_HOLD;
       lowestOrTopest = 0;
    }

    //SELL REACH PROFIT BY PRICE
    if(Position == POSITION_SELL && Ask <= SellTakeProfit){
       closeAll();
       ReachProfit = true;
       Position = POSITION_HOLD;
       lowestOrTopest = 0;
    }

    //STOP LOSS
    if(AccountEquity()<=ABToday-(ABToday/100*MaxDailyStopLoss)){
       ReachProfit = true;
       lowestOrTopest     = 0;
    }

    //BUY REACH STOP LOSS BY PRICE
    if(Position == POSITION_BUY && Bid < BuyStopLoss){
       closeAll();
       ReachProfit = true;
       Position = POSITION_HOLD;
       lowestOrTopest = 0;
    }

    //SELL REACH STOP LOSS  BY PRICE
    if(Position == POSITION_SELL && Ask > SellStopLoss){
       closeAll();
       ReachProfit = true;
       Position = POSITION_HOLD;
       lowestOrTopest = 0;
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
    }

    //tentukan signal
    if(Position==POSITION_BUY && allowDistanceToOpen(POSITION_BUY)){
        Order = SIGNAL_BUY;
    }

    if(Position==POSITION_SELL && allowDistanceToOpen(POSITION_SELL)){
        Order = SIGNAL_SELL;
    }

    if((TimeDayOfWeek(TimeCurrent())==1 && !TradeInMonday) || (TimeDayOfWeek(TimeCurrent())==5 && !TradeInFriday)){
        Order = SIGNAL_NONE;
    }

    if(TimeDayOfWeek(TimeCurrent())!=today){
        today     = TimeDayOfWeek(TimeCurrent());
        ABToday   = AccountBalance();
    }

    if(OrdersTotal()>=1){
        double sl=0;
        double nextStopLost=0;
        double prevStopLost=0;

        int tp = StartStopTrail;

        if (dig == 2 || dig == 4) {
          tp = ceil(StartStopTrail/10);
        }

        for (i=0; i<OrdersTotal(); i++){
             if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
             {
                if(Symbol()==OrderSymbol()){
                    sl=OrderStopLoss();
                    if(OrderType()==OP_BUY){

                       prevStopLost = OrderStopLoss()==0?(-1000):OrderStopLoss();
                       if(OrderProfit()> tp*OrderLots()){
                        nextStopLost = Bid-StopTrail*pnt;
                           if(nextStopLost > prevStopLost){
                             sl=NormalizeDouble(nextStopLost, Digits);
                           }
                       }else if(prevStopLost == -1000){
                            sl=NormalizeDouble(OrderOpenPrice()-(StopLossPerOrder*pnt),Digits);

                            if(Bid<=sl){
                                OrderSend(Symbol(),OP_SELL, NormalizeDouble(OrderLots()*MartiMultiple,2), Bid, Slippage, 0, Bid-MartiInitialTakeProfit*pnt, "JUAL", 10, 0, Red);
                                OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
                                Position=POSITION_SELL;
                            }
                            continue;
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
                           sl=NormalizeDouble(OrderOpenPrice()+(StopLossPerOrder*pnt),Digits);

                           if(Ask>=sl){
                               OrderSend(Symbol(),OP_BUY, NormalizeDouble(OrderLots()*MartiMultiple,2), Ask, Slippage, 0, Ask+MartiInitialTakeProfit*pnt, "BELI", 10, 0, Green);
                               OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
                               Position=POSITION_BUY;
                           }
                           continue;
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
   }

    if(ReachProfit){
        return;
    }

   if (
       totalOpenOrder()<MaxOrder
       && lastOpen<=iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder)
   ){
       if (Order==SIGNAL_BUY)
       {
          lastOpen = iTime(Symbol(),0,0);
          HLposition = Bid;
          OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, 0, Ask+InitialTakeProfit*pnt, "BELI", 10, 0, Green);
       }
       else if (Order==SIGNAL_SELL)
       {
         lastOpen = iTime(Symbol(),0,0);
         HLposition = Bid;
         OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, 0, Bid-InitialTakeProfit*pnt, "JUAL", 10, 0, Red);
       }
   }

    return(0);
}
