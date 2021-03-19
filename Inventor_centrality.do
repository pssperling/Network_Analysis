* Firm Inventor Central - diff-in-diff from non-competes of main competitors / ?? firms in states with non-compete
* inventor leaves = a + b* external centrality + b** internal centrality + b * ext* int + e
* KPSS for patent market value = a + b* external centrality + b** internal centrality + b * ext* int + e

* Centrality measures: 
* Firm Inventor Centrality - total number of coauthors from outside the firm / possible n of outside coauthors
* Inventor External Centrality (network) - total number of coauthors/ possible n of coathors
* Inventor Internal Centrality (teamwork) - total number of outside coauthors/possible n of outside coauthors

* Issue: patents that are filed by several companies, how to identify which company a person is working for
* eg. I assume that inventor work 
* This is the check for patent by multiple firms:
			sort patnum permno 
			duplicates drop patnum permno, force
			sort patnum permno
			by patnum: gen number=_n
			sum number
			* total of 32 cases where there're >1 firm filing for a patent !!!
			* there are around 2000 patents with 2 joint coauthors


* ISSUE : I only have patents until 1984 (with gender)			
			
global dir "C:\Users\ps664\OneDrive - Drexel University\Inventor Network\Work"					

cd "$dir"
clear all

					/* GENDER DATASET - Gender dataset is not full (until 1984) */
					*use inventor_gender_subset,replace
					use inventor_gender,replace
					drop n
					duplicates drop firstname lastname patent, force
					rename patent patnum 

													 
					cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\Patents"
					merge m:m patnum using patents
					keep if _merge==3 | _merge==1
					drop _merge
					* companies_assigned shows cases where a patent is assigned to several firms 
					* for cases like that to identify which inventor works for which company
					* , just look at previous patent filings for the same inventor
					* THERE WERE NO CORRECTION NEEDED HERE as all ==1 -> if there are cases ==2, have to adjust
					tab companies_assigned
					* keep only patents for which I have inventor data
					* it's gonna be small for subset
					*keep if _merge==3
					*drop _merge
					*gen fyear=substr(fdate, length(fdate) - 3, 4)
					*gen iyear=substr(idate, length(idate) - 3, 4)
					*destring fyear, replace
					*destring iyear, replace
					drop class subclass xi pdate  idate 
					*drop firstname lastname 

					
					tostring patnum,replace
					drop street

					replace patnum="0"+patnum if length(patnum)==7

					* Correct joint patents - Find out which company an inventor works for in cases where a patent is jointly filed by 2 firms
					* there are 79 cases like that
					sort companies_assigned patnum firstname lastname
					gen year = substr(fdate,-4,4)

					sort firstname lastname year companies_assigned patnum 
					gen r=1 if companies_assigned==2
					by firstname lastname year: replace permno=permno[_n-1] if companies_assigned==2 
					drop r year
					sort firstname lastname patnum permno ncites 
					duplicates drop firstname lastname patnum, force		

					* Get inventor identifier from Long et al paper
					*Long et al data is basically some columns from invpat cvs file
					cd "C:\Users\ps664\OneDrive - Drexel University\Inventor Network\Work"
					merge 1:1 firstname lastname patnum using Long_et_al_data
					keep if _merge==3
					drop _merge appdate invseq n

					
					

					
/* Starting with Long et al dataset (without gender) */					

cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\Patents"					
clear all
use patents, replace

drop class subclass xi pdate idate 
tostring patnum,replace
replace patnum="0"+patnum if length(patnum)==7

gen year = substr(fdate,-4,4)

destring year, replace
*dataset is limited to 2010
drop if year>2011  | year<1990
drop if missing(year)
cd "C:\Users\ps664\OneDrive - Drexel University\Inventor Network\Work"
merge m:m patnum using Long_et_al_data
keep if _merge==3		



sort invnum_n year companies_assigned patnum 
gen r=1 if companies_assigned==2
by invnum_n year: replace permno=permno[_n-1] if companies_assigned==2 
drop r year
sort invnum_n patnum permno ncites 


