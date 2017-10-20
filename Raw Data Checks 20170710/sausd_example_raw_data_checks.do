/*******************************************************************************
	File:						sausd_example_raw_data_checks.do 
	Current Author:				SHB
	Past Author(s):				KEK, SHB, MSL
	Purpose: 					Example code for loading and checking raw data
	Reference Code (Optional):	20161121_pg_sausd_v1_etl_shb.do
*******************************************************************************/

// Topmatter
{
	// Set Up
	{
		clear all
		set more off, permanently
		set seed 12345
	}

	// Globals - Inputs
	{
		global raw_2017		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20170701 - SAUSD Data"
		global raw_2016		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2016"
		global raw_2015		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2015"
		global raw_2014		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2014"
		global raw_2013		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2013"
		global raw_2012		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2012"
		global raw_2011		"P:\Proving_Ground\sausd_example\data\raw\Incoming Transfers\20161114 - Santa Ana Historical Data Files\2011"
	}

	// Globals - Outputs 
	{
		global interim		"U:\sausd_example\data\interim"
		global clean		"U:\sausd_example\data\clean"		
	}

	// User-Created Programs
	{
		qui do "P:\Proving_Ground\programs_new\aux_dos_cleaning\simple_utils.do"
	}
	
	// Switches
	{
		global append	"0"
	}
}

/*******************************************************************************
	Step 0: Append multiple years of raw files and save interim files
*******************************************************************************/

// STU: Student Data
// CSE: California Special Education
// FRE: Free and Reduced Lunch
if $append {
	foreach table in STU CSE FRE {
		
		// Load yearly files and save tempfiles
		forval yr = 2011/2017 {
			import delimited using "${raw_`yr'}\AERIES_`table'.csv", case(preserve) stringcols(_all) clear
			gen file_year = `yr'
			tempfile `table'_`yr'
			save ``table'_`yr''
		}
			
		// Append files and save interim file
		clear
		forval yr = 2011/2017 {
			append using ``table'_`yr''
		}
		save "$interim\sausd_`table'.dta", replace
	}
}

/*******************************************************************************
	Step 1: Examine STU (Student Data)
*******************************************************************************/

// Load interim file
use "$interim\sausd_STU.dta", clear

// Browse the data
browse

// Look at some individual records
list if _n == 1
list if _n == 10000

// How many records are there in total? In each year?
count
tab file_year, mi
tab SchoolYear file_year, mi

// Are there any straight duplicates?
duplicates report
cap drop dup
duplicates tag, gen(dup)
tab dup
duplicates drop

// What variables do we have?
ds _all
describe, fullnames
codebook

