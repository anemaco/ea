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
extern   string   XXXXXX                ="SETTING FOR H4";
extern   string   XXXXXXX               ="///MA SETTING////";
extern   int      ma_period             = 21;
extern   ENUM_MA_METHOD   ma_method     = 1;
extern   int      space_with_ma         = 500;

extern   string   xxxxxxx               ="////////////////";
extern   int      InitialBalance        = 100;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 100;
extern   int      SpacePerOrder         = 0;
extern   int      distance              = 10;
extern   bool     OpenOnStepUp          = true;
extern   bool     OpenOnStepDown        = true;
extern   bool     HoldLowestOrTopest    = false;
extern   int      LowOrTopSpread        = 50;
extern   int      StopLossPerOrder      = 500;
extern   int      TakeProfit            = 200;
extern   int      StopTrail             = 30;
extern   int      Slippage              = 3;
extern   int      MaxDailyStopLoss      = 100;
extern   int      MaxDailyProfit        = 1000;
extern   int      initial               = 0;

bool     Otomation         = false;
int      FastMA            = 3;
int      SlowMa            = 50;
int      VerySlowMa        = 100;

double     space_buy          = 0;
double     space_sell         = 0;


int     lastOpen           = 0;
int     Position           = 0;
double  HLposition         = 0;
double  AB                 = 0;
double  DailyProfitTaget   = 0;
double  DailyStopLoss      = 0;
int     day                = 0;
int     i                  = 0;
double  lowestOrTopest     = 0;
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
                else
                    OrderDelete(OrderTicket(), White);
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
           if(Symbol()==OrderSymbol()){
             if(OrderType()==OP_BUYLIMIT && OrderLots()==10){
                closeAll();
                ReachProfit = true;
                Position=POSITION_HOLD;
                lowestOrTopest     = 0;
             }
           }
         }
      }
   }

   //manual open position
   if(ReachProfit == true && totalOpenOrder()>=1){
        for (i=0; i<OrdersTotal(); i++){
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
             if(Symbol()==OrderSymbol()){
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
          }
       }
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

    double MABuy  = iMA(Symbol(), PERIOD_CURRENT, ma_period, 0, ma_method, PRICE_HIGH, 0);
    double MASell = iMA(Symbol(), PERIOD_CURRENT, ma_period, 0, ma_method, PRICE_LOW, 0);
    double FastMa = iMA(Symbol(), PERIOD_CURRENT, 1, 0, MODE_SMA, PRICE_CLOSE, 0);

    space_buy = FastMa-MABuy;

    space_sell = MASell-FastMa;

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
                                OrderSend(Symbol(),OP_SELL, NormalizeDouble(OrderLots()*2,2), Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
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
                                 OrderSend(Symbol(),OP_BUY, NormalizeDouble(OrderLots()*2,2), Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
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

   if (
       totalOpenOrder()<MaxOrder
       && lastOpen<=iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder)
   ){
       if (Order==SIGNAL_BUY && space_buy<=space_with_ma*pnt && space_buy>0 && iLow(Symbol(),PERIOD_CURRENT,0)>=MABuy)
       {
          lastOpen = iTime(Symbol(),0,0);
          HLposition = Bid;
          OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, Bid-StopLossPerOrder*pnt, 0, "BELI", 10, 0, Green);
       }
       else if (Order==SIGNAL_SELL && space_sell<=space_with_ma*pnt && space_sell>0 && iHigh(Symbol(),PERIOD_CURRENT,0)<=MASell)
       {
         lastOpen = iTime(Symbol(),0,0);
         HLposition = Bid;
         OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, Ask+StopLossPerOrder*pnt, 0, "JUAL", 10, 0, Red);
       }
   }

    return(0);
}
