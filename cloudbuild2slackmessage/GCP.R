
preloadSecret <- function(secret, jsonNamesToEnvVars = F, credentialsDirectory = '.creds', project_number = Sys.getenv('gcp_project_number')){
  
  require(dplyr)
  
  if(!dir.exists(credentialsDirectory)) dir.create(credentialsDirectory)
  
  # Either grabs local credentials file for local testing or default service account credentials from cloud build.
  token <- gargle::token_fetch(scopes = 'https://www.googleapis.com/auth/cloud-platform', path = glue::glue('{credentialsDirectory}/secrets.json'))
  
  print(glue::glue('Loading secret {secret}'))
  
  endpt <- glue::glue('v1/projects/{project_number}/secrets/{secret}/versions/latest:access')
  
  req <- gargle::request_build(method = 'GET', path = endpt, base_url = 'https://secretmanager.googleapis.com/', token = token)
  
  res <- gargle::request_make(req)
  
  print(endpt)
  print(token)
  print(glue::glue('Token Validated: {token$validate()}'))
  print(res)
  print(httr::content(res))
  
  secret_val <- httr::content(res)$payload$data %>% base64enc::base64decode() %>% rawToChar()
  
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