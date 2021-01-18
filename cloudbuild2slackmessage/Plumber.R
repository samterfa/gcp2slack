
# Fix for gargle preventing other Google Cloud scopes for use in credentials_gce.
credentials_gce2 <- function(scopes = "https://www.googleapis.com/auth/cloud-platform",
                             service_account = "default", ...) {
  gargle:::ui_line("trying credentials_gce()")
  if (!gargle:::detect_gce() || is.null(scopes)) {
    return(NULL)
  }
  
  gce_token <- gargle:::fetch_access_token(scopes, service_account = service_account)
  
  params <- list(
    as_header = TRUE,
    scope = scopes,
    service_account = service_account
  )
  token <- gargle:::GceToken$new(
    credentials = gce_token$access_token,
    params = params,
    # The underlying Token2 class appears to *require* an endpoint and an app,
    # though it doesn't use them for anything in this case.
    endpoint = httr::oauth_endpoints("google"),
    app = httr::oauth_app("google", key = "KEY", secret = "SECRET")
  )
  token$refresh()
  if (is.null(token$credentials$access_token) ||
      !nzchar(token$credentials$access_token)) {
    NULL
  } else {
    token
  }
}

# Grab project number from Google Compute Engine metadata.  See https://cloud.google.com/compute/docs/storing-retrieving-metadata for details.
if(gargle:::detect_gce()){
  
  require(dplyr)
  source('GCP.R')
  # For debugging gargle issues.
  options(gargle_quiet = F)
  
  # Must give default compute engine user secret accessor privileges for this to work.
  Sys.setenv(gcp_project_number = gargle:::gce_metadata_request('project/numeric-project-id') %>% httr::content() %>% rawToChar())
  
  print('Loading project information from GCE.')
  
  token <- credentials_gce2(scopes = c('https://www.googleapis.com/auth/pubsub'), service_account = 'default')
  print(gargle::token_email(token))
  
  # Test pubsub API call with credentials_gce2
  endpt <- glue::glue('v1/projects/{project_number}/topics')
  
  req <- gargle::request_build(method = 'GET', path = endpt, base_url = 'https://pubsub.googleapis.com', token = token)
  
  res <- gargle::request_make(req)
  
  print(res)
  print(httr::content(res))
  
  preloadSecret(secret = 'slack_buildchannel_webhook', project_number = Sys.getenv('gcp_project_number'))
  
}else{
  # Load gcp_project_number, slack_buildchannel_webhook, and pubsub.json from .Renviron and local .creds directory.
  print('Loading project information from local info.')
}

assertthat::assert_that(Sys.getenv('gcp_project_number') != '', msg = 'Must set gcp_project_number environment variable.')
assertthat::assert_that(Sys.getenv('slack_buildchannel_webhook') != '', msg = 'Must set slack_buildchannel_webhook in Google Secret Manager!')

# Swagger docs at ...s/__swagger__/ (needs trailing slash!)
if(Sys.getenv('PORT') == '') Sys.setenv(PORT = 8000)

#' @apiTitle GCP Notifications to Slack Message
#' @apiDescription These endpoints facilitate GCP notifications to Slack.
#* @param req The request
#* @param res The response
#* @post /cloudbuild2slackmessage
#* @serializer text
function(req, res, ...){
  
  require(dplyr)
  source('scripts.R')
  
  buildDetails <- req$body$message$data %>% base64enc::base64decode() %>% rawToChar() %>% jsonlite::fromJSON()
  
  projectId <- buildDetails$projectId
  status <- buildDetails$status
  logUrl <- buildDetails$logUrl
  tag <- buildDetails$tags[[3]] # Not sure on this yet...
  currentTime <- lubridate::now(tz = 'America/Chicago') %>% format('%I:%M %p')
  
  # Will convert to a template at some point.
  postToSlackChannel(message = glue::glue("*{projectId} {tag}*  {status} at {currentTime}  <{logUrl}|View Build Logs>\n"),
                     webhook = Sys.getenv('slack_buildchannel_webhook'))
  
  if(status == 'SUCCESS'){  
    
    startTime <- buildDetails$timing$BUILD$startTime %>% lubridate::as_datetime()
    endTime <- buildDetails$timing$BUILD$endTime %>% lubridate::as_datetime()
    interval <- (endTime - startTime) %>% as.numeric()
    mins <- interval %>% floor()
    secs <- ((interval - mins) * 60) %>% round()
    
    # Will convert to a template at some point.
    postToSlackChannel(message = glue::glue("\n*{projectId} {tag} build time*: {mins} minutes {secs} seconds\n\n"),
                       webhook_url = Sys.getenv('slack_buildchannel_webhook'))
  }
  
  return('')
}

