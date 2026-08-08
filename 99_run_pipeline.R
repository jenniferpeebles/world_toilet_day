# World Toilet Day: ACS plumbing access
# 99_run_pipeline.R
#
# Run this file from the project root to execute the complete pipeline.

source("00_setup.R", local = globalenv(), encoding = "UTF-8")
source("pipeline_logging.R", local = globalenv(), encoding = "UTF-8")

pipeline_scripts <- c(
  "01_import.R",
  "02_clean_analyze.R",
  "03_qa.R",
  "04_visualize.R",
  "05_export.R",
  "06_rank_counties.R",
  "07_visualize_county_rankings.R",
  "08_create_interactive_county_map.R",
  "11_import_historical_acs.R",
  "12_prepare_historical_snapshot.R",
  "13_visualize_historical_snapshot.R",
  "14_render_report.R",
  "16_publish_readme_graphics.R",
  "17_run_tests.R"
)

run_logged_pipeline(
  scripts = pipeline_scripts,
  pipeline_name = "World Toilet Day ACS pipeline",
  completion_message = "World Toilet Day pipeline completed."
)
