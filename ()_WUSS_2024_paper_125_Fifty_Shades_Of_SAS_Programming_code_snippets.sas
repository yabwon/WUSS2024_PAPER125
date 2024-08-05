
/***************************************************************************************************\
                                                                                                     
                                   Paper 125-2024                                                    
                                                                                                     
          ______ _  __ _            _____ _               _                    __                    
         |  ____(_)/ _| |          / ____| |             | |                  / _|                   
         | |__   _| |_| |_ _   _  | (___ | |__   __ _  __| | ___  ___    ___ | |_                    
         |  __| | |  _| __| | | |  \___ \| '_ \ / _` |/ _` |/ _ \/ __|  / _ \|  _|                   
         | |    | | | | |_| |_| |  ____) | | | | (_| | (_| |  __/\__ \ | (_) | |                     
         |_|    |_|_|  \__|\__, | |_____/|_| |_|\__,_|\__,_|\___||___/  \___/|_|                     
                            __/ |                                                                    
                           |___/                                                                     
   _____          _____                                                       _                      
  / ____|  /\    / ____|                                                     (_)                     
 | (___   /  \  | (___    _ __  _ __ ___   __ _ _ __ __ _ _ __ ___  _ __ ___  _ _ __   __ _          
  \___ \ / /\ \  \___ \  | '_ \| '__/ _ \ / _` | '__/ _` | '_ ` _ \| '_ ` _ \| | '_ \ / _` |         
  ____) / ____ \ ____) | | |_) | | | (_) | (_| | | | (_| | | | | | | | | | | | | | | | (_| |         
 |_____/_/    \_\_____/  | .__/|_|  \___/ \__, |_|  \__,_|_| |_| |_|_| |_| |_|_|_| |_|\__, |         
                         | |               __/ |                                       __/ |         
                         |_|              |___/                                       |___/          
                                                                                                     
                                                                                                     
                                                                                                     
                    or 53 (+3) Syntax Snippets for a Table Look-up Task,                             
                     or How to Learn SAS by Solving Only One Exercise!                               
                                                                                                     
                                                                                                     
      by                                                                                             
                                                                                                     
      Bartosz Jabłoński - yabwon/Warsaw University of Technology                                     
      and                                                                                            
      Quentin McMullen - Siemens Healthineers                                                        
                                                                                                     
                                                                                                     
      WUSS 2024 Conference, Sacramento, California                                                   
                                                                                                     
                                                                                                     
                                                                                                     
All articles referenced by the article are available at:                                             
                                                                                                     
https://pages.mini.pw.edu.pl/~jablonskib/SASpublic/WUSS2024_125/                                     
and                                                                                                  
https://github.com/yabwon/WUSS2024_PAPER125/                                                         
                                                                                                     
                                                                                                     
                                                                                                     
NOTE: Some of those code snippets *require* paths changes to adjust to your environment!             
                                                                                                     
\***************************************************************************************************/



resetline;
options msglevel=N nomprint nomlogic nosymbolgen nostimer fullstimer nosource2;
/*
  PREPARE THE DATA
*/
/* the data */
data _null_;
  file "%sysfunc(pathname(WORK))/small.txt";
  put "1 2 3 6 13 17 42 101 303 555 9999";
run;

/* you can use a standard SAS library, PostgreSQL is just as example */
libname PUB POSTGRES
  server="***.***.***.***"
  port=**** 
  user="****" 
  password="****" 
  database="****" 
  schema="****"
;

libname PUB list;

/*
proc delete data=PUB.BIG;
run;
*/
data PUB.BIG;
  call streaminit(42);
  do year = 2020 to 2024;
    do id = 12345 to 1 by -1;
      date = rand("integer", MDY(1,1,year), MDY(12,31,year));
      value = round(rand("uniform", 100, 200), 0.01);
      if ranuni(17) < 0.9 then output;
    end;
  end;
  format date yymmdd10. value dollar10.2;
  drop year;
run;



/* get the BIG DATA into SAS */
data WORK.BIG;
  set PUB.BIG;
run;

data WORK.BIG;
  set PUB.BIG;
  format date yymmdd10. value dollar10.2;
run;


libname PUB clear;


/* order the data */
proc sort data=WORK.BIG;
  by ID date value;
run;


/* know your data */
proc print data=WORK.BIG(obs=42);
run;

proc contents data=WORK.BIG varnum;
run;

proc means data=WORK.BIG;
run;

ods graphics / antialiasmax=45000;
proc sgplot data=work.big;
scatter x=date y=value / colorresponse=id
  markerattrs=(size=1 symbol=trianglefilled);
run;


/* look-up 0, PAINFULLY naive approach */
data WORK.RESULT0;
  set WORK.BIG;

  IF id = 1 
  or id = 2 
  or id = 3 
  or id = 6 
  or id = 13 
  or id = 17 
  or id = 42 
  or id = 101 
  or id = 303 
  or id = 555 
  or id = 9999 
  THEN OUTPUT;
run;
proc print;
run;

/* look-up 1, naive selection */
data WORK.RESULT1;
  set WORK.BIG;

  IF id in (1 2 3 6 13 17 42 101 303 555 9999) THEN OUTPUT;
  /* if id in (...); */
run;
proc print;
run;


