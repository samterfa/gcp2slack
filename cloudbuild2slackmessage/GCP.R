
preloadSecret <- function(secret, jsonNamesToEnvVars = F, localCredentialsJSON = '.creds/cloudbuild2slackmessage.json', project_number = Sys.getenv('gcp_project_number')){
  
  require(dplyr)
  
  print(glue::glue('Loading secret {secret}'))
  
  # Either grabs local credentials file for local testing or acting service account credentials.
  token <- gargle::token_fetch(scopes = 'https://www.googleapis.com/auth/cloud-platform', path = localCredentialsJSON)
  
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