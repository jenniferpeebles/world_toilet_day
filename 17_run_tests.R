# World Toilet Day
# 17_run_tests.R
#
# Runs integration tests against the generated project outputs.

Sys.setenv(
  WORLD_TOILET_DATA_YEAR = as.character(config$data_year),
  WORLD_TOILET_HISTORICAL_DATA_YEAR = as.character(
    config$historical_data_year
  ),
  WORLD_TOILET_PROJECT_ROOT = project_root
)

testthat::test_dir(
  file.path(project_root, "tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE
)
