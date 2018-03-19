//+------------------------------------------------------------------+
//| Buy Sell use 3 MA.mq4                                            |
//+------------------------------------------------------------------+
#property copyright "Adnan De Semplon"

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

extern   int      InitialBalance        = 100;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      RsiPeriod             = 9;
extern   int      SearchBack            = 50;
extern   int      TotalCandle           = 100;
extern   int      MaxOrder              = 5;
extern   int      MinSpaceOrder         = 3;
extern   int      StopLoss              = 500;
extern   bool     StopLossOptimize      = false;
extern   int      MaxLoss               = 2500;
extern   int      TakeProfit            = 100;
extern   int      StopTrail             = 1;
extern   int      Slippage              = 3;

int  CurrentOrder = 0;
int  cnt,ticket,total;
int  lastOpen = 0;

int  StatusCCI = 0;
int  AQ = 0;
int  backIndex;

double rsiUp[1000],rsiDown[1000];

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

void UpdateStopLost(){
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
                         sl=NormalizeDouble(OrderOpenPrice()-(StopLoss*Point),Digits);
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
                    }

                    if(prevStopLost!=sl && nextStopLost != 1000){
                         OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Blue);
                    }
                 }
              }
         }
    }
}

int start()
 {
    UpdateStopLost();

    if(Bars<SearchBack) return;

    int Order = SIGNAL_NONE;

    int timeFrame = PERIOD_CURRENT;

    backIndex = SearchBack;
    int position  = TotalCandle+SearchBack;

    while(position>0){
      rsiUp[position]  = iRSI(NULL, PERIOD_CURRENT, RsiPeriod, PRICE_CLOSE,position);
      position--;
    }

    position  = 1;
    while(backIndex>=0){
        if(
            rsiUp[position]>rsiUp[position+backIndex]&&
            rsiUp[position+backIndex]<=32 &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex+1] &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex-1] &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex+2] &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex-2] &&
            rsiUp[position]<=32 &&
            Low[position]<Low[position+backIndex]&&
            Low[position]<Low[position+1]
        )Order = SIGNAL_BUY;

        backIndex--;
      }

     position  = TotalCandle+SearchBack;

     while(position>=0){
        rsiDown[position] = iRSI(NULL, PERIOD_CURRENT, RsiPeriod, PRICE_CLOSE,position);
        position--;
     }

      backIndex = SearchBack;
      while(backIndex>=0){
         if(
             rsiDown[position]<rsiDown[position+backIndex]&&
             rsiDown[position+backIndex]>=68 &&
             rsiDown[position+backIndex]>rsiDown[position+backIndex+1] &&
             rsiDown[position+backIndex]>rsiDown[position+backIndex-1] &&
             rsiDown[position+backIndex]>rsiDown[position+backIndex+2] &&
             rsiDown[position+backIndex]>rsiDown[position+backIndex-2] &&
             rsiDown[position]>=68 &&
             rsiDown[position]>rsiDown[position+1]&&
             High[position]>High[position+backIndex]&&
             High[position]>High[position+1]
         )Order = SIGNAL_SELL;

         backIndex--;
     }

    if (
        OrdersTotal()<MaxOrder
//        && Anomali<(50*Point)
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
