//+------------------------------------------------------------------+
//| AUD/USD Oscilator EA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

#define POSITION_HOLD    0
#define POSITION_BUY     1
#define POSITION_SELL    2
#define POSITION_HOLD    0

extern   int              InitialBalance        = 1000;
extern   double           InitialLots           = 0.2;
extern   int              SaveEquityPercent     = 0;
extern   bool             LotsOptimize          = true;
extern   int              MaxOrder              = 10;
extern   int              SpacePerOrder         = 1;
extern   string           xxxxxxxxx             = "Oscilator Setting";
extern   int              k_period              = 50;
extern   int              d_period              = 3;
extern   int              slowing               = 3;
extern   ENUM_MA_METHOD   method                = 0;
extern   int              price_field           = 0;
extern   int              mode                  = 0;
extern   string           xxxxxxxxxx            = "Open Position Condition";
extern   int              OscilatorTop          = 70;
extern   int              OscilatorBottom       = 30;
extern   string           xxxxxxxxxxx            = "Marti Setting";
extern   double           MartiMultiple         = 2;
extern   int              MartiInitialTakeProfit= 300;
extern   double           MaxMartiLots          = 10;
extern   string           xxxxxxxxxxxxx         = "==========";
extern   int              StopLoss              = 300;
extern   bool             StopLossOptimize      = false;
extern   int              InitialTakeProfit     = 750;
extern   int              TakeProfit            = 1000;
extern   int              StopTrail             = 50;
extern   int              Slippage              = 3;

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

int  AQ = 0;

bool    ReachProfit       = true;

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

int init(){

   pnt = Point;
   dig = MarketInfo(Symbol(),MODE_DIGITS);

   if (dig == 2 || dig == 4) {
     pnt /= 10;
   }

  AB = AccountBalance();
}

