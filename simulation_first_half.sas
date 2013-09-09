options formdlim='=' mprint mlogic;
proc printto log='C:\Users\Austin Mulloy\Desktop\junk.log';
run;


%macro cases (condition=,Nj=,Ni=,cutoff=,repl=,dist_aucor=,theta=);
%let Ni1=%eval(&Ni+1);

%do r=1 %to &repl;
%do j=1 %to &Nj;
data numbers;										/*create session numbers (Ni's) for individual files*/
	array sessions session1-session&Ni;
		do i=1 to &Ni;
		sessions(i)=(i);
		end;
	output;
	keep session1-session&Ni;
	run;
proc transpose out=numbers;
run;
data numbers; set numbers;							
	replication=&r;
	Nj=&j;											/*create individual numbers (Nj) for individual files*/
	Ni=col1;
	drop col1 _name_;
run;

data data_points; set numbers;						/*generate data points for an individual*/
	if &dist_aucor=1 then do;							/*specify distribution*/
		y=rannor(-1);
		x='x';
		output;
		end;
	if &dist_aucor=2 then do;
		y=.5*rangam(-1,3);
		x='x';
		output;
		end;
	if &dist_aucor=3 then do;
		y=.5*rangam(-1,3);
		x='x';
		output;
		end;
run;


proc append base=accumulate_data_points data=data_points(cntllev=member);
run;												/*accumulate individual's data for a meta-analysis*/

data data_points; set data_points;					/*at individual level, calculate PND*/
	if &dist_aucor>2.1 then
	if y>&cutoff then delete;
	if &dist_aucor<2.1 then
	if y<&cutoff then delete;
data insurance;
	replication=.;
	Nj=.;
	Ni=.;
	y=.;
	x='x';
run;
data data_points; set data_points insurance;
run;
	
proc freq data=data_points noprint;
	tables x/out=calculator;
run;
data calculator; set calculator;
	keep count PND rep condition;
	rep=&r;
	condition=&condition;
	PND=(count-1)/&Ni*100;
run;
data calculator; set calculator;
	drop count;
proc append base=accumulate_PNDs data=calculator (cntllev=member);
run;												/*accumulate PNDs for a single meta-analysis*/

%end;												/*end loop for individuals data, single meta-analysis set complete*/
													/*calculate descriptive stats on PND distribution*/

proc append base=accumulate_PNDs&condition data=accumulate_PNDs (cntllev=member);
run;

data accumulate_PNDs; set accumulate_PNDs;
	theta=&theta;
	error_j=abs(PND-theta);
	if error_j ge 0 and error_j<5 then pgzero_j=1;
	else pgzero_j=0;
	if error_j ge 5 and error_j<10 then pgfive_j=1;
	else pgfive_j=0;
	if error_j ge 10 and error_j<15 then pgten_j=1;
	else pgten_j=0;
	if error_j ge 15 and error_j<20 then pgfifteen_j=1;
	else pgfifteen_j=0;
	if error_j ge 20 then pgtwenty_j=1;
	else pgtwenty_j=0;
run;
proc means data=accumulate_PNDs mean range stddev sum noprint;
	var PND error_j pgzero_j pgfive_j pgten_j pgfifteen_j pgtwenty_j;
	output out=replic_stats stddev(PND)=stdev_PND_j range(PND)=range_PND_j
		mean(PND)=PND_k
		sum(pgzero_j)=count_pgzero_j sum(pgfive_j)=count_pgfive_j sum(pgten_j)=count_pgten_j sum(pgfifteen_j)=count_pgfifteen_j sum(pgtwenty_j)=count_pgtwenty_j
		mean(error_j)=mean_error_j stddev(error_j)=stdev_error_j range(error_j)=range_error_j;
run;
data replic_stats; set replic_stats;
	condition=&condition;
	replication=&r;
	theta=&theta;
	error_k=abs(PND_k-theta);
	pgzero_j=count_pgzero_j/&Nj;
	pgfive_j=count_pgfive_j/&Nj;
	pgten_j=count_pgten_j/&Nj;
	pgfifteen_j=count_pgfifteen_j/&Nj;
	pgtwenty_j=count_pgtwenty_j/&Nj;
	drop _type_ _freq_ count_pgzero_j count_pgfive_j count_pgten_j count_pgfifteen_j count_pgtwenty_j;
run;

proc append base=accumulate_condition&condition /*data=repl_stats*/ (cntllev=member);
run;
proc delete data=accumulate_PNDs;
proc delete data=replic_stats;
run;

%end;											/*end replication, begin next replication*/

*proc append base=accumulate_conditions data=accumulate_condition&condition;
*run;

/***************************************/
/*           saving outcomes           */
/***************************************/


