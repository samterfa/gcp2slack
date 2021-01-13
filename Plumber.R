
# Grab project number from Google Compute Engine metadata.  See https://cloud.google.com/compute/docs/storing-retrieving-metadata for details.
if(gargle:::detect_gce()){
  
  print('Loading project information from GCE.')
  
  require(dplyr)
  source('GCP.R')
  
  # Must give default compute engine user secret accessor privileges for this to work.
  Sys.setenv(gcp_project_number = gargle:::gce_metadata_request('project/numeric-project-id') %>% httr::content() %>% rawToChar())
  preloadSecret(secret = 'pubsub_json', jsonNamesToEnvVars = F, credentialsDirectory = '.creds', project_number = Sys.getenv('gcp_project_number'))
  preloadSecret(secret = 'slack_buildchannel_webhook', project_number = Sys.getenv('gcp_project_number'))
  
}else{
  # Load gcp_project_number, slack_buildchannel_webhook, and pubsub.json from .Renviron and local .creds directory.
  print('Loading project information from local info.')
}

assertthat::assert_that(Sys.getenv('gcp_project_number') != '', msg = 'Must set gcp_project_number environment variable.')
assertthat::assert_that(file.exists('.creds/pubsub.json'), msg = 'Must create Google Secret named pubsub_json from uploaded pubsub service credentials json!')
assertthat::assert_that(Sys.getenv('slack_buildchannel_webhook') != '', msg = 'Must set slack_buildchannel_webhook in Google Secret Manager!')

# Swagger docs at ...s/__swagger__/ (needs trailing slash!)
if(Sys.getenv('PORT') == '') Sys.setenv(PORT = 8000)

#' @apiTitle GCP Notifications to Slack
#' @apiDescription These endpoints facilitate GCP notifications to Slack.

#* Cloud Build Notifications to Slack
#* 1) Create a pubsub topic named "cloud-builds".
#* 2) Create a subscription to that topic which posts to this endpoint.
#* 3) (Optional but recommended): Enable authentication in the pubsub subscription and this Cloud Run service.
#* @param req The request
#* @param res The response
#* @post /cloudbuild2slack
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

