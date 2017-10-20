/******************************************************************************
	Title: 		Macros in Stata Workshop
	Author: 	Lauren Dahlin (LND)
	Date: 		6/23/2017
	Purpopse: 	Introduce you to macros in coding 
	Notes: 		Fill in ??? with your code answers
*******************************************************************************/

// Change the working directory to the path where the data (agency_implementation.dta) lives
*cd "C:\Users\lnd495\Dropbox\cepr_docs\stata_resources\macros_stata_workshop\macros_stata_code"
cd "__your_path_here__"

// Load the data
use "agency_implementation.dta", clear

// Data is unique by agency + school + school year + grade range
isid agency_id school_id school_year grade_range
codebook

/*******************************************************************************
	Topic 1: Local and Global Variables 
	Note: Does not require data
*******************************************************************************/
// A local variable
// Try running line lines below separately and together (highlight one line at a time)
// What happens?
// Note: di is shorthand for "display"
local some_text "Hello world"
di "`some_text'"

// A global variable
// Try running line lines below separately and together (highlight one line at a time)
// What happens?
global some_text "Hello world"
di "$some_text"

// If you don't want space between your global and something else, 
// then you need to add curly brackets to your global
// This works
di "${some_text}ly"
// This doesn't
di "$some_textly"

// ***Your turn*** - create a local and a global and view them
// See what happens when you put a number
local my_local ???
global my_global ???
di "`my_local'"
di "$my_global"

// Globals and locals can also store variable names
// Make sure you don't put quotes around the global in the command
global summ_var "avg_minutes"
summ ${summ_var}

/*******************************************************************************
	Topic 2: Storing Output from Stata Commands
*******************************************************************************/

// What is the mean school average minutes for Grades 2-5 in Big District?
summ avg_minutes if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
// What locals (scalars) are available for us to store?
return list
// Store the mean in a global
global school_mean_mins = r(mean)
di "${school_mean_mins}"

// ***Your turn*** - what is the correlation between average minutes and average progress 
// in grades 2-5 across all schools and school years?
corr ??? ??? if grade_range == "2-5" & school_id != 999
return list
global ??? = ???
di ???

/*******************************************************************************
	Topic 3: Loops!
*******************************************************************************/ 

// Use loops to repeat the same code

// You can type the same code multiple times with slight variations
// What is the mean school average minutes for Grades 2-5 in Big District? 
summ avg_minutes if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
// Progress?
summ avg_progress if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
// Share of users?
summ avg_share_users if agency_name == "Big District" & grade_range == "2-5" & school_id != 999

// Or use a loop!
// Do you get the same answer?
foreach var in avg_minutes avg_progress avg_share_users{
	summ `var' if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
}

// Variation #1: Store variables in a global/local
local my_vars "avg_minutes avg_progress avg_share_users"
foreach var in `my_vars' {
	summ `var' if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
}

// Variation #2: Slightly different loop syntax
local my_vars "avg_minutes avg_progress avg_share_users"
foreach var of local my_vars{
	summ `var' if agency_name == "Big District" & grade_range == "2-5" & school_id != 999
}

// Values instead of strings
// Minutes by year
forval y = 2015/2016{
	di "`y'"
	summ avg_minutes if agency_name == "Big District" & grade_range == "2-5" & school_id != 999 ///
		& school_year == `y'
}

// Variation #1: Show the increment (This can be used to go backward)
forval y = 2016(-1)2015{
	di "`y'"
	summ avg_minutes if agency_name == "Big District" & grade_range == "2-5" & school_id != 999 ///
		& school_year == `y'
}

// ***Your turn*** - Can you put a loop inside a loop? Summarize all three variables by year
local my_vars "avg_minutes avg_progress avg_share_users"
forval ??? {
	foreach {
		summ ??? if agency_name == "Big District" & grade_range == "2-5" & school_id != 999 ///
		& school_year == ???
	}
}

// Sometimes you may want to have a "counter" in your loop also that increments by
// one in each iteration
local i = 1
forval y = 2015/2020{
	di "Iteration `i'"
	local ++i
} 

/*******************************************************************************
	Topic 4: Programs
*******************************************************************************/

