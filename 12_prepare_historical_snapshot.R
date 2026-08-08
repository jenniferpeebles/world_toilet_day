# World Toilet Day: historical ACS context
# 12_prepare_historical_snapshot.R
#
# Prepares a standalone national 2005–2009 snapshot. Despite this script's
# It intentionally performs no comparison with modern ACS estimates. Census
# changed the definition of complete plumbing in 2016.
# See: https://www.census.gov/programs-surveys/acs/guidance/comparing-acs-data/2016.html

historical_national_snapshot <- historical_us_raw %>%
  prepare_plumbing_data("us") %>%
  dplyr::transmute(
    period = glue::glue(
      "{config$historical_data_year - 4}–{config$historical_data_year}"
    ),
    geography = "United States",
    housing_units = total,
    housing_units_moe_90 = total_moe,
    housing_units_lacking_complete_plumbing = lacking,
    lacking_complete_plumbing_moe_90 = lacking_moe,
    pct_lacking_complete_plumbing = pct_lacking,
    pct_lacking_complete_plumbing_moe_90 = pct_lacking_moe,
    pct_lacking_ci_low_90 = pct_lacking_ci_low,
    pct_lacking_ci_high_90 = pct_lacking_ci_high,
    historical_definition = paste(
      "Complete plumbing required hot and cold running water,",
      "a flush toilet, and a bathtub or shower."
    ),
    interpretation = paste(
      "Lacking complete plumbing means one or more required facilities",
      "was absent; it does not identify which facility was absent."
    ),
    modern_comparison_allowed = FALSE,
    comparability_note = paste(
      "Do not compare directly with 2016 or later estimates:",
      "Census removed the flush-toilet component in 2016."
    )
  )

readr::write_csv(
  historical_national_snapshot,
  file.path(
    paths$data,
    glue::glue(
      "historical_plumbing_snapshot_",
      "{config$historical_data_year}.csv"
    )
  )
)

message(
  "Created the standalone historical national snapshot; ",
  "no cross-definition comparison was performed."
)
