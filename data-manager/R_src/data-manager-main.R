library(httr)
library(jsonlite)
library(glue)

url_base <- "https://dynasim-data-manager.urban.org/api"

# Connect to api and get login token
connect <- function(email, password) {
  user_account <- list(
    email = email,
    password = password
  )

  url <- glue('{url_base}/users/login/')
  response = POST(url,
                  body=user_account,
                  encode="json")
  user_token <- content(response)$token
  headers <- list(
    Authorization = glue("Token {user_token}")
  )
  return(headers)
}

## List existing projects
list_projects <- function() {
  r = GET(glue("{url_base}/projects/"),
          add_headers(Authorization = glue("{headers}")))
  return(r)
  # print(fromJSON(content(r, "text")))
}

## List scenarios
list_scenarios <- function(project_id) {
  url <- glue("{url_base}/projects/{project_id}/scenarios/")
  r = GET(url,
          add_headers(Authorization = glue("{headers}")))
  return(r)
}

## Rerieve variables for a project
list_variables <- function(project_id) {
  url <- glue("{url_base}/projects/{project_id}/variables/")
  r = GET(url, 
          add_headers(Authorization = glue("{headers}")))
  return(r)
}


## Download a subset of data
generate_dataset <- function(
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

  url <- glue("{url_base}/generate-dataset/")
  
  payload = list(
    project_name = project_name,
    scenarios = scenarios,
    person_variables = person_variables,
    family_variables = family_variables,
    birth_year_range = birth_year_range,
    year_range = year_range
  )
  
  json_payload <- toJSON(payload, auto_unbox = TRUE)
  
  response = POST(
    url,
    add_headers(
      Authorization = glue("{headers}"),
      "Content-Type" = "application/json"
    ),
    body=json_payload)

  return(response)
}

## Get dataset status
get_dataset_status <- function(job_id, file_type) {
  
  r = GET(glue("{url_base}/dataset-status/{job_id}/{file_type}/"),
          add_headers(Authorization = glue("{headers}")))
  return(r)
}

## Download files locally
# Receive response from get_dataset_status and store file locally
download_files <- function(presigned_url, output_path) {
  if (!grepl("\\.zip$|\\.pq$", output_path)) {
    stop("Output path must use either .zip or .pq")
  }

  tryCatch({
    download.file(presigned_url, output_path, mode="wb")
  }, error = function(e) {
    print(paste("Failed to download file. Error:", e$message))
  })
}

request_and_download_datasets <- function(
    file_type,
    output_dir,
    project_name,
    scenarios,
    family_variables=list(),
    person_variables=list(),
    birth_year_range=list(),
    year_range=list()
    ) {
  

  response <- generate_dataset(project_name=project_name,
                   scenarios=scenarios,
                   family_variables=family_variables,
                   person_variables=person_variables,
                   birth_year_range=birth_year_range,
                   year_range=year_range)

  job_id <- content(response)$job_id
  print(glue("Initiating job {job_id}"))
  job_status <- "PENDING"

  while (job_status != "SUCCEEDED") {
    Sys.sleep(5)
    response1 <- get_dataset_status(job_id=job_id, file_type=file_type)
    job_status <- content(response1)$job_status
    print(job_status)
    if (!(job_status %in% c("SUCCEEDED", "RUNNING", "STARTING", "WAITING"))) {
      print(http_status(response1)$message)
      stop(glue("Job {job_id} has failed with status {job_status}"))
    }
  }
  family_url <-  content(response1)$family_url
  person_url <- content(response1)$person_url

  if (file_type=="csv") {
    download_files(family_url, file.path(output_dir, "family_data.zip"))
    download_files(person_url, file.path(output_dir, "person_data.zip"))
  } else if (file_type == "parquet") {
    download_files(family_url, file.path(output_dir, "family_data.pq"))
    download_files(person_url, file.path(output_dir, "person_data.pq"))
  }
  return(TRUE)
}
