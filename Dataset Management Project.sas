/*Project 1: Replicating two analysis datasets
Elisabeth Holmes and Thomas Closser
1/12/25*/

*Using proc import to read in the excel spreadsheet and the data for the baseline sheet and
outputting the data in a new dataset called ogbaseline;
proc import
file="/home/u63554010/Tom STS 3270 A/BetterStudyData for Project.xlsx"
out=ogbaseline dbms=xlsx replace;
sheet="Baseline";
run;

*Using proc import to read in the excel spreadsheet and the data for the followup sheet and
ouytputting the data in a new dataset called ogfollowup;
proc import
file="/home/u63554010/Tom STS 3270 A/BetterStudyData for Project.xlsx"
out=ogfollowup dbms=xlsx replace;
sheet="Followup";
run;

*Sorting both datasets by recordid so that they can be merged together later using recordid;
proc sort data=ogbaseline; by recordid;
proc sort data=ogfollowup; by recordid;

*Creating a new data set called participant1 that will be used to create all of the variables 
for the Participant dataset other then the three that need to be added after the Visits dataset is created;
data participant1;

*length for education is set to 21 so that the full wording can be read;
 length education $21;
 
*merging ogbaseline and ogfollowup together and renaming variables in ogbaseline that have the same names 
	as variables in ogfollowup;
 merge ogbaseline (rename=(painworst=bpainworst painleast=bpainleast painavg=bpainavg painnow=bpainnow)) 
       ogfollowup;
       
*since both datasets have recordid, they are merged together using this variable;
 by recordid;
 
*there is only one urgent care center so if the medsite was OrthoNow the site type is set to urgent care;
 if medsite="OrthoNow" then sitetype="UC";

*otherwise the site type is set to emergency room, since the other three medsites are all emergency rooms; 
 else sitetype="ER";
 
*age is defined as the difference between screendate and birthdate divided by 365.25 and rounded down to the 
	nearest integer using the floor function;
 age = FLOOR((screendate - birthdate)/365.25);
 
*the Male variable is defined using the sex variable from the baseline data, if the participant is Male then 
	the new variable is set to 1;
 if sex=1 then Male=1;
 
*but if the participant is not make the variable Male is set to 0, then using the race_ columns from the baseline 
	data set, this data is used to create a new variable called race, so if they had a 1 in one of the previously 
	defined columns, Then that 1 changes to the name of the column and is added to the new race variable;
 else if race_black=1 then race="Black";
 else if race_white=1 then race="White";
 else Male=0;
 if race_asian=1 then race="Asian";
 else if race_black=1 then race="Black";
 else if race_white=1 then race="White";
 else race="Other";
 
*in the original baseline table education is defined by different numbers depending on level of education;
 if educ=0 or educ=1 then education="High School or Less";
 
*here we change those numbers into character variable education and combine similar numbers and meanings 
	together to make education an easier variable to understand;
 else if educ in (2,3,4) then education="At least some college";
 
 *BaselinePainSev is first created using an array taking the old data to create an array of new data;
 array oldbpain [4] bpainworst bpainleast bpainavg bpainnow;
 array newbpain [4] nbpainworst nbpainleast nbpainavg nbpainnow;
 
*we use a do loop to change any data in these old categories that was equal to 55 into missing data in the 
	new array;
 do i=1 to 4;
 if oldbpain[i]=55 then newbpain[i]=.;
 
 *if the old data is not equal to 55, then we set the new data equal to the old data;
 else newbpain[i]=oldbpain[i];

*We then use this to more easily determine if there are missing variables, so if there is 2 or less missing 
	we can take the average of pain;
 end;
 if nmiss(nbpainworst, nbpainleast, nbpainavg, nbpainnow) <= 2 then do;
  BaselinePainSev= mean(nbpainworst, nbpainleast, nbpainavg, nbpainnow);
 end;
 
*BMI is calculated;
 BMI = (weight*703)/height**2;
 
*the index function looks through the painmeds column to see if the word opioid is in a row, if it is 
	then the opioids variable is set to "Yes";
 if (index(painmeds, "Opioid") > 0) then Opioids="Yes";
 
*if the index function does not find the word opioid then the opioids variable is set to "No";
 else Opioids="No";
 
*the variables that we just created plus recordid, trtgroup, screendate, and eth_hispanic are kept in the 
	dataset so that the data set only has the information that is important to us, and not any extra 
	unneccesary data to clutter it up;
 keep recordid trtgroup screendate eth_hispanic sitetype age Male race education BaselinePainSev BMI Opioids;
run;

*Creating a new dataset called Visits that will be used to create all of the necessary variables needed;
data Visits;

*merging ogbaseline and ogfollowup together and renaming variables in ogbaseline that have the same names as 
	variables in ogfollowup;
 merge ogbaseline (rename=(painworst=bpainworst painleast=bpainleast painavg=bpainavg painnow=bpainnow))
 ogfollowup;
 
*since both datasets have recordid, they are merged together using this variable;
 by recordid;
 
*to get the correct amount of observations, visits only needs to have the information for participants that 
came back for followups, so the participants that are only in baseline must be taken out;
 if day ne .;
 
*the actual day that people came in for their followup appointments is calculated by taking the difference 
	between the participants calldate and screendate;
 ActualDay = calldate - screendate;
 
*using the variable we just created we take the absolute value of the day since the first appointment and 
	the actual day that the participant came in to determine if it was within two weeks of the suggested day;
 if abs(day-ActualDay) <= 14 then Within2Weeks=1;
 
