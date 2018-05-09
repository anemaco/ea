//--------------------------------------------------------------------
// userindicator.mq4
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property copyright "semplon"

#property indicator_separate_window // Indicator is drawn in the main window
#property indicator_buffers 5       // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
#property indicator_color2 Gold      // Color of the 2nd line
#property indicator_color3 Green
#property indicator_color4 Blue
#property indicator_color5 Purple

#property indicator_level1 0

extern bool count_eur = true;
extern bool count_usd = true;
extern bool count_gbp = true;
extern bool count_aud = true;
extern bool count_jpy = true;

extern bool show_eur = false;
extern bool show_usd = false;
extern bool show_gbp = false;
extern bool show_aud = false;
extern bool show_jpy = false;

extern ENUM_TIMEFRAMES TIMEFRAME = PERIOD_CURRENT;
extern int  MA_PERIOD            = 12;
extern int  BACK_STEP            = 1;
extern int  INITIAL_TOTAL_CANDLE = 50;
extern bool show_recomendation   = false;

bool alert = true;
bool initial = true;

double Eur[],Usd[],Gbp[],Aud[],Jpy[];             // Declaring arrays (for indicator buffers)
//--------------------------------------------------------------------
int init()                          // Special function init()
  {
   SetIndexBuffer(0,Eur);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_DOT,1);// Line style
   SetIndexLabel (0,"EUR");

   SetIndexBuffer(1,Usd);         // Assigning an array to a buffer
   SetIndexStyle (1,DRAW_LINE,STYLE_DOT,1);// Line style
   SetIndexLabel (1,"USD");

   SetIndexBuffer(2,Gbp);         // Assigning an array to a buffer
   SetIndexStyle (2,DRAW_LINE,STYLE_DOT,1);// Line style
   SetIndexLabel (2,"GBP");

   SetIndexBuffer(3,Aud);         // Assigning an array to a buffer
   SetIndexStyle (3,DRAW_LINE,STYLE_DOT,1);// Line style
   SetIndexLabel (3,"AUD");

   SetIndexBuffer(4,Jpy);
   SetIndexStyle (4,DRAW_LINE,STYLE_DOT,1);
   SetIndexLabel (4,"JPY");

   if(show_eur){
     SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   }

   if(show_usd){
     SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2);// Line style
   }

   if(show_gbp){
     SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,2);// Line style
   }

   if(show_aud){
     SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,2);// Line style
   }

   if(show_jpy){
     SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,2);// Line style
   }

   return 0;
  }

int start()
{
 if(TimeCurrent()%5!=0){
     return;
 }

  if(initial){
     generateLine(INITIAL_TOTAL_CANDLE);
     initial=false;
  }

 generateLine(0);
 return 0;
}

void generateLine(int p){
   int position  = p;
   int timeFrame = TIMEFRAME;

   while(position>=0){
      double EurUsd = getMaRange("EURUSD",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double EurJpy = getMaRange("EURJPY",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double EurGbp = getMaRange("EURGBP",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double EurAud = getMaRange("EURAUD",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double GbpUsd = getMaRange("GBPUSD",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double GbpAud = getMaRange("GBPAUD",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double GbpJpy = getMaRange("GBPJPY",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double AudUsd = getMaRange("AUDUSD",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double AudJpy = getMaRange("AUDJPY",timeFrame,MA_PERIOD,position,BACK_STEP)*10;
      double UsdJpy = getMaRange("USDJPY",timeFrame,MA_PERIOD,position,BACK_STEP)*10;

      Usd[position] = 0;
      Jpy[position] = 0;
      Aud[position] = 0;
      Gbp[position] = 0;
      Eur[position] = 0;

      if(count_eur){
         Usd[position] += -EurUsd;
         Jpy[position] += -EurJpy;
         Aud[position] += -EurAud;
         Gbp[position] += -EurGbp;
      }else{
         SetIndexStyle (0, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_usd){
         Eur[position] += EurUsd;
         Jpy[position] += -UsdJpy;
         Aud[position] += AudUsd;
         Gbp[position] += GbpUsd;
      }else{
         SetIndexStyle (1, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_gbp){
        Eur[position] += EurGbp;
        Usd[position] += -GbpUsd;
        Jpy[position] += -GbpJpy;
        Aud[position] += -GbpAud;
      }else{
        SetIndexStyle (2, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_aud){
        Eur[position] += EurAud;
        Usd[position] += -AudUsd;
        Jpy[position] += -AudJpy;
        Gbp[position] += GbpAud;
      }else{
        SetIndexStyle (3, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_jpy){
        Eur[position] += EurJpy;
        Usd[position] += UsdJpy;
        Aud[position] += AudJpy;
        Gbp[position] += GbpJpy;
      }else{
        SetIndexStyle (4, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(position==0){
         double e,u,g,a,j;
         e = Eur[0];
         u = Usd[0];
         g = Gbp[0];
         a = Aud[0];
         j = Jpy[0];

         SetIndexLabel (0,"EUR "+e);
         SetIndexLabel (1,"USD "+u);
         SetIndexLabel (2,"GBP "+g);
         SetIndexLabel (3,"AUD "+a);
         SetIndexLabel (4,"JPY "+j);

          if(show_recomendation){
             SetIndexStyle (0,DRAW_LINE,STYLE_DOT,1);// Line style
             SetIndexStyle (1,DRAW_LINE,STYLE_DOT,1);// Line style
             SetIndexStyle (2,DRAW_LINE,STYLE_DOT,1);// Line style
             SetIndexStyle (3,DRAW_LINE,STYLE_DOT,1);// Line style
             SetIndexStyle (4,DRAW_LINE,STYLE_DOT,1);// Line style

             if(show_eur){
                SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
             }

            if(show_usd){
              SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if(show_gbp){
              SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if(show_aud){
              SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if(show_jpy){
              SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if((e>u && e>g && e>a && e>j) || (e<u && e<g && e<a && e<j)){
               SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if((u>e && u>g && u>a && u>j) || (u<e && u<g && u<a && u<j)){
               SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if((g>e && g>u && g>a && g>j) || (g<e && g<u && g<a && g<j)){
               SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if((a>e && a>g && a>u && a>j) || (a<e && a<g && a<u && a<j)){
               SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,2);// Line style
            }

            if((j>e && j>g && j>a && j>u) || (j<e && j<g && j<a && j<u)){
               SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,2);// Line style
            }
       }
     }

      position--;
   }

}

double getMaRange(string symbol, int timeFrame, int period, int position, int backstep){
  double startMa = iMA(symbol, timeFrame, period,0,MODE_LWMA,PRICE_CLOSE,position);
  double backMa = iMA(symbol, timeFrame, period,0,MODE_LWMA,PRICE_CLOSE,position+backstep);

  double pnt = MarketInfo(symbol,MODE_POINT);
  double dig = MarketInfo(symbol,MODE_DIGITS);
  if (dig == 3 || dig == 5) {
    pnt *= 10;
  }

  return ((startMa - backMa)/startMa)*100;
}