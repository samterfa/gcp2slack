
# Grab project number from Google Compute Engine metadata.  See https://cloud.google.com/compute/docs/storing-retrieving-metadata for details.
if(gargle:::detect_gce()){
  
  print('Loading project information from GCE.')
  
  require(dplyr)
  source('GCP.R')
  
  # For debugging gargle issues.
  options(gargle_quiet = F)
  
  # Must give default compute engine user secret accessor privileges for this to work.
  Sys.setenv(gcp_project_number = gargle:::gce_metadata_request('project/numeric-project-id') %>% httr::content() %>% rawToChar())
  
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

  # Parse build details received from pubsub.
  buildDetails <- req$body$message$data %>% base64enc::base64decode() %>% rawToChar() %>% jsonlite::fromJSON()
  
  projectId <- buildDetails$projectId
  status <- buildDetails$status
  logUrl <- buildDetails$logUrl
  tags <- buildDetails$tags
  
  if(stats == 'SUCCESS'){
    startTime <- buildDetails$timing$BUILD$startTime %>% lubridate::as_datetime()
    endTime <- buildDetails$timing$BUILD$endTime %>% lubridate::as_datetime()
  }
  
  payload <- buildMessage2(projectId, status, logUrl, tags, startTime, endTime)
  
  postToSlackChannel(payload = payload, webhook = Sys.getenv('slack_buildchannel_webhook'))
  
  return('')
}

