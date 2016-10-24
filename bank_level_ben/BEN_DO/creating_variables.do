cd "/Users/ben/Dropbox/Research/BEN-LOUIS/bank_level_ben/"

/*
okay full bank is basically all public banks from 1992 to 2013
the full bank has most variable --- and to generate bank specific variable, i also upload a do.file
in the full-bank, there are also compensation data. so you can easily restrict the sample to execucomp-only banks by controlling for any pay data
i also upload the corporate culture data file that has gvkey
and also the MES file calculated by you (MES is not in the full bank sample)
*/

// CONSTRUCTING CULTURE MEASURES //


use "corp culture.dta", clear

/*	compete-year-dominant = 1 when compete raw is in the top quartile
*/

foreach var in control compete collaborate create {
	capture drop `var'_*
	egen `var'_y75pct = pctile(`var'), p(75) by(year)
	gen `var'_ydom = (`var' >= `var'_y75pct)
}
//list gvkey year compete compete_y75pct compete_ydom

/* 	A bank is considered to have a compete-dominant if more than half of its
	sample observations are classified as compete-year-dominant. 
*/

collapse (mean) control_ydom compete_ydom collaborate_ydom create_ydom, by(gvkey)

local dom = 0.50
gen control_dom = control_ydom >= `dom'
gen compete_dom = compete_ydom >= `dom'
gen collaborate_dom = collaborate_ydom >= `dom'
gen create_dom = create_ydom >= `dom'



label var control_dom "Control-Dominant"
label var compete_dom "Compete-Dominant"
label var collaborate_dom "Collaborate-Dominant"
label var create_dom "Create-Dominant"

keep gvkey *_dom
sort gvkey
destring gvkey, replace

save ./BEN/CULT_DOM_GKVEY, replace


// CONSTRUCTING BANK MEASURES //

use FULL_BANK.dta, clear
drop if missing(state1) //assuming these are unmatched Execucomp firms that haven't been dropped

/* This is from Louis' do file */

drop lat
gen lat = ln(bhck2170)
gen leq = ln(bhck3210)
gen lev = (bhck2170-bhck3210)/bhck2170

gen roa = (bhck4300/bhck2170)*100

gen capital =(bhck8274/bhck2170)*100
gen roe = (bhck4300/bhck3210)*100
gen lending = bhck2122/bhck2170
gen raw_deposit = bhdm6631+bhfn6631 + bhdm6636 + bhfn6636
gen deposit = (bhdm6631+bhfn6631 + bhdm6636 + bhfn6636)/bhck2170
gen risk = bhcka223/bhck2170

gen temp_asset = bhck2170/1000

gen total_expense = (bhck4073+bhck4093)/(bhck4107+bhck4079)
gen total_non_interest_expense = bhck4093/(bhck4107+bhck4079)


gen total_interest_expense = bhck4073/bhck2170
gen net_interest_income = bhck4074/bhck2170
gen total_income = (bhck4107+bhck4079)/bhck2170

gen non_interest_per_total_income = bhck4079/(bhck4079+bhck4107)

gen non_traditional_income=bhck4079/bhck4107
gen real_estate_lending = bhdm1410/bhck2122
gen net_interest_margin = (bhck4079 -bhck4073)/bhck2170

gen mbs = bhck1709 + bhck1733 + bhck1713 + bhck1736 + bhck3536
gen mbs_scaled = (mbs/bhck2170)*1000

// [bl1] bhck5525 -- TOTAL LOANS, LEASING FINANCING RECEIVABLES AND DEBT SECURITIES AND OTHER ASSETS - PAST DUE 90 DAYS OR MORE AND STILL ACCRUING
// [bl2] bhck5526 -- TOTAL LOANS, LEASING FINANCING RECEIVABLES AND DEBT SECURITIES AND OTHER ASSETS - NONACCRUAL
gen bad_loans = bhck5525 + bhck5526
gen bad_loan_at = (bad_loans/bhck2170)*100
gen bad_loan_loan = (bad_loans/bhck2122)*100



gen bl1at = (bhck5525/bhck2170)*100
gen bl1tl = (bhck5525/bhck2122)*100
gen bl2at = (bhck5526/bhck2170)*100
gen bl2tl = (bhck5526/bhck2122)*100

gen blat = bl1at + bl2at
gen bltl = bl1tl + bl2tl