// Define program arguments (inputs) and use those arguments as locals in your program
// When you call the program, you can use whatever inputs you want
// This program compliments you a specified number of times
// Drop the program if it is already defined
cap program drop compliment_me
program define compliment_me
	// The argument is times() - the number of times you want to be complimented
	syntax , times(int)
	forval i = 1/`times'{
		di "You are beautiful."
		sleep 800
	}
end
// Compliment yourself 10 times, or as many as you want!
compliment_me, times(10)

// ***Your Turn*** - Create a program that displays any string text
cap program drop ???
program define ???
	syntax, ???(str)
	???
end
// Try your program 
???

// Here is a more complicated program that makes a bar graph
// Don't worry too much about this - graphing will be covered later
cap program drop my_bar_graph
program define my_bar_graph
syntax varlist(min=1 max=1 numeric) [if], group_x_var(varname) title(str) subtitle(str) ytitle(str) color(string) 
	preserve
		cap keep `if'
		sort `varlist'
		cap drop _order
		gen _order = _n
		local max = _N
		local xlab ""
		forval i = 1/`max'{
			local lab_name = school_name[`i']
			di "`lab_name'"
			local xlab `"`xlab' `i' "`lab_name'" "'
		}
		di `"`xlab'"'
		twoway (bar `varlist' _order, lcolor(`color') fcolor(`color')), ///
				title("`title'") subtitle("`subtitle'") ///
				ytitle("`ytitle'") xtitle("") ///
				xlabel(`xlab', angle(45) labsize(vsmall)) ///
				graphregion(color(white) fcolor(white) lcolor(white)) plotregion(color(white) fcolor(white) lcolor(white) margin(1 1 0 0))
	restore
end

// Run it
my_bar_graph avg_minutes if agency_name=="Big District" & school_year == 2015 & grade_range == "K-1", ///
	group_x_var(school_name) title("Average Minutes on ST Math by School in 2014-15") subtitle("Big District, K-1") ytitle("Average Weekly Minutes")
graph export "topic4_school_bar.emf", replace 

/*******************************************************************************
	Topic 5: Locals within Globals
*******************************************************************************/

// When we run loops, we often want to look up stored numbers or text associated
// with the iteration in the loop. This means we may have locals for the loop iteration
// inside locals or globals. For example, we may want Big District and
// Little Charter to have different colors. We also want the titles to be different
// depending on the iteration.
// The "keys" for Big District and Little Charter are "big_district" and "little_charter"
global name_big_district = "Big District"
global name_little_charter = "Little Charter"
global name_2015 = "2014-15"
global name_2016 = "2015-16"
global color_big_district = "navy"
global color_little_charter = "maroon"
// Iterate over years then agency
forval y = 2015/2016{
	foreach agency in big_district little_charter{
		// Put globals into program from above
		my_bar_graph avg_minutes if agency_name=="${name_`agency'}" & school_year == `y' ///
			& grade_range == "K-1", ///
			group_x_var(school_name) title("Average Minutes on ST Math by School in ${name_`y'}") ///
			subtitle("${name_`agency'}, K-1") ytitle("Average Weekly Minutes") ///
			color(${color_`agency'})
		graph export "topic5_school_bar_`agency'_`y'.emf", replace 
	} // End agency loop
} // End year loop

// ***Your Turn*** Add an iteration to the loop above to create separate graphs for
// average progress and average share of users (in addition to average minutes. 
// Make sure you store the titles for these new variables in globals.
// Iterate over years then agency then implementation variable
global name_??? ""
global name_??? ""
global name_??? ""
forval y = 2015/2016{
	foreach agency in big_district little_charter{
		foreach ??? in ???{
			// Put globals into program from above
			my_bar_graph ?? if agency_name=="${name_`agency'}" & school_year == `y' ///
				& grade_range == "K-1", ///
				group_x_var(school_name) title("Average ??? on ST Math by School in ${name_`y'}") ///
				subtitle("${name_`agency'}, K-1") ytitle("Average ??")  ///
				color(${color_`agency'})
			graph export "topic5_school_bar_`agency'_`y'_???.emf", replace 
		} // End implementation variable loop
	} // End agency loop
} // End year loop


/*******************************************************************************
	Bonus Topic! "Global Magic"
*******************************************************************************/
cap prog drop global_magic
program define global_magic
	syntax, filename(string) sheet(string)
	preserve
		// Load table of variables and descriptions
		import excel using "`filename'", sheet("`sheet'") clear allstring firstrow
		qui describe *, varlist
		local global_list = regexr("`r(varlist)'", "agency", "")
		forval i = 1/`=_N' {
			local p = agency[`i']
			foreach global_name of local global_list{
				global `global_name'_`p' = `global_name'[`i']
			} // End row (agency) iteration
		} // End global list iteration
	restore
end

// Proof it worked
global_magic, filename("global_magic.xlsx") sheet("Sheet1")
di "${new_name_big_district}"
di "${new_name_little_charter}"