data prep&condition; set accumulate_condition&condition;
	keep condition replication theta PND_k range_PND_j stdev_PND_j mean_error_j range_error_j stdev_error_j error_k pgzero_j pgfive_j pgten_j pgfifteen_j pgtwenty_j;
run;
data prep&condition; set prep&condition;
	if error_k ge 0 and error_k<5 then pgzero_k=1;
	else pgzero_k=0;
	if error_k ge 5 and error_k<10 then pgfive_k=1;
	else pgfive_k=0;
	if error_k ge 10 and error_k<15 then pgten_k=1;
	else pgten_k=0;
	if error_k ge 15 and error_k<20 then pgfifteen_k=1;
	else pgfifteen_k=0;
	if error_k ge 20 then pgtwenty_k=1;
	else pgtwenty_k=0;	
run;
proc means data=prep&condition mean stddev range sum noprint;
	var theta PND_k range_PND_j stdev_PND_j mean_error_j range_error_j stdev_error_j error_k theta pgzero_j pgfive_j pgten_j pgfifteen_j pgtwenty_j pgzero_k pgfive_k pgten_k pgfifteen_k pgtwenty_k;
	class condition;
	output out=means_condition&condition mean(stdev_PND_j)=mean_stdev_PND_j mean(range_PND_j)=mean_range_PND_j
		mean(pgzero_j)=condition_pgzero_j mean(pgfive_j)=condition_pgfive_j mean(pgten_j)=condition_pgten_j 
		mean(pgfifteen_j)=condition_pgfifteen_j mean(pgtwenty_j)=condition_pgtwenty_j
		stddev(PND_k)=stdev_PND_k range(PND_k)=range_PND_k
		sum(pgzero_k)=count_pgzero_k sum(pgfive_k)=count_pgfive_k sum(pgten_k)=count_pgten_k sum(pgfifteen_k)=count_pgfifteen_k sum(pgtwenty_k)=count_pgtwenty_k
		mean(mean_error_j)=mean_error_j mean(stdev_error_j)=mean_stdev_error_j mean(range_error_j)=mean_range_error_j 
		mean(error_k)=mean_error_k stddev(error_k)=stdev_error_k range(error_k)=range_error_k mean(PND_k)=mean_PND_k
		mean(theta)=theta;
run;

data means_condition&condition; set means_condition&condition;
	drop _type_;
	*if _STAT_='N' or _stat_='MIN' or _stat_='MAX' or _stat_='STD' then delete;
	if condition=. then delete;
run;

data stats&condition; set means_condition&condition;
	RPBstat=(mean_PND_k-theta)/theta;
	RPBstat=round(RPBstat,.001);
	mean_PND_k=round(mean_PND_k,.001);
	mean_range_PND_j=round(mean_range_PND_j,.01);
	mean_stdev_PND_j=round(mean_stdev_PND_j,.001);
	mean_error_j=round(mean_error_j,.001);
	mean_range_error_j=round(mean_range_error_j,.001);
	mean_error_k=round(mean_error_k,.001);
	condition_pgzero_j=round(condition_pgzero_j,.001);
	condition_pgfive_j=round(condition_pgfive_j,.001);
	condition_pgten_j=round(condition_pgten_j,.001);
	condition_pgfifteen_j=round(condition_pgfifteen_j,.001);
	condition_pgtwenty_j=round(condition_pgtwenty_j,.001);
	mean_stdev_PND_j=round(mean_stdev_PND_j,.001);
	stdev_PND_k=round(stdev_PND_k,.001);
	mean_stdev_error_j=round(mean_stdev_error_j,.001);
	stdev_error_k=round(stdev_error_k,.001);
	pgzero_k=count_pgzero_k/&repl;
	pgfive_k=count_pgfive_k/&repl;
	pgten_k=count_pgten_k/&repl;
	pgfifteen_k=count_pgfifteen_k/&repl;
	pgtwenty_k=count_pgtwenty_k/&repl;
	drop _stat_ PND_k count_pgzero_k count_pgfive_k count_pgten_k count_pgfifteen_k count_pgtwenty_k;
run;


data collect.stats&condition; set work.stats&condition;
run;
data collect.accumulate_condition&condition; set work.accumulate_condition&condition;
run;

PROC EXPORT DATA= COLLECT.stats&condition 
            OUTFILE= "C:\Users\Austin Mulloy\Documents\meta-analysis of ss data\pnd\collection\stats&condition..csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
PROC EXPORT DATA= COLLECT.accumulate_condition&condition 
            OUTFILE= "C:\Users\Austin Mulloy\Documents\meta-analysis of ss data\pnd\collection\accumulate_condition&condition..csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
data collect.accumulate_PNDs&condition; set work.accumulate_PNDs&condition;
run;

%mend cases;
%cases removed_check macro_calls for macro condition lists%




