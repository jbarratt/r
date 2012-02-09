# load with 'source("..../log_analysis.r")'
# returns a data frame with all the data
library("plyr")

parse_apache_log <- function(logfile) {
  colnames <- c("month", "day", "time", "host_ip", "cruft_1", "site_id", "vhost", "in_bytes", "out_bytes", "ssl", "jiffies", "read_ops", "write_ops", "firstbyte_us", "cruft_2", "client_ip", "ident", "userid", "datetime", "timezone", "request", "status", "reply_bytes", "referrer", "user_agent", "cookie")
  colclasses <- c("month"="NULL", "day"="NULL", "time"="NULL", "host_ip"="character", "ssl"="character", "request"="character", "reply_bytes"="character", "cruft_1"="NULL", "cruft_2"="NULL", "ident"="NULL", "userid"="NULL", "timezone"="NULL", "reply_bytes"="NULL", "datetime"="character", "client_ip"="character", "referrer"="character", "user_agent"="character", "cookie"="character")
  # fill=TRUE makes this more resilient to odd log lines
  logs.full <- read.table(file=logfile, col.names = colnames, colClasses = colclasses, fill=TRUE)

  str(logs.full)

  # Logs with NA in odd fields are probably bad logs. Trash them.
  logs.full <- logs.full[!is.na(logs.full$status),]
  
  # Let's do ones that are still left but have bad requests, too
  logs.full <- logs.full[!is.na(logs.full$request),]
  
  # And jiffies, while we're at it...
  logs.full <- logs.full[!is.na(logs.full$jiffies),]

  # And all the requests that don't have 3 chunks
  logs.full <- logs.full[sapply(strsplit(logs.full$request, " "), length) == 3,]

  # in_bytes and out_bytes end up as factors. Boo.
  logs.full$in_bytes <- as.integer(logs.full$in_bytes)
  logs.full$out_bytes <- as.integer(logs.full$out_bytes)

  # convert SSL into a boolean
  logs.full <- within(logs.full, {
      ssl[ssl == "on"] <- T
      ssl[ssl == "-" ] <- F
    })
  logs.full$ssl <- as.logical(logs.full$ssl)
 
  # fix the datestamps to be POSIXlt 
  logs.full$datetime <- strptime(logs.full$datetime, "[%d/%b/%Y:%H:%M:%S")

  # Status codes are numeric, but are unordered factors
  logs.full$status <- as.factor(logs.full$status)

  # fix up the host IPs to node names so they are more readable
  logs.full$host_ip <- as.factor(sub("^\\d+\\.\\d+\\.\\d+\\.", "n", logs.full$host_ip, perl=TRUE))

  logs.full <- data.frame(logs.full, colsplit(logs.full$request, split = " ", names = c("method", "resource", "http_ver")))
  logs.full$method <- as.factor(logs.full$method)
  logs.full$http_ver <- as.factor(logs.full$http_ver)

  # subset the data to make it easier to work with
  logs.small <- logs.full[sort(sample(1:nrow(logs.full), 10^4, replace=FALSE)),]

  return(list(small=logs.small, full=logs.full)) 
}