*if it was Within2Weeks=1, if not Within2Weeks is set equal to 0, just like with BaselinePainSev, PainSeverity 
	is first created using an array taking the old data to create an array of new data;
 else Within2Weeks=0;
 array oldpain [4] painworst painleast painavg painnow;
 array newpain [4] npainworst npainleast npainavg npainnow;
 
*we use a do loop to change any data in these old categories that was equal to 55 into missing data in the 
	new array;
 do i=1 to 4;
 if oldpain[i]=55 then newpain[i]=.;
 
*if the old data is not equal to 55, then we set the new data equal to the old data;
 else newpain[i]=oldpain[i];
 
*We then use this to more easily determine if there are missing variables, so if there is 2 or less missing 
	we can take the average of pain;
 end;
 if nmiss(npainworst, npainleast, npainavg, npainnow) <= 2 then do;
  PainSeverity= mean(npainworst, npainleast, npainavg, npainnow);
 end;

*just like with BaselinePainSev and PainSeverity, PainInterference is first created using an array taking the 
	old data to create an array of new data;
 array painint [7] painint_general painint_mood painint_walk painint_work painint_relate painint_sleep painint_life;
 array inter [7] inter_general inter_mood inter_walk inter_work inter_relate inter_sleep inter_life;
 
*we use a do loop to change any data in these old categories that was equal to 55 into missing data in the new array;
 do i=1 to 7;
 if painint[i]=55 then inter[i]=.;
 
*if the old data is not equal to 55, then we set the new data equal to the old data;
 else inter[i]=painint[i];
 
*We then use this to more easily determine if there are missing variables, so if there is less than 4 missing we 
	can take the average of pain interference;
 end;
 if nmiss(inter_general, inter_mood, inter_walk, inter_work, inter_relate, inter_sleep, inter_life) < 4 then do;
  PainInterference = mean(inter_general, inter_mood, inter_walk, inter_work, inter_relate, inter_sleep, inter_life);
 end;
 

*after doing those arrays and variables we use these new variables and first make sure that they both have data;

*then we take the mean of the two new variables to get a CombinedPain score;
 if nmiss(painseverity, paininterference) = 0 then do;
  CombinedPain = mean(painseverity, paininterference);
 end;
 keep recordid trtgroup day ActualDay Within2Weeks PainSeverity PainInterference CombinedPain;

*the variables that we just created plus recordid, trtgroup, and day are kept in the dataset so that the data set only
	has the information that is important to us, and not any extra unneccesary data to clutter it up, the variables 
	are then all given labels to make them easier to understand for the people reading our dataset;
 label recordid="Participant ID"
 trtgroup="Treatment Group"
 day="Nominal Follow-Up Visit Day"
 ActualDay="Actual Follow-Up Visit Day"
 Within2Weeks="1 if actual day within 2 weeks of nominal, 0 otherwise"
 PainSeverity="Pain Severity"
 PainInterference="Pain Interference"
 CombinedPain="Combined Pain Score";
run;

*The Visits dataset we just created is sorted by recordid and day, so that it can be merged with the participant1 
	dataset;
proc sort data=Visits; by recordid day;

*Creating a new dataset called Participant that we merge the data from participant1 with the data from Visits 
	to finish the last few variables needed to complete the Participant dataset;
data Participant;

*particpipant1 and Visits datasets are merged together to supply the data needed for the Participants dataset;
 merge participant1 Visits;
 
*since both datasets have recordid and trtgroup, they are merged together using those two variables;
 by recordid trtgroup;
 
*to get the maximum and minimum pain severity, we first had to retain our new variables;
 retain PainSevFUMax PainSevFUMin;
 
*at the first recordid for each individual we set the max and min to missing, so that there had to be a number 
	to represent the max and min in the data;
 if first.recordid then do;
  PainSevFUMax=.;           
  PainSevFUMin=.;
  
*using this we then took the max and min of our retained variables and PainSeverity to get the final numbers for
	PainSevFUMax and PainSevFUMin;
 end;
 PainSevFUMax=max(PainSevFUMax, PainSeverity);
 PainSevFUMin=min(PainSevFUMin, PainSeverity);
 
*to find the FinalPainSev we had to set it equal to PainSeverity of the final visit using last.recordid;
 if last.recordid then do;
  FinalPainSev=PainSeverity;
 end;
 
*in order to get only the last observations for the participants we used if last.recordid to only show the last 
	occurence of each recordid;
 if last.recordid;

*the keep statement is used to keep the variables that are necessary to understand the data and the variables 
	we just created in participant1 and Participant;
 keep recordid trtgroup screendate eth_hispanic sitetype age Male race education BaselinePainSev BMI Opioids PainSEVFUMax PainSevFUMin FinalPainSev;
 
*the variables are then given labels to make them easier to understand for the people reading our dataset;
 label recordid="Participant ID"
 trtgroup="Treatment Group"
 screendate="Screening Date"
 eth_hispanic="Hispanic Ethnicity"
 sitetype="Enrollment Site Type"
 age="Participant Age at time of Study Entry"
 Male="1 if male, 0 if female"
 race="Participant Race"
 education="Education Category"
 BaselinePainSev="Baseline Pain Severity"
 BMI="Body Mass Index"
 Opioids="Was participant prescribed opioids? Yes or No"
 PainSevFUMax="Maximum Pain Severity During Follow-Up"
 PainSevFUMin="Minimum Pain Severity During Follow-Up"
 FinalPainSev="Pain Severity at Participant's final Follow-Up";
run;

proc contents data=participant varnum;
run;

proc contents data=visits varnum;
run;