/* look-up 2, naive selection, a bit faster */
data WORK.RESULT2;
  set WORK.BIG;
  WHERE id in (1 2 3 6 13 17 42 101 303 555 9999);

  /* set WORK.BIG(WHERE=( id in (...) )); */
run;
proc print;
run;


/* get the small DATA into SAS */
data WORK.small_wide;
  infile "%sysfunc(pathname(WORK))/small.txt";
  input ids1 - ids11; 
run;
proc print data=WORK.small_wide;
run;

/*
proc transpose 
  data=WORK.small_wide
  out=WORK.small_from_wide
;
var ids:;
run;
proc print data=WORK.small_from_wide;
run;
*/

data WORK.small;
  infile "%sysfunc(pathname(WORK))/small.txt";
  input ids @@; 
run;
proc print data=WORK.small;
run;




/* look-up 3, obvious way, SQL 1 - subquerry */
proc SQL;
  create table WORK.RESULT3 as
  select B.*
  from WORK.BIG as B
  where B.ID in (select s.IDS from WORK.small as s) 
  ;
quit;
proc print;
run;

/* look-up 4, obvious way, SQL 2 - Cartesian product */
proc SQL;
  create table WORK.RESULT4 as
  select B.*
  from WORK.BIG as B
      ,WORK.small as s
  where B.ID = s.IDS
  ;
quit;
proc print;
run;

/* look-up 5, obvious way, SQL 3 - JOIN */
proc SQL;
  create table WORK.RESULT5 as
  select B.*
  from WORK.BIG as B
       JOIN /* NATURAL JOIN */
       WORK.small as s
  ON B.ID = s.IDS /* <no clause> */
  ;
quit;
proc print;
run;


/* look-up 6, obvious way, MERGE */
data WORK.RESULT6;
  MERGE 
    WORK.BIG(in=B) 
    WORK.small(in=S RENAME=(IDS=ID))
  ;
  BY ID;
  if S and B;
  ;
run;
proc print;
run;



/* look-up 7, pointing observations, POINT= */
data WORK.RESULT7;
  SET WORK.BIG;

  do POINT = NOBS to 1 by -1;
    set WORK.small POINT=POINT NOBS=NOBS;
    if ID=IDS then 
      do; 
        OUTPUT WORK.RESULT7;
        GOTO exit;
    end;
  end;
  exit:
  drop IDS;
run;
proc print;
run;



/* look-up 8, conditional SET and ARRAY/VARIABLES LIST */
data WORK.RESULT8_A;

  IF 1 = _N_ then SET WORK.small_wide;
  ARRAY IDS[*] IDS:;
  /* ARRAY IDS[*] IDS1 - IDS11; */
  /* ARRAY IDS[*] IDS1 -numeric- IDS11; */
  DROP IDS:;

  SET WORK.BIG;

  if ID in IDS;
run;
proc print;
run;

data WORK.RESULT8_B;

  IF 1 = _N_ then SET WORK.small_wide;
  DROP IDS:;

  SET WORK.BIG;

  if WHICHN(ID, of IDS1-IDS11);
run;
proc print;
run;

data WORK.RESULT8_C;

  IF 1 = _N_ then SET WORK.small_wide;
  DROP IDS:;

  SET WORK.BIG;

  if FINDW(CATX("|", of IDS:), cats(ID),"|");
run;
proc print;
run;


filename f8D "%sysfunc(pathname(WORK))/small.txt";
data WORK.RESULT8_D; /* Q */

  infile f8D;
  if 1 = _N_ then input @@; 

  set WORK.BIG;
  if findw(_INFILE_, cats(ID), " ") then output;
run;
filename f8D clear;
proc print;
run;

filename f8E DUMMY;
data WORK.RESULT8_E; /* Q */

  FILE f8E;

  if 1 = _N_ then 
    do; 
      set WORK.small_wide;
      PUT IDS1-IDS11 @@; 
      drop IDS:;
      /*PUTLOG _FILE_;*/ /*!*/
    end;

  set WORK.BIG;
  if findw(_FILE_, cats(ID), " ") then output;
run;
filename f8E clear;
proc print;
run;




data WORK.RESULT8_F;

  IF 1 = _N_ then SET WORK.small_wide;
  DROP IDS:;

  SET WORK.BIG;

  if index (PEEKCLONG (ADDRLONG(IDS1), 88), put (ID, rb8.));


  IF 1 = _N_ then
    do;
    /*--------------------------------*/
      array X IDS:;
      do over X;
        A = ADDRLONG(X);
        Y = put (X, rb8.);
        put X=6. @12 Y= binary. / @12 a= $hex16. @32 a=;
      end;
      drop A Y;
    /*--------------------------------*/
    end;
run;
proc print;
run;







/* look-up 9, double SET and DOW-loop, and ARRAY */
data _null_;
  put NOBS=;
  call symputX("NOBS9",nobs,"G");
  stop;
  set WORK.small NOBS=NOBS;
run;

data WORK.RESULT9;
  ARRAY _IDS_[&NOBS9.] _TEMPORARY_; /* &NOBS9. = 11 <- from NOBS */

  do until(EOF_S);
    SET WORK.small end=EOF_S curobs=curobs;
    _IDS_[curobs] = IDS;
    drop IDS;
  end;

  do until(EOF_B);
    SET WORK.BIG end=EOF_B;
    if ID in _IDS_ then output;
  end;
