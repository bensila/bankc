cd "/Users/ben/Dropbox/Research/BEN-LOUIS/bank_level_ben/"
use "bank-level analysis - KEY.dta", clear

tsset lender_gvkey year 

encode state1, gen(state_num)

eststo clear
eststo: qui reg lend_growth_tr  love_compete ASSETS ROA  CAPITAL   DEPOSIT LENDING   LEVERAGE state_HHI i.year boardsize boardindep , robust
eststo: qui reg lend_growth_tr  love_create ASSETS  ROA CAPITAL  DEPOSIT LENDING   LEVERAGE state_HHI i.year  boardsize boardindep, robust
eststo: qui reg lend_growth_tr  love_control ASSETS  ROA CAPITAL  DEPOSIT LENDING   LEVERAGE state_HHI i.year  boardsize boardindep , robust
eststo: qui reg lend_growth_tr  love_collaborate ASSETS ROA CAPITAL  DEPOSIT LENDING   LEVERAGE state_HHI state_HHI     i.year boardsize boardindep  , robust
eststo: qui reg lend_growth_tr  love_compete love_create love_control love_collaborate ASSETS ROA CAPITAL  LEVERAGE DEPOSIT LENDING state_HHI    i.state_num  i.year    boardsize boardindep  , robust
esttab, star(* .10 ** .05 *** .01) order(love_compete love_create love_control love_collaborate) drop(*year *state_num) label

*outreg2 using love_compete5, stats(coef tstat)  excel    dec(3)   

eststo clear
eststo: qui reg bad_loan_at  love_compete      ASSETS ROA    CAPITAL DEPOSIT LENDING   LEVERAGE state_HHI  boardsize board_indp    i.year   , robust
eststo: qui reg bad_loan_at  love_create ASSETS  ROA  CAPITAL DEPOSIT LENDING   LEVERAGE state_HHI     boardsize board_indp  i.year  , robust
eststo: qui reg bad_loan_at  love_control ASSETS  ROA  CAPITAL DEPOSIT LENDING   LEVERAGE state_HHI   boardsize board_indp   i.year   , robust
eststo: qui reg bad_loan_at  love_collaborate ASSETS ROA    CAPITAL DEPOSIT LENDING   LEVERAGE state_HHI  boardsize board_indp    i.year   , robust
eststo: qui reg bad_loan_at  love_compete love_create love_control love_collaborate ASSETS ROA   CHARTER CAPITAL DEPOSIT LENDING   LEVERAGE state_HHI  boardsize board_indp    i.year    , robust
esttab, star(* .10 ** .05 *** .01) order(love_compete love_create love_control love_collaborate) drop(*year) label
