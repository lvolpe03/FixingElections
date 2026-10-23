cd "/Users/lukevolpe/Desktop/MA Data/PECN6200"
use PMCdata_final, clear

keep if oecd2009==0

* Combine floating and free floating
replace floating = 1 if free_floating==1
drop free_floating
replace er_num = 5 if er_num == 6

keep if !missing(money_gr, election, flex_er, newdem, gdp_pc_gr, ln_gdp_pc, resource_gdp, polity2, CBI_w)

* Moving "other managed" to the constrained category for RobCheck1
gen flex_er2 = floating
gen election_flex2 = flex_er2 * election

* Fix er_num labels
label define er_num_clean ///
	1 "No separate legal tender" ///
	2 "Conventional peg" ///
	3 "Currency board" ///
	4 "Crawling peg" ///
	5 "Crawl-like arrangement" ///
	6 "Pegged exchange rate within horizontal bands" ///
	7 "Stabilized arrangement" ///
	8 "Floating" ///
	9 "Other managed arrangement"
recode er_num (8=1) (1=2) (4=3) (3=4) (2=5) (10=6) (11=7) (5=8) (9=9), gen(er_num_cleanvar)
label values er_num_cleanvar er_num_clean
label var money_gr "M1 growth rate"
label var gdp_pc_gr "GDP per capita growth"
label var resource_gdp "Resource rents (share of GDP)"
label var ln_gdp_pc "Ln of GDP per capita"
label var polity2 "Polity2 index"
label var newdem "New democracy indicator"
label var CBI_w "CBI index"
label var er_num_cleanvar "Exchange rate regime (cleaned)"
label var flex_er "Flexible regime indicator"
label var election_flex "Election-Flex interaction"
label var flex_er2 "New flex. indicator"
label var election_flex2 "New Elec-Flex interaction"

eststo clear
estimates clear

*** Regime Classification Distribution ***
estpost tab er_num_cleanvar
esttab using "freq_table.tex", ///
	cells("b(fmt(%9.0f)) pct(fmt(%9.2f)) cumpct(fmt(%9.2f))") ///
    replace ///
    title("Exchange Regime Classification Frequencies") ///
    label ///
    varlabels(_all " ") ///
    booktabs ///
    nomtitles


*** SUMMARY STATS ***
* Make summary stats table in LaTeX
estpost tabstat money_gr election flex_er newdem polity2 CBI_w gdp_pc_gr ln_gdp_pc resource_gdp, stats(n mean sd min max) columns(stat)
* Export as .tex
esttab . using "SumStats.tex", cells("mean sd min max n") ///
    nonumber nomtitle replace ///
	title("Summary Statistics") ///
	label booktabs compress


*** TABLE 1 w/ PIECEMEAL CONTROLS ***
* Commented out models did not make final results table for spacing reasons *
* Controls still introduced in similar groups * 
reghdfe money_gr election flex_er election_flex, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model1

reghdfe money_gr election flex_er election_flex l1_money_gr l2_money_gr l3_money_gr, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model2

reghdfe money_gr election flex_er election_flex gdp_pc_gr ln_gdp_pc resource_gdp, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model3

// reghdfe money_gr election flex_er election_flex ln_gdp_pc, ab(IFSCode yearmonth) vce(cluster ISO)
// eststo model4
//
// reghdfe money_gr election flex_er election_flex resource_gdp, ab(IFSCode yearmonth) vce(cluster ISO)
// eststo model5
//
reghdfe money_gr election flex_er election_flex polity2 newdem, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model6

// reghdfe money_gr election flex_er election_flex newdem, ab(IFSCode yearmonth) vce(cluster ISO)
// eststo model7

reghdfe money_gr election flex_er election_flex CBI_w, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model8

reghdfe money_gr election flex_er election_flex l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp polity2 CBI_w newdem, ab(IFSCode yearmonth) vce(cluster ISO)
eststo model9

esttab model1 model2 model3 model6 model8 model9 ///
    using "Main Table.tex", ///
	b(5) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    label keep(election flex_er election_flex l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp newdem CBI_w polity2) ///
    title("Main Results") ///
    nomtitles nogap replace

	
*** FIGURE 1: Predicted M1 Growth in Election vs. Non-Election Months ***
reghdfe money_gr i.election##i.flex_er ///
    l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc ///
    resource_gdp polity2 CBI_w newdem, absorb(IFSCode yearmonth) vce(cluster ISO)
margins election
marginsplot, ///
    recast(bar) ///
    ytitle("Predicted Monthly M1 Growth") ///
    xtitle("Election Month") ///
    title("Average Monetary Growth: Election vs. Non-Election Months") ///
    ylabel(, angle(horizontal)) ///
    xlabel(0 "Non-Election" 1 "Election") ///
    name(main_effect, replace)
	
	
*** FIGURE 2: Total Election Effect by Regime ***
reghdfe money_gr c.election##i.flex_er ///
    l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc ///
    resource_gdp polity2 CBI_w newdem, absorb(IFSCode yearmonth) vce(cluster ISO)
margins flex_er, dydx(election)
marginsplot, ///
    recast(bar) ///
    plotopts(lcolor(black)) ///
    ytitle("Net Effect of Election on M1 Growth") ///
    title("Election Effect by Exchange Rate Regime") ///
    ylabel(, angle(horizontal)) ///
    name(mainresult, replace)


*** ROBUSTNESS CHECKS ***
* Reprint original for comparison
reghdfe money_gr election flex_er election_flex l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp polity2 CBI_w newdem, ab(IFSCode yearmonth) vce(cluster ISO)


* Recategorization
reghdfe money_gr election flex_er2 election_flex2 l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp polity2 CBI_w newdem, ab(IFSCode yearmonth) vce(cluster ISO)
estimates store reg1

esttab reg1 using "RobCheck1.tex", replace ///
    keep(election flex_er2 election_flex2 l1_money_gr l2_money_gr l3_money_gr) ///
    b(5) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Check --- Recategorizing 'Other Managed'") ///
    label nogap compress


* Disaggregating regime type
reghdfe money_gr ///
	c.election##ib1.er_num_cleanvar ///
	l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp polity2 CBI_w newdem, ///
	ab(IFSCode yearmonth) vce(cluster ISO)
estimates store reg2

esttab reg2 using "RobCheck2.tex", replace ///
    drop(l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc resource_gdp polity2 CBI_w newdem) ///
    b(5) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Robustness Check --- Disaggregating Regime Type") ///
    label nogap compress
	
	
*** ROBUSTNESS FIGURE ***
reghdfe money_gr ///
    c.election##ib1.er_num_cleanvar ///
    l1_money_gr l2_money_gr l3_money_gr gdp_pc_gr ln_gdp_pc ///
    resource_gdp polity2 CBI_w newdem, ///
    absorb(IFSCode yearmonth) vce(cluster ISO)
margins er_num_cleanvar, dydx(election)
marginsplot, ///
    recast(bar) ///
	xlabel(, angle(45)) ytitle("Marginal Effect of Election on M1 Growth") ///
    xtitle("Exchange Rate Regime") ///
    title("Political Monetary Cycle by Exchange Rate Regime") ///
    ylabel(, angle(horizontal)) ///
	byopts(xrescale yrescale compact) ///
	plotregion(margin(zero)) ///
    name(regime_effects, replace)
