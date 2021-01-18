
preloadSecret <- function(secret, jsonNamesToEnvVars = F, localCredentialsJSON = '.creds/cloudbuild2slackmessage.json', project_number = Sys.getenv('gcp_project_number')){
  
  require(dplyr)
  
  print(glue::glue('Loading secret {secret}'))
  
  # Either grabs local credentials file for local testing or acting service account credentials.
  if(file.exists(localCredentialsJSON)){
    token <- gargle::credentials_service_account(scopes = 'https://www.googleapis.com/auth/cloud-platform', path = localCredentialsJSON)
  }else{
    token <- gargle::credentials_gce(scopes = c('https://www.googleapis.com/auth/cloud-platform'), service_account = 'default')
  }
  
  print(gargle::token_email(token))
  
  endpt <- glue::glue('v1/projects/{project_number}/secrets/{secret}/versions/latest:access')
  
  req <- gargle::request_build(method = 'GET', path = endpt, base_url = 'https://secretmanager.googleapis.com/', token = token)
  
  res <- gargle::request_make(req)
  
  if(res$status_code < 300){
    secret_val <- httr::content(res)$payload$data %>% base64enc::base64decode() %>% rawToChar()
  }else{
    stop(httr::content(res))
  }
  
  # By convention, a secret named MySecret_json translates into file MySecret.json.
  if(grepl('_json', secret)){
    
    secret_val <- secret_val %>% jsonlite::fromJSON()
    
    jsonlite::write_json(x = secret_val, path = glue::glue("{credentialsDirectory}/{secret %>% stringr::str_replace('_json', '.json')}"), auto_unbox = T)
    
    # If contents of json simply store multiple secrets, write each one as an environment variable.
    if(jsonNamesToEnvVars){
      for(name in names(secret_val)) eval(parse(text = glue::glue('Sys.setenv({name} = "{secret_val[name]}")')))
    }
    
    # Otherwise the secret is to be written to an environment variable.
  }else{
    eval(parse(text = glue::glue('Sys.setenv({secret} = "{secret_val}")')))
  }
}

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