drop _merge appdate n

duplicates drop invnum_n patnum, force		

	
gen fullname=firstname+" "+lastname

drop firstname lastname ncites companies_assigned asgnum class invnum invnum_n_uc 
rename appyear fyear
			
			
sort fyear patnum invnum_n permno
duplicates drop fyear patnum invnum_n, force

order fyear patnum invnum_n fullname

sa temp1, replace
clear all
use temp1, replace

				/* File is too big, so I broke it to two parts*/
				*temp 1
				drop n
				sort fyear patnum invnum_n permno 
				gen n=_n
				keep if n>=4742245


sort fyear patnum invnum_n permno

drop n
by fyear patnum: gen n=_n
by fyear patnum: egen n_coauthors=max(n)
sum n_coauthors
* loop max is the max number of coauthors per patent 



			/* Inventor Pairs - Create inventor Pairs that coautgored together */

set more off			
forval x=1/60 {
   by fyear patnum: gen coauthor_`x'=invnum_n[`x']
}
forval x=1/60 {
   replace coauthor_`x'="" if coauthor_`x'==invnum_n 
}

*sa tempt2, replace
*clear all
*use tempt2, replace

/*
forval x=1/33 {
   local k=`x'+1
   replace coauthor_`x'=coauthor_`k' if missing(coauthor_`x')
}
*/
expand n_coauthors

sort fyear patnum invnum_n
drop n
by fyear patnum invnum_n: gen n=_n
gen coauthor=coauthor_1

set more off
forval x=1/60 {
   replace coauthor=coauthor_`x' if n==`x' 
}
drop if missing(coauthor)
drop n

gen filing_date = date(fdate, "MDY")
format filing_date %td

rename coauthor t
drop coauthor_*
rename t coauthor
order fyear invnum_n fullname permno filing_date patnum  coauthor
sort invnum_n fyear permno patnum 
gen co_permno=permno

sa part3, replace

sa part2, replace

sa part1, replace

clear all
use part1, clear
append using part2
append using part3


		/* Numerator - Count the number of coauthros each inventor had in last 3 years */

*drop same coathor from the same year
duplicates drop invnum_n fyear coauthor, force

sort invnum_n fyear coauthor

*file is too big, I broke it into parts by an inventor
gen nu=_n


by invnum_n fyear: gen n=_n
by invnum_n fyear: egen max_n=max(n)

*drop all patent with unknown filing date
drop if missing(fyear)

* drop inventors of firms without permno (but keep their co-authors from the past)
* due to nature of data (all inventors from a patent are from the same firm) 
* this means I want to include cases where a worker switched from no-permno for to permno firm
* some cases include where an inventor while employed at a firm files for a patent with someone else outside a firm

sort invnum_n permno
by invnum_n: gen no_data=1 if missing(permno[1])
drop if no_data==1
sort invnum_n fyear coauthor


gen past_coauthors=0
gen past_outside_coauthors=0
gen a=1
by invnum_n: egen sum_a=sum(a)
sum sum_a
*x variable is the maximum of sum_a (max number the same inventor pair appears in the data)
*z is the number of all observations in the data
drop a sum_a

sort invnum_n fyear filing_date permno
*by invnum_n fyear: replace permno=permno[1] if missing(permno)

sa temp3, replace

*35050
*121

