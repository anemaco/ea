//--------------------------------------------------------------------
// userindicator.mq4
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property copyright "Semplon"

#property indicator_separate_window // Indicator is drawn in the main window
#property indicator_buffers 5       // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
#property indicator_color2 Orange      // Color of the 2nd line
#property indicator_color3 Yellow
#property indicator_color4 Lime
#property indicator_color5 Blue
#property indicator_color6 Purple
#property indicator_color7 clrBrown
#property indicator_color8 clrDimGray

#property indicator_level1 0

bool count_eur = true;
bool count_usd = true;
bool count_gbp = true;
bool count_aud = true;
bool count_jpy = true;
bool count_cad = true;
bool count_chf = true;
bool count_nzd = true;

extern bool show_eur = false;
extern bool show_usd = false;
extern bool show_gbp = false;
extern bool show_aud = false;
extern bool show_jpy = false;
extern bool show_cad = false;
extern bool show_chf = false;
extern bool show_nzd = false;
extern bool show_recomendation   = false;


extern ENUM_TIMEFRAMES TIMEFRAME = PERIOD_CURRENT;
extern int  SEARCH_BACK          = 50;
extern int  INITIAL_SHOW_BACK    = 500;

bool alert = true;
bool initial = true;

double penambah = 0;

double Eur[],Usd[],Gbp[],Aud[],Jpy[];             // Declaring arrays (for indicator buffers)
double TempEur[5000],TempUsd[5000],TempGbp[5000],TempAud[5000],TempJpy[5000];             // Declaring arrays (for indicator buffers)
//--------------------------------------------------------------------
int init()                          // Special function init()
  {
   SetIndexBuffer(0,Eur);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_DOT,1,clrBlack);// Line style
   SetIndexLabel (0,"EUR");

   SetIndexBuffer(1,Usd);         // Assigning an array to a buffer
   SetIndexStyle (1,DRAW_LINE,STYLE_DOT,1,clrBlack);// Line style
   SetIndexLabel (1,"USD");

   SetIndexBuffer(2,Gbp);         // Assigning an array to a buffer
   SetIndexStyle (2,DRAW_LINE,STYLE_DASH,1,clrBlack);// Line style
   SetIndexLabel (2,"GBP");

   SetIndexBuffer(3,Aud);         // Assigning an array to a buffer
   SetIndexStyle (3,DRAW_LINE,STYLE_DOT,1,clrBlack);// Line style
   SetIndexLabel (3,"AUD");

   SetIndexBuffer(4,Jpy);
   SetIndexStyle (4,DRAW_LINE,STYLE_DOT,1,clrBlack);
   SetIndexLabel (4,"JPY");

   if(show_eur){
     SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2, clrRed);// Line style
   }

   if(show_usd){
     SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2, clrGold);// Line style
   }

   if(show_gbp){
     SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,2, clrGreen);// Line style
   }

   if(show_aud){
     SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,2, clrBlue);// Line style
   }

   if(show_jpy){
     SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,2, clrPurple);// Line style
   }

   return 0;
  }

int start()
{

 if(initial){
     int tb = INITIAL_SHOW_BACK;

     while(tb>=0){
          generateLine(SEARCH_BACK,tb);
          tb--;
     }

     initial= false;
 }

 if(TimeCurrent()%3!=0){
     return;
 }

 generateLine(SEARCH_BACK, 0);
 return 0;
}

void generateLine(int p, int t){
   int position  = p+t;
   int timeFrame = TIMEFRAME;

   TempEur[position+1]=0;
   TempUsd[position+1]=0;
   TempGbp[position+1]=0;
   TempAud[position+1]=0;
   TempJpy[position+1]=0;

   while(position>=0){
      double EurUsd = (iClose("EURUSD",timeFrame,position)-iClose("EURUSD",timeFrame,position+1))*100/iClose("EURUSD",timeFrame,position+1);
      double EurJpy = (iClose("EURJPY",timeFrame,position)-iClose("EURJPY",timeFrame,position+1))*100/iClose("EURJPY",timeFrame,position+1);
      double EurGbp = (iClose("EURGBP",timeFrame,position)-iClose("EURGBP",timeFrame,position+1))*100/iClose("EURGBP",timeFrame,position+1);
      double EurAud = (iClose("EURAUD",timeFrame,position)-iClose("EURAUD",timeFrame,position+1))*100/iClose("EURAUD",timeFrame,position+1);
      double GbpUsd = (iClose("GBPUSD",timeFrame,position)-iClose("GBPUSD",timeFrame,position+1))*100/iClose("GBPUSD",timeFrame,position+1);
      double GbpAud = (iClose("GBPAUD",timeFrame,position)-iClose("GBPAUD",timeFrame,position+1))*100/iClose("GBPAUD",timeFrame,position+1);
      double GbpJpy = (iClose("GBPJPY",timeFrame,position)-iClose("GBPJPY",timeFrame,position+1))*100/iClose("GBPJPY",timeFrame,position+1);
      double AudUsd = (iClose("AUDUSD",timeFrame,position)-iClose("AUDUSD",timeFrame,position+1))*100/iClose("AUDUSD",timeFrame,position+1);
      double AudJpy = (iClose("AUDJPY",timeFrame,position)-iClose("AUDJPY",timeFrame,position+1))*100/iClose("AUDJPY",timeFrame,position+1);
      double UsdJpy = (iClose("USDJPY",timeFrame,position)-iClose("USDJPY",timeFrame,position+1))*100/iClose("USDJPY",timeFrame,position+1);

      TempEur[position]=TempEur[position+1];
      TempUsd[position]=TempUsd[position+1];
      TempGbp[position]=TempGbp[position+1];
      TempAud[position]=TempAud[position+1];
      TempJpy[position]=TempJpy[position+1];

      TempEur[position] += EurUsd;

      TempJpy[position] += -UsdJpy;

      TempAud[position] += AudUsd;

      TempGbp[position] += GbpUsd;

      if(position==t){

         Usd[t] = 0;
         Jpy[t] = TempJpy[t];
         Aud[t] = TempAud[t];
         Gbp[t] = TempGbp[t];
         Eur[t] = TempEur[t];

         double e,u,g,a,j;
         e = Eur[t];
         u = Usd[t];
         g = Gbp[t];
         a = Aud[t];
         j = Jpy[t];

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
               SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2, Red);// Line style
            }

            if((u>e && u>g && u>a && u>j) || (u<e && u<g && u<a && u<j)){
               SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2, Gold);// Line style
            }

            if((g>e && g>u && g>a && g>j) || (g<e && g<u && g<a && g<j)){
               SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,2, Green);// Line style
            }

            if((a>e && a>g && a>u && a>j) || (a<e && a<g && a<u && a<j)){
               SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,2, Blue);// Line style
            }

            if((j>e && j>g && j>a && j>u) || (j<e && j<g && j<a && j<u)){
               SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,2, Purple);// Line style
            }
       }

       return 0;
     }

      position--;
   }

}