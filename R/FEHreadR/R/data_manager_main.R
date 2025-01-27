#' @importFrom jsonlite fromJSON toJSON
#' @importFrom httr POST GET add_headers content status_code
#' @importFrom glue glue
NULL

#' Connects to the data manager and returns an auth token
#'
#' @param email character, email address for data manager
#' @param password character, password for data manager
#' @return A list of characters containing the url_base and auth token
#' @export
dm_connect <- function(email, password) {
  user_account <- list(
    email = email,
    password = password
  )

  url_base <- 'https://dynasim-data-manager.urban.org/api'

  response = POST(paste0(url_base, '/users/login/'),
                  body=user_account,
                  encode="json")
  user_token <- content(response)$token
  connection <- list(
      url_base = url_base,
      token = glue("Token {user_token}")
  )
  return(connection)

}

#' Retrieves all projects in the data manager
#'
#' @param con A list of connection information
#' @return A dataframe of projects
#' @export
dm_get_projects <- function(con) {
    url <- paste0(con$url_base, "/projects/")
    response <- GET(
        url,
        add_headers(Authorization = con$token))
    return(fromJSON(content(response, as="text", encoding="UTF-8")))
}

#' Retrieves a single project using its project_id
#'
#' @param con A list of connection information
#' @return A dataframe of project information
#' @export
dm_get_project <- function(con, project_id) {
    url <- paste0(con$url_base, "/projects/", project_id)
    response <- GET(
        url,
        add_headers(Authorization = con$token))
    return(fromJSON(content(response, as="text", encoding="UTF-8")))
}

#' Retrieves all scenarios
#'
#' @param con A list of connection information
#' @return A dataframe of scenarios
#' @export
dm_get_scenarios <- function(con) {
    url <- paste0(con$url_base, "/scenarios/")
    response <- GET(url,
                    add_headers(Authorization = con$token))
    return(fromJSON(content(response, as="text", encoding="UTF-8")))
}

#' Retrieves the scenarios for a project
#'
#' @param con A list of connection information
#' @param project_id, integer identifier for a project
#' @return A dataframe of scenarios
#' @export
dm_get_scenarios_for_project <- function(con, project_id) {
  url <- paste0(con$url_base, "/projects/", project_id, "/scenarios/")
  response <-  GET(url,
          add_headers(Authorization = con$token))
  return(fromJSON(content(response, as="text", encoding="UTF-8")))
}

#' Retrieves the variables for a project
#'
#' @param con A list of connection information
#' @param project_id, integer identifier for a project
#' @return a dataframe containing family and person variables as dataframes
#' @export
dm_get_variables_for_project <- function(con, project_id) {
  url <- paste0(con$url_base, "/projects/", project_id, "/variables/")
  response <- GET(url,
          add_headers(Authorization = con$token))
  variables <- fromJSON(fromJSON(content(response, as="text", encoding="UTF-8")))
  return(variables)
}


#' Requests a dataset to be generated using the requested parameters
#'
#' @param con A list of connection information
#' @param project_name, character
#' @param scenarios, list of characters
#' @param family_variables, list of characters
#' @param person_variables, list of characters
#' @param birth_year_range, list of integers
#' @param year_range, list of integers
#' @return a list of characters containing a job_id and message
#' @export
dm_generate_dataset <- function(
    con,
    project_name,
    scenarios,
    family_variables=list(),
    person_variables=list(),
    birth_year_range=list(),
    year_range=list()) {

  if (!is.vector(scenarios)) {
    stop("Scenarios must be an array.\n")
  }
  if (length(family_variables) == 0 && length(person_variables) == 0) {
    stop("Must specify at least one of family_variables or person_variables.\n")
  }
  if (!(is.vector(family_variables) || is.vector(person_variables))) {
    stop("family_variables and person_variables must be arrays.\n")
    return(NULL)
  }
  if (!is.vector(birth_year_range)) {
    stop("birth_year_range must be an array.\n")
    return(NULL)
  }
  if (!is.vector(year_range)) {
    stop("year_range must be an array.\n")
    return(NULL)
  }

  url <- paste0(con$url_base, "/generate-dataset/")

  payload = list(
    project_name = project_name,
    scenarios = as.list(scenarios),
    person_variables = person_variables,
    family_variables = family_variables,
    birth_year_range = birth_year_range,
    year_range = year_range
  )

  json_payload <- toJSON(payload, auto_unbox = TRUE)

  tryCatch({
    response <- POST(
      url,
      add_headers(
        Authorization = con$token,
        "Content-Type" = "application/json"
      ),
      body=json_payload)

    if (status_code(response) >= 200 && status_code(response) < 300) {
      fromJSON(content(response, as="text", encoding="UTF-8"))
    } else {
      stop("HTTP error: ", status_code(response))
    }
  }, error = function(e) {
    stop("An error occurred: ", e$message)
  })

}