* count number of coauthors over the last 3 years
set more off
forvalues z = 8002164(-1)1 {

forval x=0/1214 {
	if invnum_n[`z'] ==invnum_n[`z'-`x'] & fyear[`z']-fyear[`z'-`x']<= 2   {
	replace past_coauthors=past_coauthors[`z']+1 in `z'
	}

	if invnum_n[`z'] ==invnum_n[`z'-`x'] & fyear[`z']-fyear[`z'-`x']<= 2 & co_permno[`z']!=co_permno[`z'-`x']  {
	replace past_outside_coauthors=past_outside_coauthors[`z']+1 in `z'
	}
}
}

*replace past_outside_coauthors=0 if missing(permno)
sort invnum_n fyear permno
by invnum_n fyear permno: egen max_c=max(past_coauthors)
by invnum_n fyear permno: egen max_d=max(past_outside_coauthors)


drop past_coauthors past_outside_coauthors
rename max_c past_coauthors
rename max_d past_outside_coauthors
gen copy_3y=0
gen copy_2y=0
*gen copy_out_3y=0
*gen copy_out_2y=0

sa temp4, replace

clear all
use temp4, replace    

sort invnum_n fyear filing_date permno

			
* adjust for cases where it was the same coauthor several times
set more off

forvalues z = 8002164(-1)1{

forval y=1/1214 {
	if coauthor[`z']==coauthor[`z'-`y'] & fyear[`z'] - fyear[`z'-`y']<= 2 & invnum_n[`z']==invnum_n[`z'-`y'] {
	replace copy_3y=1 in `z'  	
	}
	if coauthor[`z']==coauthor[`z'-`y'] & fyear[`z'] - fyear[`z'-`y']<= 1 & invnum_n[`z']==invnum_n[`z'-`y'] {
	replace copy_2y=1 in `z'  	
	}
	*print `z'
	*if coauthor[`z']==coauthor[`z'-`y'] & fyear[`z'] - fyear[`z'-`y']== 2 & invnum_n[`z']==invnum_n[`z'-`y'] & permno[`z']!=co_permno[`z'-`y'] {
	*replace copy_out_3y=1 in `z'  	
	*}
	*if coauthor[`z']==coauthor[`z'-`y'] & fyear[`z'] - fyear[`z'-`y']== 1 & invnum_n[`z']==invnum_n[`z'-`y'] & permno[`z']!=co_permno[`z'-`y'] {
	*replace copy_out_2y=1 in `z'  	
	*}	
	}
	}

* past_coathors variable includes both connections: with insiders and outsiders of a firm	
*inventors who switched jobs with this inventor are considered insiders

*by invnum_n fyear : egen sum_out_copies3=sum(copy_out_3y)
*by invnum_n fyear : egen sum_out_copies2=sum(copy_out_2y)

sa temp4_5, replace

clear all
use temp4_5, replace
drop sum_copies3 sum_copies2	

sort invnum_n fyear permno	
by invnum_n fyear permno: egen sum_copies3=sum(copy_3y)
by invnum_n fyear permno: egen sum_copies2=sum(copy_2y)

sort invnum_n fyear filing_date permno


* keep max number of coautgors within a year (yearly data)
sort invnum_n fyear permno past_coauthors	
duplicates drop fyear permno invnum_n, force


* I use sum_copies2[_n-1] because in some cases you can co-aouthor with the same person each year in the past 3 years
* condition on the last observation being from last year
sort invnum_n fyear permno
by invnum_n: gen past_coauthors_final=past_coauthors- sum_copies3 - sum_copies2[_n-1] if fyear==fyear[_n-1]+1
by invnum_n: gen past_outside_co_final=past_outside_coauthors- sum_copies3 - sum_copies2[_n-1] if fyear==fyear[_n-1]+1

*58k cases - adjust for cases where a worker transitions between firms and several copies of the same coauthor are created
by invnum_n: replace past_coauthors_final=past_coauthors- sum_copies3 - sum_copies3[_n-1]- sum_copies2[_n-2] if fyear==fyear[_n-2]+1 & missing(past_coauthors_final)
by invnum_n: replace past_outside_co_final=past_outside_coauthors- sum_copies3 - sum_copies3[_n-1]- sum_copies2[_n-2] if fyear==fyear[_n-2]+1 & missing(past_outside_co_final)
*4k cases switched jobs twice
by invnum_n: replace past_coauthors_final=past_coauthors- sum_copies3 - sum_copies3[_n-1]- sum_copies2[_n-2]- sum_copies2[_n-3] if fyear==fyear[_n-3]+1 & missing(past_coauthors_final)
by invnum_n: replace past_outside_co_final=past_outside_coauthors- sum_copies3 - sum_copies3[_n-1]- sum_copies2[_n-2]- sum_copies2[_n-3] if fyear==fyear[_n-3]+1 & missing(past_outside_co_final)

*left are cases where there's more than a year gap between patent filings
by invnum_n: replace past_coauthors_final=past_coauthors- sum_copies3  if missing(past_coauthors_final)
by invnum_n: replace past_outside_co_final=past_outside_coauthors- sum_copies3  if missing(past_outside_co_final)


replace past_outside_co_final=0 if past_outside_co_final<0
replace past_coauthors_final=past_coauthors if missing(past_coauthors_final)
replace past_outside_co_final=past_outside_coauthors if missing(past_outside_co_final)

drop past_coauthors past_outside_coauthors sum_copies3 sum_copies2  copy_3y copy_2y n max_n
rename past_coauthors_final past_coauthors
rename past_outside_co_final past_outside_coauthors

*now variable past_coauthors only includes singular coauthors (no double counting for the same coauthor)

sa temp5, replace

clear all
use temp5, replace


		/* Denominator - Count the number of possible coauthros each inventor could have had in last 3 years */

sort fyear invnum_n permno		
by fyear invnum_n: gen n=_n
by fyear invnum_n: egen hired_in_n_companies=max(n)
drop n no_data

* there could be the same inventor who filed with different companies for the same year: have to keep those cases
* and adjust for them when calculating possibilities for coauthorship
duplicates drop fyear permno invnum_n, force

* counts number of unique inventors over the last 3 years
*encode invnum_n, gen(inventor) 

egen long inventor = group(invnum_n)
sort inventor fyear

program myprogr
   egen sum=nvals(inventor)        
end
rangerun myprogr, inter(fyear -2 0) 
rename sum possible_coauthors

sa den1, replace

* (check-up) 
* counts number of total inventor obsrvations over the last 3 years -> it has to be smaller than sum
rangestat (count) inventor, interval(fyear -2 0)
drop inventor_count

sa den2, replace

* NOT CORRECTED  cases with past_outside_coauthors<0 !!!
* and 1 case with past_coauthors<0
replace past_outside_coauthors=0 if past_outside_coauthors<0
replace past_coauthors=0 if past_coauthors<0

gen centr_total=past_coauthors/possible_coauthors
gen centr_outsiders_scale_1=past_outside_coauthors/possible_coauthors
gen centr_insiders= centr_total - centr_outsiders


*drop n no_data co_permno 


* to find the total number of possible OUTSIDE coauthors over the last 3 years for each inventor:
* measures are 100% correlated independent of whether I scale it by the total 
* number of potential coauthors or potential OUTSIDE coauthors

program myprog1
   egen insiders=nvals(inventor)        
end
rangerun myprog1, by(permno) inter(fyear -2 0) 

gen possible_outside_coauthor=possible_coauthors - insiders
gen centr_outsiders_scale_2=past_outside_coauthors/possible_outside_coauthor

sa den3, replace

* This dataset has individual inventor centrality inside and outside

sa "$dir/inv_centrality", replace





		/* Firm's Inventor Centrality*/
* find centrality of a firm's inventors
* this is the number of all outside connections a firm has 
* divided by the total number of all outside inventors that filed within the last 3 years		

* can use a simple proxy instead - sum of all your inventor's outside connections
* this DOES NOT adjust for your inventors being connected to the SAME outsider (likely to be infrequent)

* have to use the second scaled measure because of the desired denominator
* denominator - outside potential coauthors not working for this firm
clear all
use inv_centrality, replace

rangestat (sum) centr_outsiders_scale_2, interval(fyear -2 0) by(permno)
rename centr_outsiders_scale_2_sum firm_centr


sa "$dir/firm_centrality", replace



				* Trying to adjust for repeated outside coauthors:

				order fyear permno inventor coauthor co_permno		
				sort permno fyear inventor coauthor co_permno		
								
				duplicates drop permno fyear co_permno, force

				rangestat (count) co_permno, interval(fyear -2 0)

				* count number of unique coauthors' permnos for each firm 
				program mypro
				   egen firm_coauthors=nvals(co_permno)        
				end
				rangerun mypro, inter(fyear -2 0) by(permno)


*
sort fyear permno invnum_n coauthor








		
		
		

		/* Gender and Centrality */
		

*Should inventor centrality be based on 3 years or all years?
*let's do 3 years first

gen female=1 if gender=="mostly_female" | gender=="female"
replace female=0 if gender=="mostly male" | gender=="male"

reg centr_total female i.fyear
reg centr_total female i.fyear if country=="US"

xtset permno
xtreg centr_total female i.fyear if country=="US"

*subsample is only up to 80s
xtreg centr_total female i.fyear if country=="US" & fyear>1980

 
 
sort Patent Firstname Lastname
duplicates drop Patent Firstname Lastname, force

by Patent: gen n=_n
by Patent: egen n_coauthors=max(n)
drop n
replace n_coauthors = n_coauthors - 1 
 
sort Firstname Lastname
 
by Firstname Lastname: egen network=sum(n_coauthors)

duplicates drop Firstname Lastname network, force

if gender =="mostly_female" then replace gender="female"
 
gen female=1 if gender=="mostly_female" | gender=="female"
replace female=0 if gender=="mostly male" | gender=="male"

ttest  network, by(female)


reg network female











			/* Scraps for Centrality code*/
	

* rangestat command does rolling summary stats over the window -2 years to this year (3 years total)
sort fyear
rangestat (sum) a, interval(fyear -2 0) 

encode invnum_n, gen(inventor) 
sort fyear inventor 

program myprogra
   gen ndistinct = r(r)        
end
rangerun myprogra, use(inventor) inter(fyear -2 0) 

list, sepby(Country Loc Group) 

gen year_min=fyear-2

egen sum=nvals(inventor)  if inrange(fyear,year_min,fyear)

	
gen possible_coauthors=1

unique invnum_n, by(fyear) gen(inv_year_1)
by fyear: replace inv_year_1=inv_year_1[1]


gen a=1
sort fyear invnum_n
by fyear: egen inv_year=sum(a)



sum inv_year_1
*x is the 3*inv_year or max number of inventors over 3 years


sort hired_in_n_companies invnum_n fyear permno
gen filed_1y_before=0
gen filed_2y_before=0

sort invnum_n fyear permno 
by invnum_n: gen k=_n
by invnum_n: replace filed_1y_before=1 if fyear[_n-1]==fyear[_n]-1 & invnum_n[_n-1]==invnum_n[_n]
by invnum_n: replace filed_2y_before=1 if fyear[_n-1]==fyear[_n]-2 & invnum_n[_n-1]==invnum_n[_n]
sort invnum_n fyear  filed_1y_before
by invnum_n fyear: replace filed_1y_before=filed_1y_before[1]
sort invnum_n fyear  filed_2y_before
by invnum_n fyear: replace filed_1y_before=filed_2y_before[1]


sort invnum_n fyear permno
forvalues z = 35050(-1)1{

forval y=1/121 {
	fyear[`z'] - fyear[`z'-`y']<= 2 & invnum_n[`z']==invnum_n[`z'-`y'] {
	replace a=0 in `z'  	
	}
}
}






* correct for repetitions where same inventor filed several patents in a year
sort invnum_n fyear permno
gen filed_several=1
by invnum_n fyear: replace filed_several=0 if filed_several[1]
rangestat (sum) filed_several, interval(fyear -2 0) 
* this is how many repeated filers there were from last 3 years due to same year filing

sort invnum_n fyear permno



program myprogra
   unique inventor, gen(inv)        
end
rangerun myprogra, inter(fyear -2 0) 



encode invnum_n, gen(inventor) 
sort fyear inventor permno
program myprogramma
   egen ndistinct = r(r)        
end
rangerun myprogramma, use(inventor) inter(fyear -2 0) 


encode invnum_n, gen(inventor) 
rangestat (unique) inventor, interval(fyear -2 0) 


encode invnum_n, gen(inventor) 
sort fyear inventor permno
program mypr
   unique inventor, gen(inv)       
end
rangerun mypr, inter(fyear -2 0) 

encode invnum_n, gen(inventor) 
sort fyear inventor permno
program myprnlk
   egen nvals = nvals(inventor)       
end
rangerun myprnlk, inter(fyear -2 0) 


* Example:
encode BName, gen(BValue) 
sort Country Loc Group Year 
program myprog
   qui tab BValue 
   gen ndistinct = r(r)        
end
rangerun myprog, use(BValue) inter(Year -2 0) by(Country Loc Group)
list, sepby(Country Loc Group) 






* correct for repetitions where same inventor filed last year or 2 years ago



* I only assumed so far that an inventor works for the company only in the year he files for patent
* POSSIBLE ASSUMPTION (EXTENSION): can assume that an inventor that files for a patent will stay in the same firm for 1 or 2 more years
* this will correct for an issue where smaller firms don't patent that frequently (meaning centrality effect is just a firm size effect)
 
 
 
expand 3
sort invnum_n fyear

by invnum_n fyear: gen g=_n

by invnum_n fyear: replace fyear=fyear[_n+1]-1 if g==2 
replace fyear=fyear[_n+2]-2  if g==1
replace inv_year=. if g==1 | g==2
*drop g
replace past_coauthors=0 if g==1 | g==2

sort invnum_n fyear inv_year
duplicates drop invnum_n fyear , force

sort fyear inv_year
by fyear: replace inv_year=inv_year[1]
drop if fyear<1955

sort invnum_n fyear

* I didn't fix same inventors repeating over 3 year period 
sort fyear invnum_n
by fyear: gen repeated=sum(filed_1y_before)+sum(filed_2y_before)

sort invnum_n fyear
by invnum_n: gen sum_possibles= inv_year + inv_year[_n-1]+inv_year[_n-2] -repeated - repeated[_n-1]+repeated[_n-2]

by invnum_n: gen centrality=past_coauthors/sum_possibles
keep if g==3
















by fullname: replace fyear=fyear[_n+1]-1 if filed_1y_before[_n+1]==0

by fullname: replace inv_year=. if filed_1y_before[_n+1]==0 & fyear[_n]==fyear[_n+1]-1


by fullname: replace fyear=fyear[_n+2]-2 if filed_2y_before[_n+2]==0 & filed_1y_before[_n+1]==0
by fullname: replace inv_year=. if filed_1y_before[_n+2]==0 & fyear[_n]==fyear[_n+2]-2



duplicates drop fullname fyear, force 

* Count number of repeated inventors over the last 3 years 
sort fyear fullname inv_year
by fyear: egen t_filed_1y_before=sum(filed_1y_before)
by fyear: egen t_filed_2y_before=sum(filed_2y_before)

by fyear: replace inv_year=inv_year[1]


sort fullname fyear

gen possible_inv= inv_year[_n-2]+inv_year[_n-1]+inv_year[_n]-filed_1y_before[_n-1]-filed_1y_before[_n]-filed_2y_before[_n]

* count number of coauthors over the last 3 years
set more off

forvalues z = 51260(-1)1 {

forval x=1/30000 {
	if fyear[`z'-`x']-fyear[`z'] <= 3  {
	replace possible_coauthors=possible_coauthors[`z']+1 in `z'
	}
	
forval y=1/30000 {
	if fullname[`z']==fullname[`z'-`y'] & fyear[`z'-`y']-fyear[`z']<= 3 {
	replace copy=1 in `z'  	
	}
	}	
}
}

		
		
		
		


sort fullname fyear past_coathors
by fullname fyear: replace past_coauthors==past_coathors[1]



if fyear=fyear[_n-`x'] & coauthor=coauthor[_n-`x']

