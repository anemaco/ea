//+------------------------------------------------------------------+
//| EA RSI DIVERGEN                                                  |
//+------------------------------------------------------------------+
#property copyright "Adnan Adiatman"

#define SIGNAL_NONE  0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2

extern   int      InitialBalance        = 1000;
extern   double   InitialLots           = 0.01;
extern   bool     LotsOptimize          = true;
extern   int      RsiPeriod             = 16;
extern   int      SearchBack            = 50;
extern   int      TotalCandle           = 100;
extern   int      MaxOrder              = 1;
extern   int      MinSpaceOrder         = 1;
extern   string   xxxxxxxxxx            = "Marti Setting";
extern   double   MartiMultiple         = 2;
extern   int      MartiInitialTakeProfit= 100;
extern   double   MaxMartiLots          = 10;
extern   string   xxxxxxxxx             = "==========";
extern   int      StopLoss              = 100;
extern   bool     StopLossOptimize      = false;
extern   int      InitialTakeProfit     = 200;
extern   int      TakeProfit            = 130;
extern   int      StopTrail             = 30;
extern   int      Slippage              = 3;

double pnt;
double dig;

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

int init()                          // Special function init()
{
   pnt = Point;
   dig = MarketInfo(Symbol(),MODE_DIGITS);

   if (dig == 2 || dig == 4) {
     pnt /= 10;
   }
}


int start()
 {
    UpdateStopLost();

    if(Bars<SearchBack) return;

    int Order = SIGNAL_NONE;

    int timeFrame = PERIOD_CURRENT;
    int position  = 1;

//===================================================================
//===================================================================
       position  = SearchBack+1;

       while(position>=0){
          rsiDown[position] = iRSI(NULL, timeFrame, RsiPeriod, PRICE_CLOSE,position);
          position--;
       }
//===================================================================
//===================================================================
       position  = SearchBack+1;

       while(position>=0){
          rsiUp[position]  = iRSI(NULL, timeFrame, RsiPeriod, PRICE_LOW,position);
          position--;
       }
//===================================================================
//===================================================================

        position  = 1;


//===================================================================
//===================================================================
          int backIndex = 1;

          while(backIndex <= SearchBack){
            if(rsiDown[position+backIndex]>40){
                backIndex = SearchBack+1;
                continue;
            }

            if(
            rsiUp[position]>rsiUp[position+backIndex]&&
            rsiUp[position+backIndex]<=40 &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex+1] &&
            rsiUp[position+backIndex]<rsiUp[position+backIndex+2] &&
            rsiUp[position]<=40 &&
            Low[position]<Low[position+backIndex]&&
            Low[position]<Low[position+1]&&
            Low[1]<Low[position]
            ){
                TrendLine(Time[position], Time[position+backIndex], Low[position+backIndex], Time[position], Low[position], clrAqua, STYLE_DOT, 2, false);
                Order = SIGNAL_BUY;
                backIndex = SearchBack+1;
                continue;
            }

            backIndex++;
          }
//===================================================================
//===================================================================
        backIndex = 1;

        while(backIndex <= SearchBack){
          if(rsiDown[position+backIndex]<60){
            backIndex = SearchBack+1;
            continue;
          }

          if(
            rsiDown[position]<rsiDown[position+backIndex]&&
            rsiDown[position+backIndex]>=60 &&
            rsiDown[position+backIndex]>rsiDown[position+backIndex+1] &&
            rsiDown[position+backIndex]>rsiDown[position+backIndex+2] &&
            rsiDown[position]>=60 &&
            rsiDown[position]>rsiDown[position+1]&&
            High[position]>High[position+backIndex]&&
            High[position]>High[position+1]&&
            High[0]>High[position]
          ){
             TrendLine(Time[position], Time[position+backIndex], High[position+backIndex], Time[position], High[position], clrRed, STYLE_DOT, 2, false);
             Order = SIGNAL_SELL;
             backIndex = SearchBack+1;
             continue;
          }

          backIndex++;
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

 void TrendLine( string name, datetime T0, double P0, datetime T1, double P1, color clr, string style,int width, bool ray=false )
 {
    if(ObjectFind(name) != 0)
    {
       if(!ObjectCreate( name, OBJ_TREND, 0, T0, P0, T1, P1 ))
          Alert("ObjectCreate(",name,",TREND) failed: ", GetLastError() );
       else if (!ObjectSet( name, OBJPROP_RAY, ray ))
          Alert("ObjectSet(", name, ",Ray) failed: ", GetLastError());
       if (!ObjectSet(name, OBJPROP_COLOR, clr )) // Allow color change
          Alert("ObjectSet(", name, ",Color) [2] failed: ", GetLastError());
       if (!ObjectSet(name,OBJPROP_STYLE,style)) // Allow color change
          Alert("ObjectSet(", name, ",Style) [2] failed: ", GetLastError());
       if (!ObjectSet(name,OBJPROP_WIDTH,width)) // Allow color change
          Alert("ObjectSet(", name, ",Width) [2] failed: ", GetLastError());
    }
    else
    {
       ObjectDelete(name);
       if(!ObjectCreate( name, OBJ_TREND, 0, T0, P0, T1, P1 ))
          Alert("ObjectCreate(",name,",TREND) failed: ", GetLastError() );
       else if (!ObjectSet( name, OBJPROP_RAY, ray ))
          Alert("ObjectSet(", name, ",Ray) failed: ", GetLastError());
       if (!ObjectSet(name, OBJPROP_COLOR, clr )) // Allow color change
          Alert("ObjectSet(", name, ",Color) [2] failed: ", GetLastError());
       if (!ObjectSet(name,OBJPROP_STYLE,style)) // Allow color change
          Alert("ObjectSet(", name, ",Style) [2] failed: ", GetLastError());
       if (!ObjectSet(name,OBJPROP_WIDTH,width)) // Allow color change
          Alert("ObjectSet(", name, ",Width) [2] failed: ", GetLastError());
     }
 }
