* This program tries to find firm centrality 
* CORRECTING for cases where several firm inventors are connected to the same outside coauthor
* otherwise I can just use the sum of all firm year inventors outside centrality measure as the firm centrality measure

global dir "C:\Users\ps664\OneDrive - Drexel University\Inventor Network\Work"					

cd "$dir"
clear all
use inventor_gender_subset,replace
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
drop _merge appdate invseq nationality n

gen fullname=firstname+" "+lastname

drop firstname lastname ncites companies_assigned asgnum class

rename appyear fyear
					
sort fyear patnum invnum_n
duplicates drop fyear patnum invnum_n, force

order fyear patnum invnum_n fullname

by fyear patnum: gen n=_n
by fyear patnum: egen n_coauthors=max(n)
sum n_coauthors
* loop max is the max number of coauthors per patent 


			/* Inventor Pairs - Create inventor Pairs that coautgored together */
			
forval x=1/21 {
   by fyear patnum: gen coauthor_`x'=invnum_n[`x']
}
forval x=1/21 {
   replace coauthor_`x'="" if coauthor_`x'==invnum_n 
}
expand 21

sort fyear patnum invnum_n
drop n
by fyear patnum invnum_n: gen n=_n
gen coauthor=coauthor_1


forval x=1/21 {
   replace coauthor=coauthor_`x' if n==`x' 
}
drop if missing(coauthor)
drop n

gen filing_date = date(fdate, "MDY")
format filing_date %td

rename coauthor t
drop coauthor_*
rename t coauthor
order fyear invnum_n permno filing_date patnum fullname coauthor
sort invnum_n fyear permno patnum 
gen co_permno=permno


		/* Numerator - Count the number of outside coauthros each firm had in last 3 years */


*drop same coathor from the same year
duplicates drop invnum_n fyear coauthor, force

sort invnum_n fyear coauthor
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


sort permno fyear co_permno invnum_n coauthor
gen strange=1 if permno!=co_permno

gen past_coauthors=0
gen past_outside_coauthors=0
gen a=1
by invnum_n: egen sum_a=sum(a)
sum sum_a


		/* Numerator - Count the number of coauthros each firm had in last 3 years */




* MERGE IN federal_credit_rate, fed_tax_rate, r
preserve
	use year k_f_e t_f t_f_e t_s_e using "$raw_data/RDusercost_2017", clear
	egen tag=tag(year)
	keep if tag==1
	drop tag
	rename k_f federal_credit_rate
	rename t_f fed_tax_rate
	rename t_f_e effective_federal_tax_rate
	rename t_s_e effective_state_tax_rate
	tempfile fedrates
	save `fedrates'
restore
merge m:1 year using `fedrates'

