void UpdateStopLost(){
   if(OrdersTotal()>=1){
         double sl=0;
         double nextStopLost=0;
         double prevStopLost=0;
         double tempLot = 0;

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
                         sl=NormalizeDouble(OrderOpenPrice()-(StopLoss*Point),Digits);

                         if(Bid<=sl){
                             tempLot = OrderLots()*MartiMultiple;
                             OrderClose(OrderTicket(),OrderLots(),Bid, 3,White);
                             if(tempLot<=MaxMartiLots){
                                OrderSend(Symbol(),OP_SELL, NormalizeDouble(OrderLots()*MartiMultiple,2), Bid, Slippage, 0, Bid-MartiInitialTakeProfit*pnt, "JUAL", 10, 0, Red);
                             }
                         }
                         continue;
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
                        sl=NormalizeDouble(OrderOpenPrice()+(optimizeStopLoss()*Point),Digits);

                        if(Ask>=sl){
                           tempLot = OrderLots()*MartiMultiple;
                           OrderClose(OrderTicket(),OrderLots(),Ask, 3,White);
                           if(tempLot<=MaxMartiLots){
                              OrderSend(Symbol(),OP_BUY, NormalizeDouble(OrderLots()*MartiMultiple,2), Ask, Slippage, 0, Ask+MartiInitialTakeProfit*pnt, "BELI", 10, 0, Green);
                           }
                        }
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

int start(){
   UpdateStopLost();

   if (!(totalOpenOrder()<MaxOrder && lastOpen<=iTime(Symbol(),PERIOD_CURRENT,SpacePerOrder))){
        return 0;
   }

    //5 minute
    double AudUsd5 = iStochastic("AUDUSD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpAud5 = 100-iStochastic("GBPAUD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double EurAud5 = 100-iStochastic("EURAUD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudJpy5 = iStochastic("AUDJPY",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudChf5 = iStochastic("AUDCHF",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudCad5 = iStochastic("AUDCAD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudNzd5 = iStochastic("AUDNZD",5,k_period,d_period,slowing,method,price_field, mode, 1);


    double Total5      = 0;
    double Divider5    = 0;

    if(AudUsd5>0 && AudUsd5<100){Total5+=AudUsd5; Divider5++;}
    if(GbpAud5>0 && GbpAud5<100){Total5+=GbpAud5; Divider5++;}
    if(EurAud5>0 && EurAud5<100){Total5+=EurAud5; Divider5++;}
    if(AudJpy5>0 && AudJpy5<100){Total5+=AudJpy5; Divider5++;}
    if(AudChf5>0 && AudChf5<100){Total5+=AudChf5; Divider5++;}
    if(AudCad5>0 && AudCad5<100){Total5+=AudCad5; Divider5++;}
    if(AudNzd5>0 && AudNzd5<100){Total5+=AudNzd5; Divider5++;}

    double Avg5 = Total5/Divider5;

        //usd
    double EurUsd5 = 100-iStochastic("EURUSD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdJpy5 = iStochastic("USDJPY",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpUsd5 = 100- iStochastic("GBPUSD",5,k_period,d_period,slowing,method,price_field, mode, 1);
           AudUsd5 = 100-iStochastic("AUDUSD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdCad5 = iStochastic("USDCAD",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdChf5 = iStochastic("USDCHF",5,k_period,d_period,slowing,method,price_field, mode, 1);
    double NzdUsd5 = 100-iStochastic("NZDUSD",5,k_period,d_period,slowing,method,price_field, mode, 1);

    double TotalUsd5      = 0;
    double DividerUsd5    = 0;

    if(EurUsd5>0 && EurUsd5<100){TotalUsd5+=EurUsd5; DividerUsd5++;}
    if(UsdJpy5>0 && UsdJpy5<100){TotalUsd5+=UsdJpy5; DividerUsd5++;}
    if(GbpUsd5>0 && GbpUsd5<100){TotalUsd5+=GbpUsd5; DividerUsd5++;}
    if(AudUsd5>0 && AudUsd5<100){TotalUsd5+=AudUsd5; DividerUsd5++;}
    if(UsdCad5>0 && UsdCad5<100){TotalUsd5+=UsdCad5; DividerUsd5++;}
    if(UsdChf5>0 && UsdChf5<100){TotalUsd5+=UsdChf5; DividerUsd5++;}
    if(NzdUsd5>0 && NzdUsd5<100){TotalUsd5+=NzdUsd5; DividerUsd5++;}

    double AvgUsd5 = TotalUsd5/DividerUsd5;

    //15 minute
    double AudUsd15 = iStochastic("AUDUSD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpAud15 = 100-iStochastic("GBPAUD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double EurAud15 = 100-iStochastic("EURAUD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudJpy15 = iStochastic("AUDJPY",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudChf15 = iStochastic("AUDCHF",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudCad15 = iStochastic("AUDCAD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudNzd15 = iStochastic("AUDNZD",15,k_period,d_period,slowing,method,price_field, mode, 1);

    double Total15      = 0;
    double Divider15    = 0;

    if(AudUsd15>0 && AudUsd15<150){Total15+=AudUsd15; Divider15++;}
    if(GbpAud15>0 && GbpAud15<150){Total15+=GbpAud15; Divider15++;}
    if(EurAud15>0 && EurAud15<150){Total15+=EurAud15; Divider15++;}
    if(AudJpy15>0 && AudJpy15<150){Total15+=AudJpy15; Divider15++;}
    if(AudChf15>0 && AudChf15<150){Total15+=AudChf15; Divider15++;}
    if(AudCad15>0 && AudCad15<150){Total15+=AudCad15; Divider15++;}
    if(AudNzd15>0 && AudNzd15<150){Total15+=AudNzd15; Divider15++;}

    double Avg15 = Total15/Divider15;

        //usd
    double EurUsd15 = 100-iStochastic("EURUSD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdJpy15 = iStochastic("USDJPY",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpUsd15 = 100- iStochastic("GBPUSD",15,k_period,d_period,slowing,method,price_field, mode, 1);
           AudUsd15 = 100-iStochastic("AUDUSD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdCad15 = iStochastic("USDCAD",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdChf15 = iStochastic("USDCHF",15,k_period,d_period,slowing,method,price_field, mode, 1);
    double NzdUsd15 = 100-iStochastic("NZDUSD",15,k_period,d_period,slowing,method,price_field, mode, 1);

    double TotalUsd15      = 0;
    double DividerUsd15    = 0;

    if(EurUsd15>0 && EurUsd15<100){TotalUsd15+=EurUsd15; DividerUsd15++;}
    if(UsdJpy15>0 && UsdJpy15<100){TotalUsd15+=UsdJpy15; DividerUsd15++;}
    if(GbpUsd15>0 && GbpUsd15<100){TotalUsd15+=GbpUsd15; DividerUsd15++;}
    if(AudUsd15>0 && AudUsd15<100){TotalUsd15+=AudUsd15; DividerUsd15++;}
    if(UsdCad15>0 && UsdCad15<100){TotalUsd15+=UsdCad15; DividerUsd15++;}
    if(UsdChf15>0 && UsdChf15<100){TotalUsd15+=UsdChf15; DividerUsd15++;}
    if(NzdUsd15>0 && NzdUsd15<100){TotalUsd15+=NzdUsd15; DividerUsd15++;}

    double AvgUsd15 = TotalUsd15/DividerUsd15;

    //30 minute
    double AudUsd30 = iStochastic("AUDUSD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpAud30 = 100-iStochastic("GBPAUD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double EurAud30 = 100-iStochastic("EURAUD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudJpy30 = iStochastic("AUDJPY",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudChf30 = iStochastic("AUDCHF",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudCad30 = iStochastic("AUDCAD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudNzd30 = iStochastic("AUDNZD",30,k_period,d_period,slowing,method,price_field, mode, 1);

    double Total30      = 0;
    double Divider30    = 0;

    if(AudUsd30>0 && AudUsd30<100){Total30+=AudUsd30; Divider30++;}
    if(GbpAud30>0 && GbpAud30<100){Total30+=GbpAud30; Divider30++;}
    if(EurAud30>0 && EurAud30<100){Total30+=EurAud30; Divider30++;}
    if(AudJpy30>0 && AudJpy30<100){Total30+=AudJpy30; Divider30++;}
    if(AudChf30>0 && AudChf30<100){Total30+=AudChf30; Divider30++;}
    if(AudCad30>0 && AudCad30<100){Total30+=AudCad30; Divider30++;}
    if(AudNzd30>0 && AudNzd30<100){Total30+=AudNzd30; Divider30++;}

    double Avg30 = Total30/Divider30;

        //usd
    double EurUsd30 = 100-iStochastic("EURUSD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdJpy30 = iStochastic("USDJPY",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpUsd30 = 100- iStochastic("GBPUSD",30,k_period,d_period,slowing,method,price_field, mode, 1);
           AudUsd30 = 100-iStochastic("AUDUSD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdCad30 = iStochastic("USDCAD",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdChf30 = iStochastic("USDCHF",30,k_period,d_period,slowing,method,price_field, mode, 1);
    double NzdUsd30 = 100-iStochastic("NZDUSD",30,k_period,d_period,slowing,method,price_field, mode, 1);

    double TotalUsd30      = 0;
    double DividerUsd30    = 0;

    if(EurUsd30>0 && EurUsd30<100){TotalUsd30+=EurUsd30; DividerUsd30++;}
    if(UsdJpy30>0 && UsdJpy30<100){TotalUsd30+=UsdJpy30; DividerUsd30++;}
    if(GbpUsd30>0 && GbpUsd30<100){TotalUsd30+=GbpUsd30; DividerUsd30++;}
    if(AudUsd30>0 && AudUsd30<100){TotalUsd30+=AudUsd30; DividerUsd30++;}
    if(UsdCad30>0 && UsdCad30<100){TotalUsd30+=UsdCad30; DividerUsd30++;}
    if(UsdChf30>0 && UsdChf30<100){TotalUsd30+=UsdChf30; DividerUsd30++;}
    if(NzdUsd30>0 && NzdUsd30<100){TotalUsd30+=NzdUsd30; DividerUsd30++;}

    double AvgUsd30 = TotalUsd30/DividerUsd30;

    //60 minute
    double AudUsd60 = iStochastic("AUDUSD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpAud60 = 100-iStochastic("GBPAUD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double EurAud60 = 100-iStochastic("EURAUD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudJpy60 = iStochastic("AUDJPY",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudChf60 = iStochastic("AUDCHF",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudCad60 = iStochastic("AUDCAD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudNzd60 = iStochastic("AUDNZD",60,k_period,d_period,slowing,method,price_field, mode, 1);


    double Total60      = 0;
    double Divider60    = 0;

    if(AudUsd60>0 && AudUsd60<100){Total60+=AudUsd60; Divider60++;}
    if(GbpAud60>0 && GbpAud60<100){Total60+=GbpAud60; Divider60++;}
    if(EurAud60>0 && EurAud60<100){Total60+=EurAud60; Divider60++;}
    if(AudJpy60>0 && AudJpy60<100){Total60+=AudJpy60; Divider60++;}
    if(AudChf60>0 && AudChf60<100){Total60+=AudChf60; Divider60++;}
    if(AudCad60>0 && AudCad60<100){Total60+=AudCad60; Divider60++;}
    if(AudNzd60>0 && AudNzd60<100){Total60+=AudNzd60; Divider60++;}

    double Avg60 = Total60/Divider60;

        //usd
    double EurUsd60 = 100-iStochastic("EURUSD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdJpy60 = iStochastic("USDJPY",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpUsd60 = 100- iStochastic("GBPUSD",60,k_period,d_period,slowing,method,price_field, mode, 1);
           AudUsd60 = 100-iStochastic("AUDUSD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdCad60 = iStochastic("USDCAD",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdChf60 = iStochastic("USDCHF",60,k_period,d_period,slowing,method,price_field, mode, 1);
    double NzdUsd60 = 100-iStochastic("NZDUSD",60,k_period,d_period,slowing,method,price_field, mode, 1);

    double TotalUsd60      = 0;
    double DividerUsd60    = 0;

    if(EurUsd60>0 && EurUsd60<100){TotalUsd60+=EurUsd60; DividerUsd60++;}
    if(UsdJpy60>0 && UsdJpy60<100){TotalUsd60+=UsdJpy60; DividerUsd60++;}
    if(GbpUsd60>0 && GbpUsd60<100){TotalUsd60+=GbpUsd60; DividerUsd60++;}
    if(AudUsd60>0 && AudUsd60<100){TotalUsd60+=AudUsd60; DividerUsd60++;}
    if(UsdCad60>0 && UsdCad60<100){TotalUsd60+=UsdCad60; DividerUsd60++;}
    if(UsdChf60>0 && UsdChf60<100){TotalUsd60+=UsdChf60; DividerUsd60++;}
    if(NzdUsd60>0 && NzdUsd60<100){TotalUsd60+=NzdUsd60; DividerUsd60++;}

    double AvgUsd60 = TotalUsd60/DividerUsd60;

    //240 minute
    double AudUsd240 = iStochastic("AUDUSD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpAud240 = 100-iStochastic("GBPAUD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double EurAud240 = 100-iStochastic("EURAUD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudJpy240 = iStochastic("AUDJPY",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudChf240 = iStochastic("AUDCHF",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudCad240 = iStochastic("AUDCAD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double AudNzd240 = iStochastic("AUDNZD",240,k_period,d_period,slowing,method,price_field, mode, 1);

    double Total240      = 0;
    double Divider240    = 0;
    if(AudUsd240>0 && AudUsd240<100){Total240+=AudUsd240; Divider240++;}
    if(GbpAud240>0 && GbpAud240<100){Total240+=GbpAud240; Divider240++;}
    if(EurAud240>0 && EurAud240<100){Total240+=EurAud240; Divider240++;}
    if(AudJpy240>0 && AudJpy240<100){Total240+=AudJpy240; Divider240++;}
    if(AudChf240>0 && AudChf240<100){Total240+=AudChf240; Divider240++;}
    if(AudCad240>0 && AudCad240<100){Total240+=AudCad240; Divider240++;}
    if(AudNzd240>0 && AudNzd240<100){Total240+=AudNzd240; Divider240++;}
    double Avg240 = Total240/Divider240;

        //usd
    double EurUsd240 = 100-iStochastic("EURUSD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdJpy240 = iStochastic("USDJPY",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double GbpUsd240 = 100- iStochastic("GBPUSD",240,k_period,d_period,slowing,method,price_field, mode, 1);
           AudUsd240 = 100-iStochastic("AUDUSD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdCad240 = iStochastic("USDCAD",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double UsdChf240 = iStochastic("USDCHF",240,k_period,d_period,slowing,method,price_field, mode, 1);
    double NzdUsd240 = 100-iStochastic("NZDUSD",240,k_period,d_period,slowing,method,price_field, mode, 1);

    double TotalUsd240      = 0;
    double DividerUsd240    = 0;

    if(EurUsd240>0 && EurUsd240<100){TotalUsd240+=EurUsd240; DividerUsd240++;}
    if(UsdJpy240>0 && UsdJpy240<100){TotalUsd240+=UsdJpy240; DividerUsd240++;}
    if(GbpUsd240>0 && GbpUsd240<100){TotalUsd240+=GbpUsd240; DividerUsd240++;}
    if(AudUsd240>0 && AudUsd240<100){TotalUsd240+=AudUsd240; DividerUsd240++;}
    if(UsdCad240>0 && UsdCad240<100){TotalUsd240+=UsdCad240; DividerUsd240++;}
    if(UsdChf240>0 && UsdChf240<100){TotalUsd240+=UsdChf240; DividerUsd240++;}
    if(NzdUsd240>0 && NzdUsd240<100){TotalUsd240+=NzdUsd240; DividerUsd240++;}

    double AvgUsd240 = TotalUsd240/DividerUsd240;

    //===========================================
    int Order = SIGNAL_NONE;

    //tentukan posisi
      if(
        //AUD Condition
        Avg5<OscilatorBottom
        &&Avg15<OscilatorBottom
        &&Avg30<OscilatorBottom
        &&Avg60<OscilatorBottom
        &&Avg240<OscilatorBottom

        //USD Condition
        &&AvgUsd5>OscilatorTop
        &&AvgUsd15>OscilatorTop
        &&AvgUsd30>OscilatorTop
        &&AvgUsd60>OscilatorTop
        &&AvgUsd240>OscilatorTop
      ){
          Position=POSITION_BUY;
          if(Position!=POSITION_BUY){
              HLposition = Bid;
          }else if(HLposition<Bid){
              HLposition = Bid;
          }
      }else if(
        //AUD Condition
        Avg5>OscilatorTop
        &&Avg15>OscilatorTop
        &&Avg30>OscilatorTop
        &&Avg60>OscilatorTop
        &&Avg240>OscilatorTop

        //USD COndition
        &&AvgUsd5<OscilatorBottom
        &&AvgUsd15<OscilatorBottom
        &&AvgUsd30<OscilatorBottom
        &&AvgUsd60<OscilatorBottom
        &&AvgUsd240<OscilatorBottom
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

    //tentukan signal
    if(Position==POSITION_BUY){
        Order = SIGNAL_BUY;
    }

    if(Position==POSITION_SELL){
        Order = SIGNAL_SELL;
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