stop;
run;
proc print;
run;





/* look-up 10, reading two data sets */
data _null_;
  put NOBS=;
  call symputX("NOBS10",nobs,"G");
  stop;
  set WORK.small NOBS=NOBS;
run;

data WORK.RESULT10;
  ARRAY _IDS_[&NOBS10.] _TEMPORARY_; /* &NOBS10. = 11 <- from NOBS */

  SET WORK.small(in=S) WORK.BIG curobs=curobs;
  if S then _IDS_[curobs] = IDS;
  else
    if ID in _IDS_ then output;

  drop ids;
run;
proc print;
run;






/* look-up 10, interleaving SET */
data WORK.RESULT10_A;

  SET 
    WORK.small(in=S RENAME=IDS=ID) 
    WORK.BIG(in=B)
  ;
  BY ID;
  
  if S and FIRST.ID then _check+ID;
  if B and _check=ID then output;
  if LAST.ID then _check=.;

  drop _:;
run;
proc print;
run;


data WORK.RESULT10_B; /* Q */

  DO UNTIL(last.id);
    set 
      WORK.small(in=S RENAME=IDS=ID)
      WORK.BIG(in=B)
    ;
    by ID;

    if FIRST.ID then _check=S;
    if B and _check then output;
  END; 

  drop _:;
run ;








/* look-up 11, DOW-loop */

/* (extra assumption that all IDs exist in BIG) */
data WORK.RESULT11_A;

  SET WORK.small;
  drop IDS;

  do until(last.ID and ID=IDS);
    SET WORK.BIG;
    by ID;
    if ID = IDS then output;
  end;
run;
proc print;
run;

/* (NO extra assumption that all IDs exist in BIG) */
/* options mergenoby=nowarn; */
data WORK.RESULT11_B;  /* Q */
  SET WORK.small;

  do until(nextID>IDS) ;
    MERGE 
      WORK.BIG 
      WORK.BIG(FIRSTOBS=2 keep=ID rename=(ID=nextID))
    ;
    if ID=IDs then output;
  end;
  put _all_;

  drop IDS nextID;
run;
/* options mergenoby=error; */
proc print;
run;




/* look-up 12, User Defined Format */
proc format;
  VALUE myFormat
    1, 2, 3, 6, 13, 17, 42, 101, 303, 555, 9999 = 'Y'
    OTHER = "N"
    ;
run;

data WORK.RESULT12;
  SET WORK.BIG;
  where put(ID,myFormat.) = "Y";
run;
proc print;
run;


/* look-up 13, User Defined Format from data */
data input_control_SAS_data_set;
  set WORK.small END=EOF;
  rename IDS=START;
  FMTNAME="myFormatFromData";
  LABEL="Y";
  TYPF="F";
  output;
  IF EOF;

  LABEL="N";
  HLO="O";
  output;
run;

proc format CNTLIN=input_control_SAS_data_set;
run;

data WORK.RESULT13;
  SET WORK.BIG;
  where put(ID,myFormatFromData.) = "Y";
run;
proc print;
run;

/*
proc format LIB=WORK;
  select myFormat myFormatFromData;
run;
*/

/* look-up 14 A, ARRAY and direct addressing */
options symbolgen;
data _null_;
  set WORK.small END=EOF;
  retain min max;
  max = max(max, IDS);
  min = min(min, IDS);
  if EOF; 
  put max= min=;
  call symputX("max14",max,"G");
  call symputX("min14",min,"G");
run;

data WORK.RESULT14_A;

  ARRAY T[&min14.:&max14.] _temporary_;
  do until(EOF_S);
    set WORK.small end=EOF_S;
    T[IDS] = 1;
  end;

  do until(EOF_B);
    SET WORK.BIG end=EOF_B;
    if &min14. <= ID <= &max14. then
      if T[ID] then output; /* this is direct addressing */
  end;
stop;
drop IDS;
run;
proc print;
run;


/* look-up 14 B, BITMAP and direct addressing */
%let M = 32; /* bitmap size (32 bits) */
%let KL = 1; /* ID (key) low value */
%let KH = 12345; /* ID (key) high value */
%let R = %eval (&KH - &KL + 1); /* keys range */
%let D = %sysfunc (ceil (&R / &M)); /* dim of bitmap array*/

%put &=M. &=KL. &=KH. &=R. &=D.;

data WORK.RESULT14_B ;
  /* Initialization of bitmap and bitmask */
  array BM [&D] _temporary_ (&D.*0);
  array bitmask [0:&M] _temporary_;
  do B = 0 to &M;
    bitmask[B] = 2**B;
  end;

  /* Mapping IDs to Bitmap */
  do until(EOF_S);
    set WORK.small end=EOF_S;

    C = int (divide (IDS - 1, &M)) + 1; /* find bitmap cell */
    B = 1 + mod (IDS - 1, &M); /* find bit in cell */
    BM[C] = BOR (BM[C], bitmask[B - 1]); /* activate bit */
    N_mapped + 1;
  end;

  /* Searching IDs in Bitmap */
  do until(EOF_B);
    SET WORK.BIG end=EOF_B;
      C = int (divide (ID - 1, &M)) + 1;
      B = 1 + mod (ID - 1, &M);
      ActiveBit = BAND (BM[C], bitmask[B - 1]) ne 0;
      N_found + ActiveBit;
      if ActiveBit then output;
  end;

  put N_Mapped= N_found=; /* Number of mapped and found values */
  stop;
