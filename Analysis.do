capture cd "C:\Users\Jubo Yan\Dropbox\Shared Research Folders\LargeGroupPPM\Dataprocessing_Yan\Oneshot"
capture cd "C:\Users\YAN-Workstation\Dropbox\Shared Research Folders\LargeGroupPPM\Dataprocessing_Yan\Oneshot"
capture cd "C:\Users\yanjubo\Dropbox\Shared Research Folders\LargeGroupPPM\Dataprocessing_Yan\Oneshot"
capture cd "C:\Users\xiaog\Dropbox\Shared Research Folders\LargeGroupPPM\Dataprocessing_Yan\Oneshot"
capture cd "D:\Dropbox\Shared Research Folders\LargeGroupPPM\Dataprocessing_Yan\Oneshot"

do cleansurvey.do

use PPM_oneshot_WTA_PR.dta, clear
append using PPM_oneshot_UPA.dta
append using PPM_oneshot_UPC.dta


***Merge survey data***
merge 1:1 idnumber using oneshot_Q.dta

drop provided-endowment
drop profit-othersbid
drop bonus_gsbid-payoff_2

***Note: "price" is the UP or UC in the UPA and UPC mechanisms. There is no corresponding variable in the WTA treatment***
***Note: "randomid" only applies when the rebate of PPM is randomly determined (either with equal or unequal probability)***

***Assign subjects to corresponding treatments using the info from "IDNum和相应场次0920UPDATE.dox"***


label define treatment 0 "PPM(norebate)" 1 "WTA_AG" 2 "WTA_AC" 3 "WTA_Prop" 11 "PR" 21 "UPA" 22 "UPC"

gen treatment = .
replace treatment = 1 if idnumber>=1001&idnumber<=1045
replace treatment = 1 if idnumber>=1086&idnumber<=1100

replace treatment = 2 if idnumber>=1101&idnumber<=1145
replace treatment = 2 if idnumber>=1186&idnumber<=1200

replace treatment = 3 if idnumber>=1301&idnumber<=1345
replace treatment = 3 if idnumber>=1386&idnumber<=1400

replace treatment = 11 if idnumber>=1401&idnumber<=1445
replace treatment = 11 if idnumber>=1486&idnumber<=1500

replace treatment = 0 if idnumber>=1251&idnumber<=1295
replace treatment = 0 if idnumber>=1201&idnumber<=1215

replace treatment = 21 if idnumber>=1701&idnumber<=1745
replace treatment = 21 if idnumber>=1791&idnumber<=1800

replace treatment = 22 if idnumber>=1501&idnumber<=1545
replace treatment = 22 if idnumber>=1586&idnumber<=1600

label values treatment treatment

tab treatment gpsize


***Append the oneshot game data from the repeated sessions***
gen wave = 1
order wave
append using oneshotfromrepeated.dta
drop groupid

***Drop the records that did not actually happen***
drop if bid == .
describe

gen valuerevelation = bid/payoff
gen guesscost_payoff = guesscost/payoff
gen guessbid_payoff = guessbid/payoff

--
***Generate sum stat ***
preserve

gen sumofpayoff = payoff*gpsize 

collapse (mean) sumofbid sumofpayoff meanbid = bid meanvaluerev = valuerevelation meancostbelief = guesscost_payoff meanbidbelief = guessbid_payoff (p50) medianbid=bid medianvaluerev = valuerevelation mediancostbelief = guesscost_payoff medianbidbelief = guessbid_payoff (sd) sdbid = bid sdvaluerev = valuerevelation sdcostbelief = guesscost_payoff sdbidbelief = guessbid_payoff, by(treatment gpsize)

gen percentage = sumofbid / sumofpayoff 
sort gpsize treatment

export excel using "sum_stat.xls", firstrow(variables) replace

restore

***Conduct Wilconxon Ranksum test to compare the small and large groups

