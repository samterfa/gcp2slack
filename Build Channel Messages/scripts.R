
postToSlackChannel <- function(message, webhook_url){
  
  httr::POST(webhook_url, body = list(text = message), encode = 'json')
 
}