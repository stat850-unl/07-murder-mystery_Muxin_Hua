/* This code reads in the 8 tables needed for the SQL murder mystery */

filename file1 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/crime_scene_report.csv';
PROC IMPORT FILE = file1 OUT = crime_scene_report DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=1228;
RUN;
filename file2 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/drivers_license.csv';
PROC IMPORT FILE = file2 OUT = drivers_license DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=10007;
RUN;
filename file3 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/facebook_event_checkin.csv';
PROC IMPORT FILE = file3 OUT = facebook_event_checkin DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=20011;
RUN;
filename file4 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/get_fit_now_check_in.csv';
PROC IMPORT FILE = file4 OUT = get_fit_now_check_in DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=2703;
RUN;
filename file5 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/get_fit_now_member.csv';
PROC IMPORT FILE = file5 OUT = get_fit_now_member DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=184;
RUN;
filename file6 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/income.csv';
PROC IMPORT FILE = file6 OUT = income DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=7514;
RUN;
filename file7 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/interview.csv';
PROC IMPORT FILE = file7 OUT = interview DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=4991;
RUN;
filename file8 URL 'https://raw.githubusercontent.com/srvanderplas/unl-stat850/master/data/sql-murder/person.csv';
PROC IMPORT FILE = file8 OUT = person DBMS = CSV REPLACE;
GETNAMES=YES;
GUESSINGROWS=10011;
RUN;

/*dm 'log;clear;';*/
/*Plese run as chunks*/
/*change the column names for join convinience*/
data drivers_license1;
	set drivers_license(rename=(id=license_id));
	run;

data person1;
	set person(rename=(id=person_id));
	run;

data get_fit_now_member1;
	set get_fit_now_member(rename=(id=membership_id));
	run;

data facebook_event_checkin1;
	set facebook_event_checkin(rename=(date=fb_date));
	run;

/*Get information about the murder*/
proc sql;
create table target as
		select * from crime_scene_report
		where date=20180115 & type='murder' & city="SQL City";
		run;
proc print data=target;
title 'Murder detailed information';
run;

/*Trace the interview of two witnesses*/
/*Witness 1*/
proc sql;
create table w1_name as 
		select * from person1
		where name like 'Annabel%';

create table w1_adr as
		select * from person1
		where address_street_name like 'Franklin%';

create table wit1 as 
	select * from 
		w1_name inner join w1_adr
		on w1_name.name=w1_adr.name;

create table wit_1 as
		select * from wit1 inner join interview
		on wit1.person_id=interview.person_id;
run;
proc print data=wit_1;
title 'Witness 1: info and clue';
run;

/*Witness 2*/
proc sql outobs=1;
create table wit2 as
		select * from person1
		where address_street_name like 'Northwestern%'
		order by address_number desc;

create table wit_2 as
		select * from wit2 inner join interview
		on wit2.person_id=interview.person_id;
run;
proc print data=wit_2;
title 'Witness 2: info and clue';
run;

/*Verify with table facebook_event_checkin*/
proc sql;
create table w1_fb as
		select name, event_id from
		wit_1 inner join facebook_event_checkin1
		on wit_1.person_id=facebook_event_checkin1.person_id;

create table w2_fb as
		select name, event_id from
		wit_2 inner join facebook_event_checkin1
		on wit_2.person_id=facebook_event_checkin1.person_id;

create table fb12 as
		select * from w1_fb
		union all
		select * from w2_fb;
run; 
proc print data=fb12;
title 'Witness 1 and witness 2 share the same facebook event ID';
run;


/*transcript of the witnesses.*/
proc sql;
create table transcript_12 as
		select * from wit_1
		union all
		select * from wit_2;

create table transcript12 as
		select transcript from transcript_12;
run;
proc print data=transcript12;
title 'Interview transcript from witnesses';
run;


/*Identify the record of suspect*/
proc sql;
create table suspect_mem_id as
		select * from get_fit_now_member1
		where membership_id like '48Z%' & membership_status='gold';

create table suspect_mid as
		select * from
		suspect_mem_id inner join person1
		on suspect_mem_id.person_id=person1.person_id;

create table suspect as
		select * from
		suspect_mid inner join drivers_license1
		on suspect_mid.license_id=drivers_license1.license_id;
run;
proc print data=suspect;
title 'Information of the suspect';
run;

/*verify the gym show up date is January 09*/
proc sql;
create table veri_date as
		select check_in_date from
		suspect inner join get_fit_now_check_in
		on suspect.membership_id=get_fit_now_check_in.membership_id;
run;
proc print data=veri_date;
title 'Date the suspect showed up at the gym';
run;

/*Name of the guilty party*/
proc sql;
create table guilty_name as
		select name from suspect;
run;
proc print data=guilty_name;
title 'Name of the guilty party';
run;
