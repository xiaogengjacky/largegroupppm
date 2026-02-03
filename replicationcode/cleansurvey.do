capture cd "C:\Users\xiaog\Dropbox\LargeGroupPPM\Dataprocessing_Yan"
capture cd "C:\Users\YAN-Workstation\Dropbox\LargeGroupPPM\Dataprocessing_Yan"

use PPM_oneshot_WTA_PR_Q.dta, clear
rename *, lower
rename idnumber IDNumber
rename payoff Payoff

append using PPM_oneshot_UPA_Q.dta
append using PPM_oneshot_UPC_Q.dta

label define rating 1 "Strongly agree" 2 "Agree" 3 "Neutral" 4 "Disagree" 5 "Strongly disagree"

rename Payoff payoff
rename q1 uncon_invest_rate
label var uncon_invest_rate "Invest regardless of others"
rename q2 con_invest_rate
label var con_invest_rate "Invest depending on others"
label values uncon_invest_rate con_invest_rate rating

rename q3 exc_payoff 
label  var exc_payoff "Investment exceeds payoff"
rename q4 exc_reason
label var exc_reason "Reason to exceed payoff"

rename q5_* costlow_*
rename q6_* costmed_*
rename q7_* costhigh_*

rename q8 soc_pref
rename q9 risk_pref

rename q10 age
rename q11 male
rename q12 major
rename q13 monthlyexpense
rename q14 parent_income

rename IDNumber idnumber
rename payoff payoff_2

rename costlow_00 costlow_0
rename costlow_05 costlow_5
rename costmed_00 costmed_0
rename costmed_05 costmed_5
rename costhigh_00 costhigh_0
rename costhigh_05 costhigh_5
capture save "C:\Users\xiaog\Dropbox\LargeGroupPPM\Dataprocessing_Yan\oneshot_Q.dta", replace
capture save "C:\Users\YAN-Workstation\Dropbox\LargeGroupPPM\Dataprocessing_Yan\oneshot_Q.dta", replace