cd "H:\Research\corporate culture and bank lending\Data\bank-level"


gen year = round(rssd9999/10000)
gen month = rssd9999-year*10000
gen month_1 = 12 if month>1000
drop if month_1 ==.


sort rssdid year 
merge m:m rssdid year   using "bank data" , keep (match master) 


gen ASSETS = ln(bhck2170)
gen ASSETS_SQR = ASSETS*ASSETS
gen LEVERAGE=(bhck2170-bhck3210)/bhck2170

gen ROA = (bhck4300/bhck2170)*100

gen CAPITAL=(bhck8274/bhck2170)*100
gen ROE = (bhck4300/bhck3210)*100
gen LENDING = bhck2122/bhck2170
gen raw_deposit = bhdm6631+bhfn6631 + bhdm6636 + bhfn6636
gen DEPOSIT = (bhdm6631+bhfn6631 + bhdm6636 + bhfn6636)/bhck2170
gen RISK = bhcka223/bhck2170

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

gen MBS = bhck1709 + bhck1733 + bhck1713 + bhck1736 + bhck3536
gen M_B_S = (MBS/bhck2170)*1000


gen bad_loans = bhck5525 + bhck5526
gen bad_loan_at = (bad_loans/bhck2170)*1000
gen bad_loan_loan = bad_loans/bhck2122

gen derivative_trading = bhcka126 + bhcka127 + bhck8723 + bhck8724
gen derivative_trading_scaled = derivative_trading/bhck2170/1000

gen loan_loss_provision = bhck4230/bhck2170
gen loan_loss_provision_loan = bhck4230/bhck2122
 