// Are there any variables that are entirely missing? Should we drop them?
ds, not(type numeric)
foreach var of varlist `r(varlist)' {

	// Remove leading and trailing blanks from string variables
	quietly replace `var' = strtrim(`var')
	
	// Check whether the variable is entirely missing
	capture assert mi(`var')
	
	// If the assert statement fails, move on
	if _rc {
		dis "`var' is not entirely missing"
		continue
	}
	
	// If the assert statement does not fail, drop the variable
	if !_rc {
		dis "`var' is entirely missing          ***DROPPING `var'***"
		drop `var'
	}
}

// Is there a data dictionary that describes the variables?
	*** If there are a lot of variables, you might want to focus only on 
	*** the ones you think you will use. But it is a good idea to look at
	*** every variable if time permits.
	keep SchoolYear SC SN LN FN MN ID SX GR EC LF CID EC2-EC6 ETH RC1-RC5 
	
// Label or rename variables based on information from the data dictionary
label var SC	"School code"
label var SN	"Student number"
label var LN	"Student last name"
label var FN	"Student first name"
label var MN	"Student middle name"
label var ID	"Student ID"
label var SX	"Student gender"
label var GR	"Grade level"
label var EC	"Ethnicity code 1"
label var LF	"Language fluency"
label var CID	"State student ID"
label var EC2	"Ethnicity code 2"
label var EC3	"Ethnicity code 3"
label var EC4	"Ethnicity code 4"
label var EC5	"Ethnicity code 5"
label var EC6	"Ethnicity code 6"
label var ETH	"Ethnicity code"
label var RC1	"Race code 1"
label var RC2	"Race code 2"
label var RC3	"Race code 3"
label var RC4	"Race code 4"
label var RC5	"Race code 5"

// What is the level of uniqueness? What are the unique identifiers?
	
	// State ID?
	isid SchoolYear CID
	gen missing_CID = mi(CID)
	tab SchoolYear missing_CID, row
	
	// Local ID?
	isid SchoolYear ID
	duplicates report SchoolYear ID
	cap drop dup
	duplicates tag SchoolYear ID, gen(dup)
	sort SchoolYear ID
	browse if dup>0
	
	// Student Number?
	isid SchoolYear SN
	duplicates report SchoolYear SN
	// School Code and Student Number?
	isid SchoolYear SC SN
	duplicates report SchoolYear SC SN

	// How many values of ID exist for each year-school-student?
	bys SchoolYear SC SN: egen n_ID = nvals(ID)
	tab n_ID

	// Does the same student have the same ID across years?
	gen full_name = upper(FN) + upper(MN) + upper(LN)
	bys ID: egen n_name = nvals(full_name)
	tab n_name, mi
	sort ID SchoolYear
	br if n_name>1

	// ID seems like the most promising student identifier across years
	// How many unique students are there overall? In each year?
	unique ID
	bys SchoolYear ID: gen n = _n
	tab SchoolYear if n==1
	tab SchoolYear

// Go through each variable looking for missingness, patterns over time, etc.

// EXAMPLE 1: Gender
	tab SX, mi
	tab SX SchoolYear, mi 
	
	// Is there a codebook that describes the value of this variable?
	preserve
		use "$interim\sausd_codebook.dta", clear
		keep if table=="STU" & !mi(SX)
		keep SX SX_desc
		duplicates drop
		isid SX
		tempfile sx_code
		save `sx_code'
	restore
	merge m:1 SX using `sx_code', keepusing(SX_desc) keep(1 3) nogen
	order SX_desc, after(SX)
	
	tab SX SX_desc, mi
	
	// How many values of SX does each student have in each year? 
	bys SchoolYear ID: egen n_gender_year = nvals(SX)
	tab n_gender_year, mi
	// Overall?
	bys ID: egen n_gender = nvals(SX)
	tab n_gender, mi
		
// EXAMPLE 2: Grade Level
	tab GR, mi
	tab GR SchoolYear, mi col
	bys SC: tab SchoolYear GR, mi
	
	// Is there a codebook that describes the values of this variable?
	preserve
		use "$interim\sausd_codebook.dta", clear
		keep if table=="STU" & !mi(GR)
		keep SchoolYear GR GR_desc
		duplicates drop
		isid SchoolYear GR
		tempfile gr_code
		save `gr_code'
	restore
	merge m:1 SchoolYear GR using `gr_code', keepusing(GR_desc) keep(1 3) nogen
	order GR_desc, after(GR)
	
	bys GR: tab GR_desc SchoolYear, mi
	
	// How many values of GR does each student have in each year? 
	bys SchoolYear ID: egen n_grade_year = nvals(GR)
	tab n_grade_year, mi
	tab GR if n_grade_year>1, mi
	
// Which variables can we use to connect different tables?
// EXAMPLE: Free and Reduced Lunch
preserve	
	use "$interim\sausd_FRE.dta", clear
	ds _all
	tab SchoolYear, mi
	bys SchoolYear ID: gen n = _n
	tab SchoolYear if n==1
	keep SchoolYear ID
	duplicates drop
	isid SchoolYear ID
	tempfile frpl
	save `frpl'
restore
merge m:1 SchoolYear ID using `frpl'

// How well did the merge work?
cap drop n
bys SchoolYear ID: gen n = _n
tab _merge if n==1
tab SchoolYear _merge if n==1, mi row


	
