


*** NOT included in paper***
*** Draw best response graphs***

***Calculate best response values***
*gen br = .
//threshold
gen pp = guesscost * gpsize
//others' total contribution
gen con_j = othersbid * (gpsize - 1)
gen gap = pp - con_j
//to create 0 gaps
local new = _N + 9
set obs `new'
replace gap = -200 if _n == _N - 8
replace gap = -19.99 if _n == _N - 7
replace gap = -0.01 if _n == _N - 6
replace gap = 0  if _n == _N - 5
replace gap = 0.01  if _n == _N - 4
replace gap = 4.49  if _n == _N - 3
replace gap = 4.5  if _n == _N - 2
replace gap = 19.99 if _n == _N - 1
replace gap = 200  if _n == _N

replace treatment = 99 if _n >= _N - 8
replace payoff = 4.5 if _n>= _N - 8

replace gap = . if treatment == 21
//lower bound of best response
gen br_lb = .
//upper bound of best response
gen br_ub = .



foreach var of varlist br_lb br_ub {
	replace `var' = 0 if gap <= 0 & (treatment != 2 & treatment != 21)
	//the theoretical prediction is empty set but 0.01 in discrete case
	replace `var' = 0.01 if gap < 0 & treatment == 2	
	replace `var' = 0 if gap == 0& treatment == 2
	replace `var' = gap if (gap >0 & gap < payoff) & treatment != 21
}

replace br_lb = 0 if (gap >= payoff) & treatment != 21
replace br_ub = gap if (gap >= payoff) & treatment != 21

replace br_ub = 6 if br_ub > 6

sort gap

twoway (line br_lb gap if gap<=0&treatment == 99, lcolor(red) lwidth(medium) lpattern(longdash))  (line br_lb gap if gap>=4.5&treatment==99, lcolor(red) lwidth(medium) lpattern(longdash))  (line br_ub gap , lwidth(medium) lpattern (shortdash))  (scatter bid gap if treatment == 0 & gpsize == 5, msize(small)) (scatter bid gap if treatment == 1 & gpsize == 5, msize(small) msymbol(triangle_hollow)) (scatter bid gap if treatment == 2 & gpsize == 5, msize(small) msymbol(square_hollow)) (scatter bid gap if treatment == 3 & gpsize == 5, msize(small) msymbol(diamond_hollow)) (scatter bid gap if treatment == 11 & gpsize == 5, msize(small) msymbol(x)) (scatter bid gap if treatment == 22 & gpsize == 5, msize(small) msymbol(plus)) if gap>=-20&gap<=20, title(Response for Group Size = 5) ytitle(Response (Best Response)) xtitle(PP-C) legend(order(1 "lower bound" 3 "upper bound" 4 "PPM" 5 "WTA-AG" 6 "WTA-AC" 7 "WTA-Prop" 8 "Prop" 9 "UPC")) 

graph export response_5.png, replace

twoway (line br_lb gap if gap<=0&treatment == 99, lcolor(red) lwidth(medium) lpattern(longdash))  (line br_lb gap if gap>=4.5&treatment==99, lcolor(red) lwidth(medium) lpattern(longdash))  (line br_ub gap , lwidth(medium) lpattern (shortdash))  (scatter bid gap if treatment == 0 & gpsize == 45, msize(small)) (scatter bid gap if treatment == 1 & gpsize == 45, msize(small) msymbol(triangle_hollow)) (scatter bid gap if treatment == 2 & gpsize == 45, msize(small) msymbol(square_hollow)) (scatter bid gap if treatment == 3 & gpsize == 45, msize(small) msymbol(diamond_hollow)) (scatter bid gap if treatment == 11 & gpsize == 45, msize(small) msymbol(x)) (scatter bid gap if treatment == 22 & gpsize == 45, msize(small) msymbol(plus)) if gap>=-200&gap<=200, title(Response for Group Size = 45) ytitle(Response (Best Response)) xtitle(PP-C) legend(order(1 "lower bound" 3 "upper bound" 4 "PPM" 5 "WTA-AG" 6 "WTA-AC" 7 "WTA-Prop" 8 "Prop" 9 "UPC")) 

graph export response_45.png, replace


--
***Draw distributional graph for different treatments and group size***

foreach dvar of numlist 0 1 2 3 11 21 22 {
	
	kdensity guessbid if treatment == `dvar' & gpsize == 5, addplot((kdensity guesscost if treatment == `dvar' & gpsize == 45)) legend(row(2) order(1 "Small Group (5)" 2 "Large Group (45)" )) title ("Guessbid (`dvar')") xsize(1) ysize(2) name(GuessBid_`dvar', replace)
	*graph export GuessBid_`dvar'.png, replace


}

	quietly graph combine GuessBid_0 GuessBid_1 GuessBid_2 GuessBid_3 GuessBid_11 GuessBid_21 GuessBid_22, ycommon xcommon rows(1) cols(7) xsize(20) ysize(6) title(GuessBid Comparisons)
	graph export GuessBid_comp.png, replace 

kdensity guessbid if gpsize == 5, addplot((kdensity guesscost if gpsize == 45)) legend(row(2) order(1 "Small Group (5)" 2 "Large Group (45)" )) title ("Guessbid (Overall)")
graph export GuessBid.png, replace