# load with 'source("..../log_analysis.r")'
# returns a data frame with all the data
library("plyr")

parse_apache_log <- function(logfile) {
  colnames <- c("month", "day", "time", "host_ip", "cruft_1", "site_id", "vhost", "in_bytes", "out_bytes", "ssl", "jiffies", "read_ops", "write_ops", "firstbyte_us", "cruft_2", "client_ip", "ident", "userid", "datetime", "timezone", "request", "status", "reply_bytes", "referrer", "user_agent", "cookie")
  colclasses <- c("month"="NULL", "day"="NULL", "time"="NULL", "host_ip"="character", "ssl"="character", "request"="character", "reply_bytes"="character", "cruft_1"="NULL", "cruft_2"="NULL", "ident"="NULL", "userid"="NULL", "timezone"="NULL", "reply_bytes"="NULL", "datetime"="character", "client_ip"="character", "referrer"="character", "user_agent"="character", "cookie"="character")
  # fill=TRUE makes this more resilient to odd log lines
  log_data <- read.table(file=logfile, col.names = colnames, colClasses = colclasses, fill=TRUE)
  # Logs with NA in odd fields are probably bad logs. Trash them.
  log_data <- log_data[!is.na(log_data$status)]

  # convert SSL into a boolean
  log_data <- within(log_data, {
      ssl[ssl == "on"] <- T
      ssl[ssl == "-" ] <- F
    })
  log_data$ssl <- as.logical(log_data$ssl)
 
  # fix the datestamps to be POSIXlt 
  log_data$datetime <- strptime(log_data$datetime, "[%d/%b/%Y:%H:%M:%S")

  # Status codes are numeric, but are unordered factors
  log_data$status <- as.factor(log_data$status)

  # fix up the host IPs to node names so they are more readable
  log_data$host_ip <- as.factor(sub("^\\d+\\.\\d+\\.\\d+\\.", "n", log_data$host_ip, perl=TRUE))

  #log_data <- data.frame(log_data, colsplit(log_data$request, split = " ", names = c("method", "resource", "http_ver")))
  #log_data$method <- as.factor(log_data$method)
  #log_data$http_ver <- as.factor(log_data$http_ver)

  return(log_data) 
}