keep ID date value;
run;
proc print;
run;





/* look-up 15, HASH TABLES */
data WORK.RESULT15;

  if 0 then set WORK.small;
  DECLARE HASH H(dataset:"WORK.small");
  H.defineKey("IDS");
  /* H.defineData("IDS"); */
  H.defineDone();

  do until(EOF_B);
    SET WORK.BIG end=EOF_B;

    if 0=H.CHECK(key:ID) then output;
  end;
stop;
drop IDS;
run;
proc print;
run;


/* look-up 16, naive selection - but smart, v1 */
/* macro variable with values list */
proc SQL noprint;
  select distinct IDS
  into :IDS16_A separated by " "
  from WORK.small
  ;
quit;

data WORK.RESULT16_A;
  set WORK.BIG;
  WHERE id in (&IDS16_A.);
run;
proc print;
run;

/* macro variable array */
proc SQL noprint;
  select distinct IDS
  into :IDS16_B1- 
  from WORK.small
  ;
  %let N16B=&sqlobs.;
quit;

%macro loop16(n);
  %do n = 1 %to &n.;
    &&IDS16_B&n.
  %end;
%mend;

data WORK.RESULT16_B;
  set WORK.BIG;
  WHERE id in (
      %loop16(&N16B.)
    );
run;
proc print;
run;




