//+------------------------------------------------------------------+
//| Scalping Momentum.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define MMT_POSISITON_NETRAL  0
#define MMT_POSISITON_TOP  1
#define MMT_POSISITON_BOT  2
#define MMT_POSISITON_OPEN_BUY  3
#define MMT_POSISITON_OPEN_SELL  4

extern   int      MomentumPeriod        = 12;
extern   int      InitialBalance        = 500;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      MaxOrder              = 30;
extern   int      LowOrTopSpread        = 75;
extern   int      StopLossPerOrder      = 100;
extern   int      TakeProfit            = 70;
extern   int      Slippage              = 3;
extern   int      MaxDailyProfit        = 10;


double  HLposition         = 0;
double  DailyProfitTaget   = 0;
int     day                = 0;
int     i                  = 0;
int     MmtPosition        = 0;
double  Top                = 0;
double  PrevTop            = 0;
double  StatusBuy          = 0;
double  Bottom             = 0;
double  PrevBottom         = 0;
double  StatusSell         = 0;
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

int init(){

   pnt = Point;
   dig = MarketInfo(Symbol(),MODE_DIGITS);

   if (dig == 2 || dig == 4) {
     pnt /= 10;
   }
}

int totalOpenOrder(){
    int totalOpen = 0;

    for (i=0; i<OrdersTotal(); i++){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
       {
          if(OrderType()==OP_BUY || OrderType()==OP_SELL)
            totalOpen++;
       }
    }

   return totalOpen;
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

int start(){
    int Order = SIGNAL_NONE;

    double mmt = iMomentum(Symbol(),0,MomentumPeriod,PRICE_OPEN,0);

    if(mmt>=100.15 && MmtPosition!=MMT_POSISITON_OPEN_BUY){
        if(MmtPosition!=MMT_POSISITON_TOP){
            PrevTop = Top;
            Top = mmt;
            MmtPosition = MMT_POSISITON_TOP;
        }

        if(MmtPosition == MMT_POSISITON_TOP && mmt>Top){
            Top = mmt;
        }
    }

    if(mmt<=99.85 && MmtPosition!=MMT_POSISITON_OPEN_SELL){
        if(MmtPosition!=MMT_POSISITON_BOT){
            PrevBottom = Bottom;
            Bottom = mmt;
            MmtPosition==MMT_POSISITON_BOT;
        }

        if(MmtPosition == MMT_POSISITON_BOT && mmt<Bottom){
            Bottom = mmt;
        }
    }

    if(
       PrevTop<=Top
       && MmtPosition == MMT_POSISITON_BOT
       && Bottom+0.15<=mmt
       && mmt<=99.99
    ){
     Order = SIGNAL_BUY;
     MmtPosition = MMT_POSISITON_OPEN_BUY;
    }

    if(
       PrevBottom>=Bottom
       && MmtPosition == MMT_POSISITON_TOP
       && Top-0.15>=mmt
       && mmt>=100.01
    ){
     Order = SIGNAL_SELL;
     StatusSell = 0;
     MmtPosition = MMT_POSISITON_OPEN_SELL;
    }

    if (Order==SIGNAL_BUY)
    {
       Order=SIGNAL_NONE;
       OrderSend(Symbol(),OP_BUY, optimizeLots(), Ask, Slippage, Bid-StopLossPerOrder*pnt, Ask+TakeProfit*pnt, "BELI", 10, 0, Green);
    }

    else if (Order==SIGNAL_SELL)
    {
      Order=SIGNAL_NONE;
      OrderSend(Symbol(),OP_SELL, optimizeLots(), Bid, Slippage, Ask+StopLossPerOrder*pnt, Bid-TakeProfit*pnt, "JUAL", 10, 0, Red);
    }

    return(0);
}