foreach treat of numlist 0 1 2 3 11 21 22{
	ranksum bid if treatment == `treat' , by(gpsize)
}

***Conduct Wilcoxon Ranksum test for the sum stats (bid, valuerevelation, guessbid)***
foreach treat of numlist 11 21 22{
	ranksum bid if gpsize == 45 & (treatment == 0 | treatment == `treat'), by(treatment)
    ranksum bid if gpsize == 5 & (treatment == 0 | treatment == `treat'), by(treatment)
	ranksum valuerevelation if gpsize == 45 & (treatment == 0 | treatment == `treat'), by(treatment)
	ranksum valuerevelation if gpsize == 5 & (treatment == 0 | treatment == `treat'), by(treatment)
	ranksum guesscost if gpsize == 45 & (treatment == 0 | treatment == `treat'), by(treatment)
    ranksum guesscost if gpsize == 5 & (treatment == 0 | treatment == `treat'), by(treatment)
	ranksum guessbid if gpsize == 45 & (treatment == 0 | treatment == `treat'), by(treatment)
	ranksum guessbid if gpsize == 5 & (treatment == 0 | treatment == `treat'), by(treatment)
}


***Estimate linear model (as in Spencer et al.)***


local replace replace

foreach size of numlist 45 5{
	reg bid ibn.treatment if gpsize == `size', nocon
	outreg2 using regression.xls, `replace' label noas pvalue
	reg bid ibn.treatment ibn.treatment#c.payoff if gpsize == `size', nocon
	foreach treat of numlist 0 11 21 22{
	    test (_b[`treat'.treatment#c.payoff] == 1)
		local P`treat' = r(p)
	}
*	outreg2 using regression.xls, append label noas pvalue addstat(pvalue0, -`P0', pvalue1, -`P1', pvalue2, -`P2', pvalue3, -`P3', pvalue11, -`P11', pvalue21, -`P21', pvalue22, -`P22' )
		outreg2 using regression.xls, append label noas pvalue addstat(pvalue0, -`P0', pvalue11, -`P11', pvalue21, -`P21', pvalue22, -`P22' )
	tobit bid ibn.treatment ibn.treatment#c.payoff if gpsize == `size', ll(0) ul(6) nocon
	foreach treat of numlist 0 11 21 22{
	    test (_b[bid:`treat'.treatment#c.payoff] == 1)
		local P`treat' = r(p)
	}
	*outreg2 using regression.xls, append label noas pvalue addstat(pvalue0, -`P0', pvalue1, -`P1', pvalue2, -`P2', pvalue3, -`P3', pvalue11, -`P11', pvalue21, -`P21', pvalue22, -`P22' )
		outreg2 using regression.xls, append label noas pvalue addstat(pvalue0, -`P0', pvalue11, -`P11', pvalue21, -`P21', pvalue22, -`P22' )
	local replace
	
}

/*
local replace replace

foreach size of numlist 5 45{
	gen temp = bid 
	reg temp ibn.treatment if gpsize == `size', nocon
	outreg2 using regression.xls, `replace' label noas pvalue
	
	replace temp = temp - payoff
	
	reg temp ibn.treatment ibn.treatment#c.payoff if gpsize == `size', nocon
	outreg2 using regression.xls, append label noas pvalue 
	
	tobit temp ibn.treatment ibn.treatment#c.payoff if gpsize == `size', ll(-4.5) ul(4.5) nocon
	outreg2 using regression.xls, append label noas pvalue 
	
	local replace
	drop temp
}
*/

***Estimate belief model for PPM only***
gen guessexcess = guessbid*(gpsize - 1) / gpsize - guesscost
replace guessexcess = 0 if guessexcess <= 0
keep if treatment == 0
local replace replace
foreach size of numlist 45 5{
	reg bid payoff if gpsize == `size'
	outreg2 using ppmbelief.xls, `replace'
	
	reg bid payoff guesscost if gpsize == `size' 
	outreg2 using ppmbelief.xls, append
	
	test (_b[guesscost] == 1)
	
	reg bid payoff guesscost guessbid if gpsize == `size'
	outreg2 using ppmbelief.xls, append
	
	test (_b[guessbid] == 1)
	
	reg bid payoff guesscost guessbid guessexcess if gpsize == `size'
	outreg2 using ppmbelief.xls, append
	
	test(_b[guessexcess] == 0)
	test(_b[guessexcess] + _b[guessbid] == 1)
	test(_b[guessbid] == 1)
	
	local replace
}

***Estimate behavior-belief model for all rebate rules****


gen guessbid2 = guessbid - guesscost*gpsize/(gpsize-1)
replace guessbid2 = 0 if guessbid2<=0
local replace replace
foreach size of numlist 45 5{
	*gen temp = bid - payoff
	gen temp = bid
	reg temp i.treatment ibn.treatment#c.payoff if gpsize == `size', nocon
	outreg2 using BeliefReg.xls, `replace' label noas pvalue //br
	
	*replace temp = temp - guesscost
	reg temp i.treatment ibn.treatment#c.payoff ibn.treatment#c.guesscost if gpsize == `size', nocon
	outreg2 using BeliefReg.xls, append label noas pvalue //br
	
	*replace temp = temp - guessbid
	reg temp i.treatment ibn.treatment#c.guesscost ibn.treatment#c.payoff ibn.treatment#c.guessbid  if gpsize == `size', nocon
	outreg2 using BeliefReg.xls, append label noas pvalue //br
	
	
	*the added model so no need to adjust values
	*reg temp i.treatment ibn.treatment#c.payoff ibn.treatment#c.guessbid  if gpsize == `size', nocon
	*outreg2 using BeliefReg.xls, append label noas pvalue //br
	
	local replace
	drop temp
	
}

***replicate belief regression with Tobit model***
local replace replace
foreach size of numlist 45 5{
	*gen temp = bid - payoff
	gen temp = bid
	tobit temp i.treatment ibn.treatment#c.payoff if gpsize == `size', nocon ll(0) ul(6)
	outreg2 using BeliefReg_tobit.xls, `replace' label noas pvalue //br
	
	*replace temp = temp - guesscost
	tobit temp i.treatment ibn.treatment#c.payoff ibn.treatment#c.guesscost if gpsize == `size', nocon ll(0) ul(6)
	outreg2 using BeliefReg_tobit.xls, append label noas pvalue //br
	
	*replace temp = temp - guessbid
	tobit temp i.treatment ibn.treatment#c.guesscost ibn.treatment#c.payoff ibn.treatment#c.guessbid  if gpsize == `size', nocon ll(0) ul(6)
	outreg2 using BeliefReg_tobit.xls, append label noas pvalue //br
	
	
	*the added model so no need to adjust values
	*tobit temp i.treatment ibn.treatment#c.payoff ibn.treatment#c.guessbid  if gpsize == `size', nocon ll(0) ul(6)
	*outreg2 using BeliefReg_tobit.xls, append label noas pvalue //br
	
	local replace
	drop temp
	
}


tab guessbid2
drop guessbid2


***Explore the non incentivized survey data ***
preserve
reshape long costlow_ costmed_ costhigh_, i(idnumber) j(condition)
replace condition = condition/10
rename (costlow_ costlow_payoff costmed_ costmed_payoff costhigh_ costhigh_payoff) (wtb1 payoff_hyp1 wtb2 payoff_hyp2 wtb3 payoff_hyp3)

drop if treatment ==1 | treatment == 2 | treatment == 3

label var treatment "Cost-sharing Rule"


***draw PPM only plot (comment out if need to draw for all rebate rules)***
/*
keep if treatment == 0
replace gpsize = -gpsize
    twoway (lpoly wtb1 condition if wtb1>=0&wtb1<=6, lpatter(solid)) (lpoly wtb2 condition if wtb2>=0&wtb2<=6, lpattern(dash)) (lpoly wtb3 condition if wtb3>=0&wtb3<=6, lpattern(vshortdash)), by(gpsize, cols(2)) xlabel(0(1)6) ylabel(0(1)6)  legend(order(1 "Low Cost (1/6)" 2 "Medium Cost (2/6)" 3 "High Cost (3/6)") row(1)) xtitle("Others' Contribution") ytitle("Own Contribution (C{sub:i})") subtitle(, size(small)) xsize(10) ysize(5) scheme(s2mono)
	graph export survey_lpoly_ppm.png, replace width(1600) height(800)
*/
***draw all rebate rules***
foreach size of numlist 5 45{
    twoway (lpoly wtb1 condition if wtb1>=0&wtb1<=6&gpsize == `size', lpatter(solid)) (lpoly wtb2 condition if wtb2>=0&wtb2<=6&gpsize == `size', lpattern(dash)) (lpoly wtb3 condition if wtb3>=0&wtb3<=6&gpsize == `size', lpattern(vshortdash)), by(treatment, cols(7)) xlabel(0(1)6) ylabel(0(1)6)  legend(order(1 "Low Cost (1/6)" 2 "Medium Cost (2/6)" 3 "High Cost (3/6)") row(1)) xtitle("Others' Contribution") ytitle("Own Contribution (C{sub:i})") subtitle(, size(small)) xsize(5) ysize(1.5) scheme(s2mono)
	graph export survey`size'.png, replace width(3200) height(800)
}


***Regression Analysis***
reshape long wtb payoff_hyp, i(idnumber condition) j(scenario)

replace wtb = . if wtb<0|wtb>6
replace payoff_hyp = . if payoff_hyp < 0 | payoff_hyp > 20
rename scenario cost
 
*replace cost = cost*gpsize
gen con2 = condition - cost*gpsize/(gpsize - 1)
replace con2 = 0 if con2<=0

*replace wtb = wtb - payoff_hyp - cost - condition
tab cost

***test the ratio of 0 and conditional bids***
log using conditional_test, replace
gen wtb_zero = wtb == 0
tab wtb_zero
gen wtb_zero_l = (wtb<=0.5)
tab wtb_zero_l
gen wtb_conditional = (wtb == condition)
tab wtb_conditional
gen wtb_conditional_l = (abs(wtb -  condition) <= 0.5)
tab wtb_conditional_l
foreach size of numlist 45 5{
	prtest wtb_zero if (treatment == 0 | treatment == 11) & gpsize == `size', by(treatment)
	prtest wtb_zero if (treatment == 0 | treatment == 21) & gpsize == `size', by(treatment)
	prtest wtb_zero if (treatment == 0 | treatment == 22) & gpsize == `size', by(treatment)
	prtest wtb_zero_l if (treatment == 0 | treatment == 11) & gpsize == `size', by(treatment)
	prtest wtb_zero_l if (treatment == 0 | treatment == 21) & gpsize == `size', by(treatment)
	prtest wtb_zero_l if (treatment == 0 | treatment == 22) & gpsize == `size', by(treatment)
	prtest wtb_conditional if (treatment == 0 | treatment == 11) & gpsize == `size', by(treatment)
	prtest wtb_conditional if (treatment == 0 | treatment == 21) & gpsize == `size', by(treatment)
	prtest wtb_conditional if (treatment == 0 | treatment == 22) & gpsize == `size', by(treatment)
	prtest wtb_conditional_l if (treatment == 0 | treatment == 11) & gpsize == `size', by(treatment)
	prtest wtb_conditional_l if (treatment == 0 | treatment == 21) & gpsize == `size', by(treatment)
	prtest wtb_conditional_l if (treatment == 0 | treatment == 22) & gpsize == `size', by(treatment)
	
	*prtest wtb_zero if (treatment == 0 | treatment == 1) & gpsize == `size', by(treatment)
	*prtest wtb_zero if (treatment == 0 | treatment == 2) & gpsize == `size', by(treatment)
	*prtest wtb_zero if (treatment == 0 | treatment == 3) & gpsize == `size', by(treatment)
	
}
log close
***regression for PPM only***
keep if treatment == 0
local replace replace
foreach size of numlist 45 5{
	reg wtb c.cost c.payoff_hyp condition con2 if gpsize == `size', cluster(idnumber)
	outreg2 using SurveyReg_ppm.xls, `replace' label noas pvalue
	areg wtb c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment if gpsize == `size', cluster(idnumber) absorb(idnumber)
	outreg2 using SurveyReg_ppm.xls, append label 
	local replace
}



***regression for all rebate rules***

local replace replace
foreach size of numlist 45 5{
	reg wtb c.cost c.payoff_hyp condition con2 if gpsize == `size', cluster(idnumber)
	outreg2 using SurveyReg.xls, `replace' label noas pvalue
	reg wtb c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment if gpsize == `size', cluster(idnumber)
	outreg2 using SurveyReg.xls, append label noas pvalue
	areg wtb c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment if gpsize == `size', cluster(idnumber) absorb(idnumber)
	outreg2 using SurveyReg.xls, append label noas pvalue
	local replace
}

local replace replace
foreach size of numlist 45 5{
	tobit wtb c.cost c.payoff_hyp condition con2 if gpsize == `size',  ll(0) ul(6)
	outreg2 using SurveyReg_tobit.xls, `replace' keep(c.cost c.payoff_hyp condition con2) label noas pvalue
	tobit wtb c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment if gpsize == `size', ll(0) ul(6)
	outreg2 using SurveyReg_tobit.xls, append keep(c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment) label noas pvalue
	tobit wtb c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment i.idnumber if gpsize == `size',  ll(0) ul(6)
	outreg2 using SurveyReg_tobit.xls, append keep(c.cost c.payoff_hyp c.condition#i.treatment c.con2#i.treatment) label noas pvalue
	local replace
}



restore

--
***Draw barcharts***

preserve 

collapse (mean) bid guessbid guesscost valuerevelation guesscost_payoff (sem) bid_se = bid guessbid_se = guessbid guesscost_se = guesscost valuerevelation_se = valuerevelation guesscost_payoff_se = guesscost_payoff, by(treatment gpsize)

***Need to change the value of group size to make them side by side***
replace gpsize = 0 if gpsize == 5
replace gpsize = 1 if gpsize == 45

gen hid_bid = bid + 1.96*bid_se
gen lod_bid = bid - 1.96*bid_se

gen hid_valuerevelation = valuerevelation + 1.96*valuerevelation_se
gen lod_valuerevelation = valuerevelation - 1.96*valuerevelation_se

gen hid_guessbid = guessbid + 1.96*guessbid_se
gen lod_guessbid = guessbid - 1.96*guessbid_se

gen hid_guesscost = guesscost + 1.96*guesscost_se
gen lod_guesscost = guesscost - 1.96*guesscost_se

gen hid_guesscost_payoff = guesscost_payoff + 1.96*guesscost_payoff_se
gen lod_guesscost_payoff = guesscost_payoff - 1.96*guesscost_payoff_se

gen sei = (1 - gpsize) if treatment == 0
replace sei = (1 - gpsize)+3 if treatment == 1
replace sei = (1 - gpsize)+6 if treatment == 2
replace sei = (1 - gpsize)+9 if treatment == 3
replace sei = (1 - gpsize)+12 if treatment == 11
replace sei = (1 - gpsize)+15 if treatment == 21
replace sei = (1 - gpsize)+18 if treatment == 22
*replace sei = (1 - gpsize)+3 if treatment == 11
*replace sei = (1 - gpsize)+6 if treatment == 21
*replace sei = (1 - gpsize)+9 if treatment == 22
sort sei
/*
gen spencer_c = 2.96 if treatment == 11
replace spencer_c = 4.18 if treatment == 3
replace spencer_c = 3.96 if treatment == 2
replace spencer_c = 2.69 if treatment == 1

gen spencer_cv = 1.06 if treatment == 11
replace spencer_cv = 1.56 if treatment == 3
replace spencer_cv = 1.42 if treatment == 2
replace spencer_cv = 1.03 if treatment == 1
*/
label var bid "Contribution (C{sub:i})"
label var guessbid "Perceived Avg. Contribution"
label var guesscost "Perceived Cost (PP/N)"
label var valuerevelation "Ratio of Individual Contribution to Induced Value"
label var guesscost_payoff "Perceived Cost/Value Ratio"

foreach dvar in "bid" "valuerevelation" "guessbid" "guesscost" "guesscost_payoff"{
quietly	twoway (bar `dvar' sei if gpsize==1, fcolor(gs1)) ///
       (bar `dvar' sei if gpsize==0, fcolor(gs15)) ///
       (rcap hid_`dvar' lod_`dvar' sei, lcolor(black)), ///
       legend(row(1) order(1 "Large (45)" 2 "Small (5)" )) ///
	   xlabel( 0.5 "PPM" 3.5 "WTA_AG" 6.5 "WTA_AC" 9.5 "WTA_Prop" 12.5 "PR" 15.5 "UPA" 18.5 "UPC", labsize(small) angle(forty_five) noticks) ///	
       xtitle("Cost-sharing Rule") ytitle(`: variable label `dvar'') title(Average `: variable label `dvar'') xsize(10) ysize(6) scheme(s2mono)
	   graph export `dvar'_full.png, replace
	
}

*   xlabel( 0.5 "PPM" 3.5 "PR" 6.5 "UPA" 9.5 "UPC", labsize(small) angle(forty_five) noticks) ///

restore




--

***draw marginal penalty graph by segment***
gen guessexcess = guessbid*(gpsize - 1) - guesscost*gpsize
replace guessexcess = floor(guessexcess/6)*6 + 0.5*6
collapse (mean)bid (sem) bid_se = bid, by(guessexcess treatment gpsize)

gen hid_bid = bid + 1.96*bid_se
gen lod_bid = bid - 1.96*bid_se

keep if guessexcess>=-100 & guessexcess<=100

foreach j of numlist 5 45 {
	foreach i of numlist 0 1 2 3 11 21 22 {
		local ytitle = ""
		if `i' == 0	{
			local ytitle = "Own Contribution (C{sub:i})"
			local ttitle = "PPM (no rebate)"
		}
		else if `i' == 1	{
			local ttitle = "WTA-AG"
		}
		else if `i' == 2	{
			local ttitle = "WTA-AC"
		}
		else if `i' == 3	{
			local ttitle = "WTA-Prop"
		}
		else if `i' == 11	{
			local ttitle = "Proportional"
		}
		else if `i' == 21	{
			local ttitle = "UPA"
		}
		else if `i' == 22	{
			local ttitle = "UPC"
		}

	tw (scatter bid guessexcess if treatment == `i' & guessexcess>=0 & gpsize==`j', mcolor(green)) (scatter bid guessexcess if treatment== `i' & guessexcess<-6 & gpsize==`j', mcolor(red)) (scatter bid guessexcess if treatment== `i' & guessexcess<0&guessexcess>=-6 & gpsize==`j', mcolor(black)) (rcap hid_bid lod_bid guessexcess if treatment == `i' & gpsize == `j', lcolor(black)), xtitle(Guessed Excess Cont) ytitle(`ytitle') name(mp`i', replace) legend(off) title(`ttitle') xsize(1) ysize(2)

	}
	quietly graph combine mp0 mp1 mp2 mp3 mp11 mp21 mp22, ycommon xcommon rows(1) cols(7) xsize(20) ysize(6) title(Own contribution conditional on guessed excess contribution (group size = `j'))
	graph export marginalpenalty_`j'.png, replace 
}

drop guessexcess



***draw marginal penalty graph by segment using survey data***

preserve
reshape long costlow_ costmed_ costhigh_, i(idnumber) j(condition)
replace condition = condition/10
rename (costlow_ costlow_payoff costmed_ costmed_payoff costhigh_ costhigh_payoff) (wtb1 payoff_hyp1 wtb2 payoff_hyp2 wtb3 payoff_hyp3)

tab condition

reshape long wtb payoff_hyp, i(idnumber condition) j(scenario)

gen check1 = (wtb <= condition + 0.5 & wtb >= condition - 0.5)
gen check2 = (wtb <= 0.5)
sum check1 if treatment == 0 & gpsize ==45
sum check2 if treatment == 0 & gpsize ==45

tab scenario

replace wtb = . if wtb<0|wtb>6
replace payoff_hyp = . if payoff_hyp < 0 | payoff_hyp > 20
rename scenario cost
 
gen excess = condition*(gpsize - 1) - cost*gpsize
label var excess "Excess Contribution" 

*bysort treatment: sum bid if gpsize == 5 & excess >= 0
*bysort treatment: sum bid if gpsize == 45 & excess >= 0

gen pivotal = (excess >= -6 & excess <0 )
foreach j of numlist 5 45	{
	foreach i of numlist 0 1 2 3 11 21 22 {
		display `j' `i'
		ranksum wtb if excess < 0 & treatment == `i' & gpsize == `j', by(pivotal)
		*if `i' != 0 {
		*	ranksum wtb if excess > 0 & (treatment == 0 | treatment == `i') & gpsize == `j', by(treatment)
		*}
		
	}
}

tab excess if gpsize == 5
tab excess if gpsize == 45
replace excess = (floor(excess/6))*6 + 0.5*6
tab excess if gpsize == 5
tab excess if gpsize == 45
collapse (mean) wtb (sem)wtb_se = wtb, by(excess treatment gpsize)

gen hid_wtb = wtb + 1.96*wtb_se
gen lod_wtb = wtb - 1.96*wtb_se

***draw PPM only***
foreach j of numlist 45 5 {
	if `j' == 45	{
			local ytitle = "Own Contribution (C{sub:i})"
		}
		quietly tw (scatter wtb excess if treatment == 0 & excess>=0 & gpsize==`j', mcolor(green)) (scatter wtb excess if treatment== 0 & excess<-6 & gpsize==`j', mcolor(red)) (scatter wtb excess if treatment== 0 & excess<0 & excess>=-6 & gpsize==`j', mcolor(black)) (rcap hid_wtb lod_wtb excess if treatment == 0 & gpsize == `j', lcolor(black)), xtitle(Others' Excess Contribution) ytitle(`ytitle') ylabel(0(1)4) name(mpppm`j', replace) legend(off) title(Size = `j') xsize(40) ysize(60) scheme(s2mono)
}
quietly graph combine mpppm45 mpppm5, ycommon rows(1) cols(2) xsize(80) ysize(40) title(Own contribution conditional on others' excess contribution)  scheme(s2mono)
	graph export marginalpenaltysurvey_ppm.png, replace width(3200) height(1600)
	
***draw for all rebate rules***

foreach j of numlist 5 45	{
	foreach i of numlist 0 11 21 22 {

		local ytitle = ""
		if `i' == 0	{
			local ytitle = "Own Contribution (C{sub:i})"
			local ttitle = "PPM (no rebate)"
		}
		/*
		else if `i' == 1	{
			local ttitle = "WTA-AG"
		}
		else if `i' == 2	{
			local ttitle = "WTA-AC"
		}
		else if `i' == 3	{
			local ttitle = "WTA-Prop"
		}
		*/
		else if `i' == 11	{
			local ttitle = "Proportional"
		}
		else if `i' == 21	{
			local ttitle = "UPA"
		}
		else if `i' == 22	{
			local ttitle = "UPC"
		}
		
		if `j' == 5{
			local ylabel = "0(1)6"
		}
		else if `j' == 45{
			local ylabel = "0(1)4"
		}

	quietly tw (scatter wtb excess if treatment == `i' & excess>=0 & gpsize==`j', mcolor(green)) (scatter wtb excess if treatment== `i' & excess<-6 & gpsize==`j', mcolor(red)) (scatter wtb excess if treatment== `i' & excess<0&excess>=-6 & gpsize==`j', mcolor(black)) (rcap hid_wtb lod_wtb excess if treatment == `i' & gpsize == `j', lcolor(black)), xtitle(Others' Excess Contribution) ytitle(`ytitle') ylabel(`ylabel') name(mp`i', replace) legend(off) title(`ttitle') xsize(40) ysize(60) scheme(s2mono)

	}

	quietly graph combine mp0 mp11 mp21 mp22, ycommon xcommon rows(1) cols(7) xsize(80) ysize(20) title(Own contribution conditional on others' excess contribution (group size = `j')) scheme(s2mono)
	graph export marginalpenaltysurvey_`j'.png, replace width(3200) height(800)
		
}

restore

*** Draw empirical results for marginal penalty ranking: survey ***
gen tt1 = (costlow_payoff == costmed_payoff)
gen tt2 = (costlow_payoff == costhigh_payoff)
gen tt3 = (costmed_payoff == costhigh_payoff)

drop if tt1 == 0 | tt2 == 0 | tt3 == 0
drop tt1 - tt3

preserve
reshape long costlow_ costmed_ costhigh_, i(idnumber) j(condition)
replace condition = condition/10
rename (costlow_ costlow_payoff costmed_ costmed_payoff costhigh_ costhigh_payoff) (wtb1 payoff_hyp1 wtb2 payoff_hyp2 wtb3 payoff_hyp3)

tab condition

reshape long wtb payoff_hyp, i(idnumber condition) j(scenario)

tab scenario

replace wtb = . if wtb<0|wtb>6
replace payoff_hyp = . if payoff_hyp < 0 | payoff_hyp > 20
keep if payoff_hyp ==  4.5
rename scenario cost
 
gen excess = condition*(gpsize - 1) - cost*gpsize
label var excess "Excess Contribution" 

*drop if excess < -6
*gen pivotal = 1 - (excess >=0 )

*collapse (mean) wtb treatment gpsize, by(idnumber pivotal)
*reshape wide wtb, i(idnumber) j(pivotal)
*gen wtb = wtb0 - wtb1

collapse (mean) wtb (sem) wtb_se = wtb, by(treatment gpsize)
replace gpsize = 0 if gpsize == 5
replace gpsize = 1 if gpsize == 45

gen hid_wtb = wtb + 1.96*wtb_se
gen lod_wtb = wtb - 1.96*wtb_se
label var wtb "Contribution (C{sub:i})"

gen sei = gpsize if treatment == 0
replace sei = gpsize+3 if treatment == 1
replace sei = gpsize+6 if treatment == 2
replace sei = gpsize+9 if treatment == 3
replace sei = gpsize+12 if treatment == 11
replace sei = gpsize+15 if treatment == 21
replace sei = gpsize+18 if treatment == 22
sort sei

quietly	twoway (bar wtb sei if gpsize==0, fcolor(gs2)) ///
       (bar wtb sei if gpsize==1, fcolor(gs12)) ///
       (rcap hid_wtb lod_wtb sei, lcolor(black)), ///
       legend(row(1) order(1 "Small (5)" 2 "Large (45)")) ///
	   xlabel( 0.5 "PPM" 3.5 "WTA_AG" 6.5 "WTA_AC" 9.5 "WTA_Prop" 12.5 "PR" 15.5 "UPA" 18.5 "UPC", labsize(small) angle(forty_five) noticks) ///
       xtitle("Cost-sharing Rule") ytitle(Condtional Contribution) title(Average Contribution Beyond Threshold V = 4.5) xsize(10) ysize(6) ylabel(1(1)6) scheme(s2mono)
	   graph export mp_empirical_payoff45.png, replace
	   
restore