#' Retrieves the status of the job_id returned from dm_generate_dataset().
#' If the dataset has successfully generated, dm_get_dataset_status() will
#' return download links to family and person data files.
#'
#' @param con A list of connection information
#' @param job_id, integer
#' @param file_type, character. 'csv' or 'parquet' ONLY
#' @return a list
#' @export
dm_get_dataset_status <- function(con, job_id, file_type) {
  if (!(file_type %in% c("csv", "parquet"))) {
    stop("file_type must be 'csv' or 'parquet'")
  }
    url <- paste0(con$url_base, "/dataset-status/", job_id, "/", file_type, "/")
    response <- GET(url,
          add_headers(Authorization = con$token))
  return(fromJSON(content(response, as="text", encoding="UTF-8")))
}


#' Using the download link from dm_get_dataset_status(), downloads data
#' files to the specified local path
#'
#' @param presigned_url, character. 'zip' or 'pq' ONLY.
#' @param output_path, character
#' @export
dm_download_file <- function(presigned_url, output_path) {
  if (!grepl("\\.zip$|\\.pq$", output_path)) {
    stop("Output path must use either .zip or .pq")
  }

  tryCatch({
    download.file(presigned_url, output_path, mode="wb")
  }, error = function(e) {
    print(paste("Failed to download file. Error:", e$message))
  })
}

#' Requests and downloads a dataset using dm_generate_dataset(),
#' dm_get_dataset_status(), and dm_download_file
#'
#' @param con A list of connection information
#' @param file_type, 'csv' or 'parquet' ONLY
#' @param output_dir, character
#' @param project_name, character
#' @param scenarios, list of characters
#' @param family_variables, list of characters
#' @param person_variables, list of characters
#' @param birth_year_range, list of integers
#' @param year_range, list of integers
#' @export
dm_request_and_download_datasets <- function(
    con,
    file_type,
    output_dir,
    project_name,
    scenarios,
    family_variables=list(),
    person_variables=list(),
    birth_year_range=list(),
    year_range=list()
    ) {

  if (!(file_type %in% c("csv", "parquet"))) {
    stop("file_type must be 'csv' or 'parquet'")
  }

  response <- dm_generate_dataset(
    con,
    project_name=project_name,
    scenarios=as.list(scenarios),
    family_variables=family_variables,
    person_variables=person_variables,
    birth_year_range=birth_year_range,
    year_range=year_range)

  job_id <- response$job_id
  print(glue("Job successfully submitted. Job ID: {job_id}"))
  job_status <- "PENDING"

  # have function time out after 10 minutes
  timeout_duration <- 10 * 60
  start_time <- Sys.time()

  print("Checking status...")
  while (job_status != "SUCCEEDED") {
    Sys.sleep(5)
    response1 <- dm_get_dataset_status(con, job_id=job_id, file_type=file_type)
    job_status <- response1$job_status
    print(job_status)
    if (!(job_status %in% c("SUCCEEDED", "RUNNING", "STARTING", "WAITING"))) {
      print(http_status(response1)$message)
      stop(glue("Job {job_id} has failed with status {job_status}"))
    }
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    if (elapsed_time > timeout_duration) {
        print(glue("Timeout reached after 10 min. Stopping program for job id {job_id}"))
        break
    }
  }
  if ('family_url' %in% names(response1)) {
      family_url <- response1$family_url
      person_url <- response1$person_url
  } else {
      stop("Could not retrieve family and person URLs. Please try again or check back later.")
  }

  if (file_type=="csv") {
    dm_download_file(family_url, file.path(output_dir, "family_data.zip"))
    dm_download_file(person_url, file.path(output_dir, "person_data.zip"))
  } else if (file_type == "parquet") {
    dm_download_file(family_url, file.path(output_dir, "family_data.pq"))
    dm_download_file(person_url, file.path(output_dir, "person_data.pq"))
  }
  return(TRUE)
}
