//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define STATUS_CLOSE  0
#define STATUS_OPEN   1

#define LAST_SELL  0
#define LAST_BUY   1


extern   int      InitialBalance        = 1000;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = false;
extern   int      FastMA                = 3;
extern   int      SlowMa                = 15;
extern   int      SpacePerOrder         = 5;
extern   int      ForceXcandle          = 5;
extern   int      MartiIn               = 20;
extern   double   TakeProfitBaseCurency = 10;
extern   int      Slippage              = 3;
extern   double   MaxDailyProfit        = 0.02;
extern   double   MaxLost               = 0.05;

double  MartiBuyAt            = 0;
double  MartiSellAt           = 0;
int     MartiIndex            = 0;

int     OpenDay             = 0;
int     lastOpen            = 0;
int     Order               = 0;
int     Status              = 0;
int     LastOrder           = 0;
double  OpenLot             = 0;
double  AQ                  = 0;
double  ProfitTaget         = 0;
double  DailyProfitTaget    = 0;
double  DailyMaxLoss        = 0;
double  OpenEquity          = 0;


double optimizeLots(){
    if(LotsOptimize){
        return NormalizeDouble(AccountEquity()/InitialBalance*InitialLots, 2);
    }

    return InitialLots;
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
    AQ = AccountEquity();

    if(Status==STATUS_CLOSE){
       ProfitTaget = AQ+(AQ+TakeProfitBaseCurency);
    }

    if(OpenDay+86400<iTime(Symbol(),PERIOD_CURRENT,0)){
       DailyProfitTaget = AQ+(AQ*MaxDailyProfit);
       DailyMaxLoss = AQ-(AQ*MaxLost);
       OpenDay = iTime(Symbol(),PERIOD_CURRENT,0);
    }


    if(Bars<50+SlowMa) return;

    int Order = SIGNAL_NONE;
    int Sideway = false;

    double PrevFastMaValue  = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 1);
    double PrevSlowMaValue  = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 1);

    double CurrentFastMaValue   = iMA(Symbol(), PERIOD_CURRENT, FastMA, 0, MODE_SMA, PRICE_CLOSE, 0);
    double CurrentSlowMaValue   = iMA(Symbol(), PERIOD_CURRENT, SlowMa, 0, MODE_SMA, PRICE_CLOSE, 0);

       //+------------------------------------------------------------------+
       //| Signal Begin(Entry)                                              |
       //+------------------------------------------------------------------+

//create first entry buy signal
       if (
           PrevFastMaValue >= PrevSlowMaValue
           &&CurrentFastMaValue < CurrentSlowMaValue
           &&Status==STATUS_CLOSE
           ) Order = SIGNAL_BUY;

//create first entry sell signal
       if (
           PrevFastMaValue <= PrevSlowMaValue
           &&CurrentFastMaValue > CurrentSlowMaValue
           &&Status==STATUS_CLOSE
           ) Order = SIGNAL_SELL;

//take profit
        if((AQ > OpenEquity+TakeProfitBaseCurency) && Status==STATUS_OPEN){
            closeAll();
            Status=STATUS_CLOSE;
        }

//force Close
        if(lastOpen<iTime(Symbol(),PERIOD_CURRENT,ForceXcandle) && AQ > OpenEquity){
            closeAll();
            Status=STATUS_CLOSE;
        }

//first Entry
    if (
        OrdersTotal()<1
        && Status==STATUS_CLOSE
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,5)
        && AQ<=DailyProfitTaget
//        && AQ>DailyMaxLoss
    ){
        if (Order==SIGNAL_BUY)
        {
           MartiBuyAt   = Ask;
           MartiSellAt  = NormalizeDouble(Bid+(MartiIn*Point),Digits);
           lastOpen = iTime(Symbol(),0,0);

           Order = SIGNAL_NONE;
           Status=STATUS_OPEN;
           LastOrder = LAST_BUY;
           MartiIndex++;
           OpenLot = optimizeLots();
           lastOpen = iTime(Symbol(),0,0);
           OrderSend(Symbol(),OP_BUY, OpenLot, Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
           OpenEquity = AccountEquity();
        }

        else if (Order==SIGNAL_SELL)
        {
          MartiSellAt = Bid;
          MartiBuyAt  = NormalizeDouble(Bid+(MartiIn*Point),Digits);
          lastOpen = iTime(Symbol(),0,0);

          Order = SIGNAL_NONE;
          Status=STATUS_OPEN;
          LastOrder = LAST_SELL;
          OpenLot = optimizeLots();
          lastOpen = iTime(Symbol(),0,0);
          OrderSend(Symbol(),OP_SELL, OpenLot, Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
          OpenEquity = AccountEquity();
        }
    }

//MartiEntri Entry
    if (
        OrdersTotal()>=1
        && lastOpen<iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder)
        && AQ<=ProfitTaget
    ){
        if (
        Status==STATUS_OPEN
        &&  LastOrder == LAST_SELL
        &&  Ask > MartiBuyAt
        )
        {
           lastOpen = iTime(Symbol(),0,0);
           LastOrder = LAST_BUY;
           OpenLot = OpenLot*1.2;
           OrderSend(Symbol(),OP_BUY, OpenLot, Ask, Slippage, 0, 0, "BELI", 10, 0, Green);
        }

        if (
        Status==STATUS_OPEN
        &&  LastOrder == LAST_BUY
        &&  Bid < MartiSellAt
        )
        {
          lastOpen = iTime(Symbol(),0,0);
          LastOrder = LAST_SELL;
          OpenLot = OpenLot*1.2;
          OrderSend(Symbol(),OP_SELL, OpenLot, Bid, Slippage, 0, 0, "JUAL", 10, 0, Red);
        }
    }

    return(0);
 }
