# World Toilet Day: historical ACS context
# 11_import_historical_acs.R
#
# Retrieves a national snapshot from the first ACS 5-year release, covering
# 2005–2009. It is not compared with modern estimates because Census changed
# the definition of complete plumbing in 2016.

historical_us_raw <- fetch_plumbing_data(
  "us",
  year = config$historical_data_year,
  with_geometry = FALSE
)

message(
  "Retrieved the national 2005–",
  config$historical_data_year,
  " ACS 5-year historical snapshot."
)