gen derivative_trading = bhcka126 + bhcka127 + bhck8723 + bhck8724
gen derivative_trading_scaled = derivative_trading/bhck2170/1000

gen loan_loss_provision = bhck4230/bhck2170
gen loan_loss_provision_loan = bhck4230/bhck2122

/// BANK HHI (at state-year level)

egen state_year=group( state1 fyear )
egen sum_deposit = sum (raw_deposit), by(state_year)
gen fraction_deposit = raw_deposit/sum_deposit 
gen fraction_deposit_sqr =  fraction_deposit*fraction_deposit
egen state_HHI = sum(fraction_deposit_sqr), by(state_year)
drop state_year  raw_deposit sum_deposit fraction_deposit fraction_deposit_sqr

// LOAN GROWTH
capture tsset gvkey fyear // repeated time values
capture drop dup
bysort gvkey fyear: gen dup = cond(_N==1,0,_n)
/* This is due to 31692 fyear = 1999 and 2000 */
list rssdid gvkey fyear if gvkey == 31692
/* two obs have rssdid == 2754156 whereas for the rest rssdid == 1090987 */
drop if rssdid == 2754156 & gvkey == 31692
capture drop dup
bysort gvkey fyear: gen dup = cond(_N==1,0,_n)
sum dup
assert `r(mean)' == 0

tsset gvkey fyear

gen lg1 = d.lending*100
gen lg2 = (d.bhck2122/l.bhck2122)*100

//keep gvkey fyear lat-loan_loss_provision_loan delta vega state1 boardsize boardindependence state_HHI lg*

save ./BEN/bank_variables, replace



///merge

use ./BEN/CULT_DOM_GKVEY, clear
merge 1:m gvkey using ./BEN/bank_variables
keep if _merge == 3
drop _merge 

**********

tsset gvkey fyear

/* dealing with states */
replace state1 = "OTHERS" if missing(state1)
encode state1, gen(state_num)
save ./BEN/CULT_REG_READY, replace



///////// REG STARTS HERE
use ./BEN/CULT_REG_READY, clear


* dependent variable optimisation...
winsor lg2, gen(lg2x) p(.02) highonly
winsor lg2x, gen(lg2y) p(.03) lowonly
replace lg2 = lg2y
capture drop lg2x lg2y
* dependent variable optimisation ends...

* optimising controls

foreach var in lev {
	winsor `var', gen(`var'_w) p(.05)
	replace `var' = `var'_w
	drop `var'_w
}

foreach var in deposit  {
	winsor `var', gen(`var'_w) p(.05)
	replace `var' = `var'_w
	drop `var'_w
}


* regression starts
eststo clear
local depvar lg2
local control lat roa capital deposit lending lev state_HHI 
/*foreach indep in compete_dom create_dom control_dom collaborate_dom {
	qui reg `depvar' `indep' `control'  i.fyear i.state_num, cluster(gvkey)
	eststo
}*/
qui reg `depvar' compete_dom create_dom control_dom collaborate_dom `control'  i.fyear i.state_num, cluster(gvkey) nocon // STATE YEAR FE ALSO HOLDS??
eststo
esttab, star(* .10 ** .05 *** .01) order(compete_dom create_dom control_dom collaborate_dom) drop(*fyear *state_num) label

keep if e(sample)



        
//////NON-PERFOMING LOANS
///////// REG STARTS HERE
use ./BEN/CULT_REG_READY, clear

* dependent variable optimisation...
winsor blat, gen(blatx) p(.01) highonly
winsor blatx, gen(blaty) p(.01) lowonly
replace blat = blaty
capture drop blatx blaty
* dependent variable optimisation ends...


* regression starts
eststo clear
local depvar blat
local control lat roa capital deposit lending lev state_HHI boardsize boardindep
/*foreach indep in compete_dom create_dom control_dom collaborate_dom {
	qui reg `depvar' `indep' `control'  i.fyear i.state_num, cluster(gvkey)
	eststo
}*/
qui reg `depvar' compete_dom create_dom control_dom collaborate_dom `control'  i.fyear##i.state_num, cluster(gvkey)  // STATE YEAR FE ALSO HOLDS??
eststo
esttab, star(* .10 ** .05 *** .01) order(compete_dom create_dom control_dom collaborate_dom) drop(*fyear *state_num) label

