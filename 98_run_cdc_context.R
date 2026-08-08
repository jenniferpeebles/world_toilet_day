# World Toilet Day: supplemental disease context
# 98_run_cdc_context.R
#
# Runs the optional CDC context module. It does not run or modify the ACS
# plumbing analysis.

source("00_setup.R", local = globalenv(), encoding = "UTF-8")
source("pipeline_logging.R", local = globalenv(), encoding = "UTF-8")

cdc_context_scripts <- c(
  "20_import_cdc_context.R",
  "21_visualize_cdc_context.R"
)

run_logged_pipeline(
  scripts = cdc_context_scripts,
  pipeline_name = "CDC disease context",
  completion_message = "Supplemental CDC disease-context module completed."
)