/* look-up 17, naive selection - but smart, v2 */
data _null_;
  call execute('
  data WORK.RESULT17;
    set WORK.BIG;
    WHERE id in (
  ');
  
  do until(EOF);
    set WORK.small end=EOF;
    call execute(IDS); 
  end;

  call execute('
  );
  run;
  ');
stop;
run;
proc print;
run;


/* look-up 18, naive selection - but smart, v3 */
filename F18 TEMP;

data _null_;
  file F18 ;
  put 'WHERE id in (';
  
  do until(EOF);
    set WORK.small end=EOF;
    put IDS; 
  end;

  put ');';
stop;
run;

data WORK.RESULT18;
  set WORK.BIG;
  %include F18 / source2;
run;
filename F18 CLEAR;
proc print;
run;


/* look-up 19, naive selection - but smart, v4 */
data _null_;
  length text $ 32767;

  text = 'data WORK.RESULT19; set WORK.BIG; WHERE id in (';
  
  do until(EOF);
    set WORK.small end=EOF;
    text =  catx(" ", text, IDS); 
  end;

  text =  catx(" ", text, "); run;"); 

  put text;
  rc = DoSubL(text);
stop;
run;
proc print data = WORK.RESULT19;
run;


/* look-up 20, User Defined Functions, v1 */
proc FCMP outlib=WORK.F20.P;
  function F20(x);
    array A[1] / NOSYMBOLS;
    static A XX;

    if NOT xx then
      do;
        rc = READ_ARRAY("WORK.small", A, 'IDS');
        xx = 1;
      end;

    /* small is sorted so binary search is possible */
    l=1; h=dim(A);
    do while(l<=h);
      i = int((l+h)/2);
      if A[i] = x then return(1);
      else if A[i] < x 
           then l=i+1;
           else h=i-1;
    end;

    return(0);
  endfunc;
run;

options append=(cmplib=WORK.F20);

data WORK.RESULT20; 
  set WORK.BIG; 
  WHERE 1 = F20(id);
run;
proc print;
run;


/* look-up 21, User Defined Functions, v2 */
proc FCMP outlib=WORK.F21.P;
  function F21(IDS);
      DECLARE HASH H(dataset: "WORK.small");
      rc = H.defineKey("IDS");
      rc = H.defineDone();

    return(NOT H.CHECK());
  endfunc;
run;

options append=(cmplib=WORK.F21);

data WORK.RESULT21; 
  set WORK.BIG; 
  WHERE 1 = F21(id);
run;
proc print;
run;


/* look-up 22, INDEXED SET + KEY= + KEYRESET= */

proc datasets lib=WORK noprint;
  modify BIG;
    INDEX CREATE ID;  
  run;
/*
  modify BIG;
    INDEX delete ID;  
  run;
*/
quit;

data WORK.RESULT22;
  set WORK.small(rename=(IDS=ID));

  reset = 1;
  do while (NOT _iorc_);
    set WORK.BIG key=ID keyreset=reset;
    if NOT _iorc_ then output;
  end;
  _error_ = 0; _iorc_ = 0;
run;
proc print;
run;




/* look-up 23, MODIFY */

data WORK.RESULT23_A;
  set WORK.BIG(obs=0) WORK.small;
  ID = IDS;
  drop IDS;
run;
proc print;
run;

proc datasets lib=WORK noprint;
  modify RESULT23_A;
    index create ID;  
  run;
quit;

/*
proc datasets lib=WORK noprint;
  modify RESULT23_A;
    index delete ID;  
  run;
quit;
*/

data WORK.RESULT23_A;
  MODIFY WORK.RESULT23_A WORK.BIG;
  by ID;

  if _iorc_=0 then output;
  _error_ = 0; _iorc_ = 0;
run;
proc print data=WORK.RESULT23_A(where=(value)); /* ! */
run;




/* look-up 23 B, Integrity Constraints - CHECK with where condition */
proc SQL noprint;
  select distinct IDS
  into :IDS23_B separated by " "
  from WORK.small
  ;
quit;

data WORK.RESULT23_B;
  stop;
  set WORK.BIG;
run;

proc datasets lib=WORK noprint;
  modify RESULT23_B;
    IC create IC_of_type_check = check(where=(ID in (&IDS23_B.)));  
  run;
quit;

options msglevel=i;
proc append 
  base=WORK.RESULT23_B 
  data=WORK.BIG;
run;


/* look-up 23 C, Integrity Constraints - FOREIGN KEY */
proc SQL noprint;
  create table work.IC_PK_small as
  select distinct IDS
  from WORK.small
  ;
  create unique index IDS on work.IC_PK_small(IDS);
  alter table work.IC_PK_small add primary key (IDS);;
quit;

data WORK.RESULT23_C;
  stop;
  set WORK.BIG;
run;

proc datasets lib=WORK noprint;
  modify RESULT23_C;
    IC create IC_of_type_foreignkey =
      FOREIGN KEY (ID) REFERENCES work.IC_PK_small ON UPDATE RESTRICT;  
  run;
quit;

options msglevel=i;
proc append 
  base=WORK.RESULT23_C 
  data=WORK.BIG;
run;




/* look-up 24, OPEN + FETCH */
data WORK.RESULT24;

  set WORK.BIG(obs=0) WORK.small;

  did = OPEN('WORK.BIG(where=(id=' !! put(IDS,best32.) !! '))');
  
  if did then
    do;
      CALL SET(did);
      do while (0=FETCH(did));
        output;
      end;
    end;
  did = CLOSE(did);
run;
proc print;
run; 



/* look-up 25, PROC DS2 */
PROC DS2;
  data WORK.RESULT25_A / overwrite=yes;
    method run();
      SET {select B.*
           from WORK.BIG as B
           join
           WORK.small as s
           on B.ID = s.IDS
          };
      output;
    end;
  enddata;
  run;

  data WORK.RESULT25_B / overwrite=yes;
    method run();
      MERGE 
        WORK.BIG(in=B) 
        WORK.small(in=S rename=(IDS=ID))
      / RETAIN /* ! */
      ;
      BY ID;
      if (B and S ) then output;
    end;
  enddata;
  run;

  data WORK.RESULT25_C/ overwrite=yes;
    declare double IDS rc;
    declare package hash H(8,'WORK.small');
    drop IDS rc;

    method init();
      rc = H.defineKey('IDS');
      /*rc = H.defineData('IDS');*/
      rc = H.defineDone();
    end;

    method run();
      set WORK.BIG;
      if (0 = H.check([ID])) then output;
    end;

  enddata;
  run;
QUIT;
proc print data=WORK.RESULT25_A;
run;
proc print data=WORK.RESULT25_B;
run; 
proc print data=WORK.RESULT25_C;
run; 


/* look-up 26, PROC FedSQL; */
PROC FedSQL;
  drop table WORK.RESULT26 FORCE;
  create table WORK.RESULT26 as 
    select B.*
    from WORK.BIG as B
    join
    WORK.small as s
    on B.ID = s.IDS
;
QUIT;
proc print data=WORK.RESULT26;
run; 





/* look-up 27, PROC IML; */
PROC IML;
  use WORK.BIG;
  read all var {id date value}; 
  close WORK.BIG;

  use WORK.small;
  read all var {ids}; 
  close WORK.small;

  TF = LOC(ELEMENT(ID, IDS));
  
  id = id[TF];

  date = date[TF];
  mattrib date format=yymmdd10.;

  value = value[TF];
  mattrib value format=dollar10.2;

  create WORK.RESULT27 var {"id" "date" "value"};
  append from id date value;
  close WORK.RESULT27;
QUIT;
proc print;
run;





/* look-up 28, PROC TRANSPOSE and APPEND; */

proc sort 
  data = WORK.BIG
  out  = WORK.BIGSORTED28
  ;
  by date id value;
run;

proc transpose 
  data = WORK.BIGSORTED28
  out  = WORK.BIGTRANSPOSED28(drop=_:)
  prefix = ID
  ;
  by DATE;
  id ID;
  var value;
run;

proc transpose 
  data = WORK.small
  out  = WORK.smallTRANSPOSED28(drop=_:)
  prefix = ID
  ;
  var ids;
  id ids;
run;

data WORK.smallTRANSPOSED28;
  date = .; format date yymmdd10.;
  set WORK.smallTRANSPOSED28;
  stop;
run;

filename D DUMMY;
proc printto log=D;run;
PROC APPEND
  BASE = WORK.smallTRANSPOSED28
  DATA = WORK.BIGTRANSPOSED28
  FORCE;
RUN;
proc printto;run;
filename D clear;

proc transpose 
  data = WORK.smallTRANSPOSED28
  out  = WORK.RESULT28(where=(value1))
  name = ID
  prefix = value
  ;
by DATE;
var id:;
run;


proc sort 
  data = WORK.RESULT28
  SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON)
  ;
by id date value1;
run;
proc print;
run;


/* ! */
data WORK.RESULT28;
  length newID 8;
  set WORK.RESULT28;
  newID = input(compress(ID, , "KD"), best32.);
  drop ID;
  rename newID=ID value1=value;
run;
proc print;
run;


/* look-up 29, PROC TABULATE and MEANS - CLASSDATA= */
proc sort
  data=WORK.BIG
  out=WORK.SORTED29
  ;
  by date id value;
run;

ods select NONE; filename D DUMMY; proc printto log=D;run;

proc tabulate 
  CLASSDATA=WORK.small(rename=(IDS=ID))
  EXCLUSIVE
  data=WORK.SORTED29
  OUT=WORK.RESULT29_A(drop=_: rename=value_sum=value where=(.z<value))
  ;
class ID;
by DATE;
var value;
table ID,value*sum=" ";
run;

ods select ALL; proc printto;run; filename D clear;
proc print;
run;

data WORK.BIGview29 / view = WORK.BIGview29; /* Q */
  set WORK.BIG; 
  _obs = _n_;
run ;

proc means 
  CLASSDATA=WORK.small(rename=(ids=id)) 
  EXCLUSIVE 
  data=WORK.BIGview29 
  noprint nway
  ;
class ID;
by _obs date;
var value;
OUTPUT 
  out=WORK.RESULT29_B(drop=_: where=(not missing(value))) 
  sum=;
run ;
proc print;
run;



/* look-up 30, unique values */

%let maxDup=7; /* Q & B */
data WORK.smallDup / view = WORK.smallDup;
  set WORK.small;
  do d = 1 to &maxDup.;
    output;
  end;
  rename IDS=ID;
run;

data WORK.BIGview30 / view = WORK.BIGview30; /* Q */
  set WORK.BIG;
  by ID;

  if first.ID then d=0;
  d+1;
run;
 
data WORK.BSv30 / view = WORK.BSv30;
  set WORK.smallDup WORK.BIGview30 ;
run ;

proc sort 
  NODUPKEY 
  data   = WORK.BSv30
  out    = _null_
  DUPOUT = WORK.RESULT30(drop=d);
  by id d;
run ;

proc print data=WORK.RESULT30;
run; 






/* look-up 31, unique markers in macro variables */
%let uniqueMarker=%sysfunc(datetime(),hex16.);
%put &=uniqueMarker.;
data _null_;
  set WORK.small;
  call symputX(cats("_31_&uniqueMarker._",IDS),"I am here","G");
run;
%put _user_;

data WORK.RESULT31;
  set WORK.BIG;
  where symexist(cats("_31_&uniqueMarker._",ID));
run;

/*
data WORK.eXclude_RESULT31_1A;
  set WORK.BIG;
  where symget(cats("_31_&uniqueMarker._",ID)) is not null;
run;

data WORK.eXclude_RESULT31_1B;
  set WORK.BIG;
  if NOT (symget(cats("_31_&uniqueMarker._",ID)) = " ");
run;

filename f31 DUMMY;
proc printto log=f31;
run;
data WORK.eXclude_RESULT31_2;
  set WORK.BIG;
  where resolve(cats('&',"_31_&uniqueMarker._",ID)) = "I am here";
run;
proc printto;
run;
filename f31 clear;

proc print data=WORK.eXclude_RESULT31_2(obs=47);
run;
*/






/* look-up 32, "foreign languages" - R */

proc options option=RLANG;
run;
options set=R_HOME="/******/R/R-4.3.1\";
PROC IML;
  /* https://support.sas.com/kb/70/253.html */ /* !! */
  call ExportDataSetToR("WORK.BIG", "BIG");
  call ExportDataSetToR("WORK.small", "small");
  submit / R;
     RESULT32 <- BIG[BIG$id %in% small$ids,1:3]
     head(RESULT32)
     tail(RESULT32)
  endsubmit;
  call ImportDataSetFromR("WORK.RESULT32", "RESULT32");
QUIT;
proc print data=WORK.RESULT32;
run;





/* look-up 33, "foreign languages" - Python */

options set=MAS_M2PATH="/******/SAShome/SASFoundation/9.4/tkmas/sasmisc/mas2py.py";
options set=MAS_PYPATH="/******/Python/Python312/python.exe";

/* Execute in command line:

cd /******/Python/Python312
python -m pip install pandas saspy
*/

/* Setup SASPY.PY config file, located for example in:

/******/Python/Python312/Lib/site-packages/saspy/sascfg.py

For local:

default  = {'saspath'  : '/******/SAShome/SASFoundation/9.4/',
            'encoding': 'utf8',
            'java' : '/******/SAShome/SASPrivateJavaRuntimeEnvironment/9.4/jre/bin/java'
           }
*/

PROC FCMP;
length libpath fileBIG filesmall fileresult33 $ 512 output $ 42;
libpath = pathname('WORK');
fileBIG   = catx("/", libpath, 'big.sas7bdat');
filesmall = catx("/", libpath, 'small.sas7bdat');
fileresult33 = catx("/", libpath, 'result33.csv');

declare object py(python);
submit into py;
def lookup33(BIGpath, smallpath, CSVpath, libpath):
  """Output: outputKey"""
  import pandas
  import saspy

  #/* read data sets to pandas data frames */
  BIGdf = pandas.read_sas(BIGpath)
  smalldf = pandas.read_sas(smallpath)

  RESULT33 = BIGdf.merge(smalldf, left_on='id', right_on='ids', how='inner')

  #/* create CSV file for import */
  RESULT33[["id","date","value"]].to_csv(CSVpath, index=False)

  #/* create data set with SASPY */
  sas = saspy.SASsession(cfgname='default')
  sas.saslib(libref = 'out', path = libpath)

  dataSet = sas.dataframe2sasdata(
    df = RESULT33[["id","date","value"]],
    libref = 'out',
    table = 'RESULT33'
    )
  sas.endsas()

  return dataSet.table
endsubmit;
rc = py.publish();
rc = py.call('lookup33', fileBIG, filesmall, fileresult33, libpath);
output = py.results['outputKey']; /* = outputValue */

put "output:" output;
RUN;
/*
data csv_version_of_result33;
  infile "%sysfunc(pathname(WORK))/result33.csv" dlm="," firstobs=2;
  input @;
  put _infile_;
  input @1 id date yymmdd10. value;
  format date yymmdd10.;
run;
*/
proc import 
  file="%sysfunc(pathname(WORK))/result33.csv"
  out=csv_version_of_result33
  dbms=csv
  replace;
run;
proc print data=csv_version_of_result33;
run;

proc print data=RESULT33;
run;




/* look-up 34, "foreign languages" - LUA */

Proc LUA restart;
submit;
  --- /* get data from SMALL */
  local small = {}
  local dsid = sas.open("WORK.small")
  for row in sas.rows(dsid) do
    for n,v in pairs(row) do
      if n == "ids" then 
        small[#small+1] = v
      end;
    end
  end
  sas.close(dsid)
  print(table.tostring(small))
  print(type(small))
    
  --- /* load BIG */
  local BIG = sas.read_ds("WORK.BIG")
  print(type(BIG))

  local result34 = {}
  print(table.tostring(result34))

  local cnt = 0
  local find = 0

  --- /* loop over rows of BIG and ... */
  for _,rowBIG in ipairs(BIG) do
    cnt = cnt + 1
    --- /* ... check if value of ID in in small */
    if (table.contains(small, rowBIG.id)) then 
      find = find + 1
      vars = {}
        vars.id=rowBIG.id
        vars.date=rowBIG.date
        vars.value=rowBIG.value
      result34[#result34+1] = vars 
    end
  end;
  print ("cnt=", cnt)
  print ("find=", find)

  -- /*write LUA table to SAS data set */
  sas.write_ds(result34, "work.result34")

  print(table.tostring(result34))
endsubmit;
run;
proc print data=RESULT34;
  format date yymmdd10.;
run;


/* look-up 35, SAS indexes and user defined indexes */
data WORK.BIG2 WORK.BIG3;
  set WORK.BIG;
run;

data work.userDefinedIndex(
      index=(key) 
      keep=key start end dataSet
      );
  set WORK.BIG /* WORK.BIG2 WORK.BIG3 ... - multiple data sets */
      curobs=curobs indsname=indsname end=eof
  ;

  lag_co   = lag(curobs);
  lag_INDS = lag(indsname);
  lag_ID   = lag(id);
  newDS    = indsname NE lag_INDS;
  newBY    = id NE lag_ID;

  if EOF OR ((newDS OR newBY) AND 1 < _N_) then
    do;
      key     = coalesce(lag_ID,ID);
      dataSet = coalescec(lag_INDS,indsname);
      start   = (start<>1);
      end     = coalesce(lag_co,curobs);
      output userDefinedIndex;
      start=.;
      start+curobs;
    end;
run;
/* proc print data=userDefinedIndex(firstobs=12340 obs=12350);
run; */

proc sql noprint;
  select IDS 
  into :IDS separated by " "
  from work.small
  ;                                                                 
quit;

options msglevel=i;
data _null_;
  call execute('data RESULT35; set');
  do until(eof);
    set work.userDefinedIndex end=EOF;
    where KEY in (&IDS.);
    call execute(catx(' ',dataSet,'(firstobs=',start,'obs=',end,')'));
  end;
  call execute('open=defer;run;');
stop;
run;
options msglevel=n;








/* look-up 36, SAS macro indirect referencing */
data _null_;
  set WORK.BIG curobs=co;
  by ID;
  if first.ID then call symputX(cats("_st36_",ID),co,"G");
  if last.ID  then call symputX(cats("_en36_",ID),co,"G");
run;

data _null_;
  set WORK.small end=eof;
  call symputX(cats("_i36_",_N_),IDS,"G");
  if eof then call symputX("_n36_",_N_,"G");
run;

%macro lookup36();
data RESULT36; 
  set
    %local i;
    %do i = 1 %to &_n36_.;
       WORK.BIG(firstobs=&&&&_st36_&&_i36_&i obs=&&&&_en36_&&_i36_&i) 

    %end;
  open=defer;
run;

%mend lookup36;

options mprint symbolgen mlogic;
%lookup36()
options nomprint nosymbolgen nomlogic;

proc print data=RESULT36;
run;



%let VeryImportantMessage=This, is, WUSS!!!;

%let T1=Very;
%let T2=Important;
%let T3=Message;

%let letter=T;
%let one=1;
%let two=2;
%let three=3;



%put &&&&&&&letter&one&&&letter&two&&&letter&three;

/*
How the resolution goes?
{} - are added to indicate grouping

&&&&&&&letter&one&&&letter&two&&&letter&three

first grouping and resolving:
{&&}{&&}{&&}{&letter}{&one}{&&}{&letter}{&two}{&&}{&letter}{&three}

result:
{&}{&}{&}{T}{1}{&}{T}{2}{&}{T}{3}

second grouping and resolving:
{&&}{&T1}{&T2}{&T3}

result:
{&VeryImportantMessage}

third grouping and resolving gives the result:
This, is, WUSS!!!
*/









/* look-up 37, SAS macro recursion for binary search */

/* PROC FUNCTN - not working motivation*/
/*
resetline;
DATA work.functionData; 
  set work.small; 
  rename IDS=arg;
  value=1;
run;

PROC SORT data=work.functionData; 
  BY arg; 
run;

PROC FUNCTN 
  DATA=work.functionData
  NAME=myFunc 
  DDNAME=work
  TYPE=1
; 
  ID value; 
  VAR arg;
run;

DATA work.RESULT37;
  set work.BIG;
  if myFunc(ID);
run;
*/


/* expected result */
/*
data work.RESULT37;
  set work.BIG;
    if (ID < 17) then do;
      if (ID < 3) then do;
        return=( ID=1 | ID=2 );
      end;
      else if (ID = 3) then return=(1);
      else if (ID > 3) then do;
        return=( ID=6 | ID=13 );
      end;
    end;
    else if (ID = 17) then return=(1);
    else if (ID > 17) then do;
      if (ID < 303) then do;
        return=( ID=42 | ID=101 );
      end;
      else if (ID = 303) then return=(1);
      else if (ID > 303) then do;
        return=( ID=555 | ID=9999 );
      end;
    end;
  if return;
run;
*/

/* SAS macro recursion for binary search */
%macro binSrch(var,list,sep==)/minoperator;
%local l h i j v;
%let l=1;
%let h=%sysfunc(countw(%superq(list),%str( )));
%let i = %eval((&l.+&h.)/2);
%let v = %scan(&list.,&i.,%str( ));

%if 1 = &h. %then
  %do;
    return&sep.( &var.=&list. );
  %end;
%else %if 2 = &h. %then
  %do;
    return&sep.( &var.=%scan(&list.,1,%str( )) | &var.=%scan(&list.,-1,%str( )) );
  %end;
%else %if NOT %sysevalf(%superq(v)=,boolean) %then
  %do;
    if (&var. < &v.) then 
      do;
        %binSrch(&var.,%do j=&l. %to %eval(&i-1); %scan(&list.,&j.,%str( ))  %end;)
      end;
    else if (&var. = &v.) then return&sep.(1);
    else if (&var. > &v.) then 
      do;
        %binSrch(&var.,%do j=%eval(&i+1) %to &h.; %scan(&list.,&j.,%str( ))  %end;)
      end;
  %end;
%mend binarySearch;

options mprint;

data work.RESULT37;
  set work.BIG;
  %binSrch(ID, 1 2 3 6 13 17 42 101 303 555 9999)
  if return;
  drop return;
run;
proc print;
run;








/* some extras */

filename packages "/***/***/***/";
%include packages (SPFinit.sas);

options nosymbolgen;

/* look-up 97, naive selection, with basePlus */
%loadPackage(basePlus)

filename f97 "%workPath()/small.txt";
data WORK.RESULT97;
  set WORK.BIG;
  WHERE id in (%minclude(f97));
run;
proc print;
run;
filename f97 clear;




/* look-up 98, naive selection, with Macro Variable Arrays */
%loadPackage(macroArray)

%array(ds=WORK.small,vars=IDS|IDS98_,macarray=Y)
%put %IDS98_(1) %IDS98_(5) %IDS98_(11);
/*%put _user_;*/

data WORK.RESULT98;
  set WORK.BIG;
  WHERE id in (%do_over(IDS98_));
run;
proc print;
run;


/* look-up 99, SQLinDS - Macro Function Sandwich approach */
%loadPackage(SQLinDS)

data WORK.RESULT99;
  SET %SQL(
    select B.*
    from WORK.BIG as B
        ,WORK.small as s
    where B.ID = s.IDS
  );
run;
proc print;
run;






/* short summary */

options obs=1;
data list;
  set WORK.RESULT: indsname=i;
  indsname=i;
  keep indsname;
run;
options obs=MAX;
proc sort 
  data = list
  SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON)
  ;
by i:;
run;
proc print;
run;

data _null_;
    point = rand("integer",1,NOBS);
    set list POINT=point NOBS=NOBS;

    call symputX("EXAMPLE_DATA",indsname,"G");
    stop;
run;

%put "Results from &EXAMPLE_DATA.";
title "Results from &EXAMPLE_DATA.";
proc tabulate data=&EXAMPLE_DATA.;
;
class ID;
var value;
  table id,value*(sum n mean);
run;
title;


/*
proc contents noprint 
  data=work._all_ 
  out=META_DATA(where=(memname like 'RESULT%'))
;
run;
*/
