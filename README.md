# World Toilet Day
R code for mapping U.S. data at the national, state and place level for World Toilet Day. 


### Why data about toilets? 

We posted the first version of this script on Nov. 19, 2021, in recognition of [World Toilet Day](https://www.un.org/en/observances/toilet-day) -- a day intended to draw greater awareness to the fact that many people in the world live without proper sanitary sewer service. 

Lack of such service brings an increased risk for the spread of numerous diseases. My own grandmother was orphaned at age 3 in the year 1930 when her [widowed young mother](https://www.ancestry.com/family-tree/person/tree/280288/person/-2100736346/facts) died of [typhoid fever](https://en.wikipedia.org/wiki/Typhoid_fever#:~:text=Typhoid%20fever%2C%20also%20known%20as,high%20fever%20over%20several%20days.), a disease that humans contract by drinking water that has been contaminated by human waste, such as when a well is dug too close to an outhouse or latrine. Typhoid also took the life of [my other grandmother's oldest sister](https://www.ancestry.com/family-tree/person/tree/280288/person/-2100736752/facts) at age 13 -- two young lives lost due to lack of running water and proper sanitation in rural Georgia.

Diseases like these, like typhoid and cholera, have largely been stamped out in the developed world today due to the adoption of modern sewer and septic systems. But there are still places even in the U.S. where people go without such conveniences every day due to poverty. The United Nations estimates that 2 billion people around the globe use a drinking water source that is contaminated with fecal matter. 

### About the data

All data in this summary is from the 2019 5-year averages of the [American Community Survey](https://www.census.gov/programs-surveys/acs) done by the U.S. Census Bureau.

To use this script, you will need a free API key from the Census. You can [request one at this link](https://api.census.gov/data/key_signup.html).

ACS data is usually released about a year behind. ACS data for 2023 was released in calendar year 2022. 

The 5-year average data averages each metric over the previous five years to provide a less herky-jerky result than would be provided with annual data releases. Why do we use the 5-year average data? The Census Bureau only publishes 1-year data for the largest cities and counties in America. For everybody else, we have to use the 5-year data -- or nothing. 

ACS data is an estimate. The confidence interval is 90 percent. The Census Bureau publishes margins of error for each metric presented here. Always remember, the smaller the sample the estimate is taken from, the wider the margin of error. 

But just to be clear, despite my attempts at toilet humor here, we're not actually counting toilets per se. The Census Bureau questionnaire asks people if their home has "complete" plumbing facilities, which the Census has defined since 1990 as [hot and cold running water and a bath or shower and a working toilet](https://www.census.gov/data/tables/time-series/dec/coh-plumbing.html#:~:text=Complete%20plumbing%20facilities%20are%20defined,requirement%20was%20dropped%20in%201990). So the metric we're examining is the percentage of housing units that have, or lack, complete plumbing facilities. 

Much of the data in this summary specifically comes from ACS table B25047, [which you can read more about at here](https://censusreporter.org/tables/B25047/), "Plumbing Facilities for All Housing Units." 

### About this script

This script will retrieve data from the Census Bureau's online data repositories using the Census's Application Programming Interface (API) and the [tidycensus package](https://walker-data.com/tidycensus/) of the [R programming language](https://en.wikipedia.org/wiki/R_(programming_language)) written by Kyle Walker.

The script uses a number of R packages including the [tidyverse family of packages](https://www.tidyverse.org/) created by [Hadley Wickham](http://hadley.nz/) et al. I am also very grateful for packages including [janitor](https://github.com/sfirke/janitor) and [cdlTools](https://github.com/jlisic/cdlTools). Thank you to the brilliant people behind these packages who wrote all the code and keep it maintained. 

The summary the script produces, or can produce, uses the [knitr package](https://yihui.org/knitr/) and [R Markdown](https://rmarkdown.rstudio.com/index.html). The text in this README file, in the script and in the knitted summary has not been copy edited, so please forgive all typos and style errors. 

Like most of the code you'll find here on GitHub, this is a work in progress. I've rewritten the script considerably since last updating this repository in 2019, and the new version is now in knitr and can produce a lovely, formatted report for you. The new version also includes some nifty barcharts and what knitr calls "kables."

The last iteration of this script included a section that pulled and crunched data at the tract level. I've started rewriting that section but still haven't finished it, so I've left out the tract-level data section entirely until it's ready for prime time. My apologies.

There are also numerous improvements I would like to make to the script. One thing in particular: I wrote the script not knowing that tidycensus includes functions that will convert FIPS codes, so the script as written relies on another package, cdlTools, to do the FIPS code conversion. My to-do list will include rewriting it so that we use tidycensus' own FIPS converter. You will see other items on my to-do list marked in the comments of the code. 

As a relative newcomer to R, I'm sure there are more elegant ways to do many things I do here. I hope to make more improvements in time for an update for World Toilet Day 2022. In the meantime, all suggestions are welcome. 
