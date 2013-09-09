
/***************************************/
/*           saving outcomes           */
/***************************************/


data RPB; set accumulate_conditions;
	keep condition replication theta mean Nj max min range stdev;

proc means data=RPB mean noprint;
	var mean range stdev theta;
	class condition;
	output out=conditions_means;
run;
data conditions_means; set conditions_means (firstobs=2);
	drop _type_ _freq_;
	if _STAT_='N' or _stat_='MIN' or _stat_='MAX' or _stat_='STD' then delete;
run;
data conditions_means; set conditions_means (firstobs=2);
run;


data RPBcalculation; set conditions_means;
	drop _stat_;
	RPBstat=(mean-theta)/theta;
	RPBstat=round(RPBstat,.001);
	mean=round(mean,.001);
	range=round(range,.01);
	stdev=round(stdev,.0001);
run;



data collect.RPBs; set work.RPBcalculation;
run;


PROC EXPORT DATA= COLLECT.RPBS 
            OUTFILE= "C:\Users\Austin Mulloy\Documents\meta-analysis of ss data\pnd\collection\RPBs.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
