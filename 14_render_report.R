# World Toilet Day
# 14_render_report.R
#
# Renders the compact HTML report from validated pipeline outputs.

configure_project_pandoc()

report_output <- rmarkdown::render(
  input = file.path(project_root, "world_toilet_day_report.Rmd"),
  output_file = paste0(
    "world_toilet_day_report_",
    config$data_year,
    ".html"
  ),
  output_dir = paths$output,
  params = list(
    data_year = config$data_year,
    output_root = paths$output
  ),
  envir = new.env(parent = globalenv()),
  quiet = TRUE,
  encoding = "UTF-8"
)

message(
  "Rendered report: ",
  normalizePath(report_output, winslash = "/", mustWork = TRUE)
)
