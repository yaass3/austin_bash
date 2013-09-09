the script creates nine jobs on the cluster for the macros listed also here.

To execute the script run the command:
 ./script_austin.pbs 

(Do chmod +x $filename to give the file the execution permission) Here, for the files given, it would be:
chmod +x script_austin.pbs


You should put all the files, meaning the body of the sas code, simulation_first_half.sas, the macro list, macro_calls.txt ,
 and the tailing part of the sas code, tail_simulation.sas , in one folder.

The script basically, reads every 9 cases at a time and creates one job at a time and submits them onto the cluster one by one while run once.  
 