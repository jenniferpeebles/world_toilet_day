# Shared logging and completion helpers for the project runners.

run_logged_pipeline <- function(scripts, pipeline_name, completion_message) {
  log_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  log_slug <- stringr::str_replace_all(
    stringr::str_to_lower(pipeline_name),
    "[^a-z0-9]+",
    "_"
  )
  log_file <- file.path(
    paths$logs,
    paste0(log_slug, "_", log_stamp, ".log")
  )

  log_line <- function(...) {
    line <- paste0(...)
    timestamped_line <- paste0(
      "[",
      format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      "] ",
      line
    )

    message(timestamped_line)
    cat(
      timestamped_line,
      "\n",
      file = log_file,
      append = TRUE
    )
  }

  append_capture <- function(value) {
    cat(
      paste(capture.output(value), collapse = "\n"),
      "\n",
      file = log_file,
      append = TRUE
    )
  }

  log_line("Starting ", pipeline_name)
  log_line("Project root: ", project_root)
  log_line("Log file: ", normalizePath(
    log_file,
    winslash = "/",
    mustWork = FALSE
  ))
  log_line(
    "Configuration: data_year=", config$data_year,
    "; historical_data_year=", config$historical_data_year,
    "; survey=", config$survey,
    "; geographies=", paste(config$geos, collapse = ",")
  )

  cat(
    "\n--- SESSION AND PACKAGE VERSIONS ---\n",
    file = log_file,
    append = TRUE
  )
  append_capture(sessionInfo())
  cat(
    "--- END SESSION AND PACKAGE VERSIONS ---\n\n",
    file = log_file,
    append = TRUE
  )

  completed_successfully <- FALSE

  tryCatch(
    {
      for (script in scripts) {
        log_line("Starting script: ", script)

        withCallingHandlers(
          source(script, local = globalenv(), encoding = "UTF-8"),
          warning = function(warning_condition) {
            log_line(
              "WARNING in ",
              script,
              ": ",
              conditionMessage(warning_condition)
            )
            invokeRestart("muffleWarning")
          }
        )

        log_line("Finished script: ", script)
      }

      completed_successfully <- TRUE
      log_line(completion_message)
    },
    error = function(error_condition) {
      log_line(
        "ERROR: ",
        conditionMessage(error_condition)
      )
      log_line(pipeline_name, " stopped before completion.")
      stop(error_condition)
    },
    finally = {
      if (completed_successfully) {
        beepr::beep(2)
      } else {
        beepr::beep(9)
      }
    }
  )

  invisible(log_file)
}
