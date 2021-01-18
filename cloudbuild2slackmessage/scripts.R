
postToSlackChannel <- function(payload, webhook_url){
  
  httr::POST(webhook_url, body = payload, encode = 'json')
 
}

formatBuildTime <- function(startTime, endTime){
  
  interval <- (endTime - startTime) %>% as.numeric()
  mins <- interval %>% floor()
  secs <- ((interval - mins) * 60) %>% round()
  
  glue::glue("{mins} minutes {secs} seconds\n\n")
}

buildMessage1 <- function(projectId, status, logUrl, tags, startTime = NULL, endTime = NULL){
  
  currentTime <- lubridate::now(tz = 'America/Chicago') %>% format('%I:%M %p')
  
  msg <- glue::glue("*{projectId} {tags[[3]]}*  {status} at {currentTime}  <{logUrl}|View Build Logs>\n")
  
  if(status == 'SUCCESS') msg <- paste0(msg, "\n\n", glue::glue("*Build Time*: {formatBuildTime(startTime, endTime)}"))
  
  list(text = msg)
}

buildMessage2 <- function(projectId, status, logUrl, tags, startTime = NULL, endTime = NULL){
  
  currentTime <- lubridate::now(tz = 'America/Chicago') %>% format('%I:%M %p')
  
  payload <- list(attachments = list(
    list(color = ifelse(status %in% c('QUEUED', 'WORKING'), 
                        "warning", ifelse(status %in% c('SUCCESS'),
                                          "good", "danger")),
    fields = list(
      list(title = "Script",
           value = glue::glue("{projectId} {tags[[3]]}"),
           short = T),
      list(title = "Status",
           value = glue::glue("{status} at {currentTime} <{logUrl}|View Build Logs>"),
           short = T)
    ))))
  
  if(status == 'SUCCESS') payload$attachments[[1]]$fields <- payload$attachments[[1]]$fields %>% 
    append(list(list(title = "Build Time",
                            value = formatBuildTime(startTime, endTime),
                            short = T)))
  payload
}