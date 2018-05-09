//--------------------------------------------------------------------
// userindicator.mq4
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property copyright "Semplon"

#property indicator_separate_window // Indicator is drawn in the main window
#property indicator_buffers 5       // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
#property indicator_color2 Gold      // Color of the 2nd line
#property indicator_color3 Green
#property indicator_color4 Blue
#property indicator_color5 Purple

#property indicator_level1 0

bool count_eur = true;
bool count_usd = true;
bool count_gbp = true;
bool count_aud = true;
bool count_jpy = true;

extern bool show_eur = false;
extern bool show_usd = false;
extern bool show_gbp = false;
extern bool show_aud = false;
extern bool show_jpy = false;
extern bool show_recomendation   = false;


extern ENUM_TIMEFRAMES TIMEFRAME = PERIOD_CURRENT;
extern int  SEARCH_BACK          = 50;

bool alert = true;
bool initial = true;

double penambah = 0;

double Eur[],Usd[],Gbp[],Aud[],Jpy[];             // Declaring arrays (for indicator buffers)
double TempEur[5000],TempUsd[5000],TempGbp[5000],TempAud[5000],TempJpy[5000];             // Declaring arrays (for indicator buffers)
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

 if(initial){
     int tb = 1000;

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

      if(count_eur){
         penambah = 0;
         if(EurUsd>penambah){
             penambah = EurUsd;
         }

         if(EurJpy>penambah){
             penambah = EurJpy;
         }

         if(EurAud>penambah){
             penambah = EurAud;
         }

         if(EurGbp>penambah){
             penambah = EurGbp;
         }

         TempEur[position] += penambah;
      }else{
         SetIndexStyle (0, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_usd){
        penambah = 0;
         if(-EurUsd>penambah){
             penambah = -EurUsd;
         }

         if(UsdJpy>penambah){
             penambah = UsdJpy;
         }

         if(-AudUsd>penambah){
             penambah = -AudUsd;
         }

         if(-GbpUsd>penambah){
             penambah = -GbpUsd;
         }

         TempUsd[position] += penambah;
      }else{
         SetIndexStyle (1, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_gbp){
        penambah = 0;
         if(-EurGbp>penambah){
             penambah = -EurGbp;
         }

         if(GbpUsd>penambah){
             penambah = GbpUsd;
         }

         if(GbpJpy>penambah){
             penambah = GbpJpy;
         }

         if(GbpAud>penambah){
             penambah = GbpAud;
         }

         TempGbp[position] += penambah;
      }else{
        SetIndexStyle (2, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_aud){
        penambah = 0;
         if(-EurAud>penambah){
             penambah = -EurAud;
         }

         if(AudUsd>penambah){
             penambah = AudUsd;
         }

         if(AudJpy>penambah){
             penambah = AudJpy;
         }

         if(-GbpAud>penambah){
             penambah = -GbpAud;
         }

         TempAud[position] += penambah;
      }else{
        SetIndexStyle (3, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(count_jpy){
        penambah = 0;
         if(-EurJpy>penambah){
             penambah = -EurJpy;
         }

         if(-UsdJpy>penambah){
             penambah = -UsdJpy;
         }

         if(-AudJpy>penambah){
             penambah = -AudJpy;
         }

         if(-GbpJpy>penambah){
             penambah = -GbpJpy;
         }

         TempJpy[position] += penambah;

      }else{
        SetIndexStyle (4, DRAW_LINE,STYLE_SOLID,0,clrNONE);// Line style
      }

      if(position==t){

         Usd[t] = TempUsd[t];
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

       return 0;
     }

      position--;
   }

}