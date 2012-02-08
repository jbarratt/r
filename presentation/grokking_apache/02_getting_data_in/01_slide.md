!SLIDE
# Reading Data In

* R has lots of helper functions for reading data
  * CSV, TSV, Spreadsheets
  * SQL
  * [There's a whole manual](http://cran.r-project.org/doc/manuals/R-data.pdf)

!SLIDE
# Our log files

!SLIDE logline

`Dec 25 00:00:03 10.8.1.12 apache2: 115300 somedomain.com 479 465 - 31 0 0 345572 -- 72.122.1.102 - - [25/Dec/2011:00:00:03 -0800] "GET /feed/ HTTP/1.1" 302 - "-" "Windows-RSS-Platform/2.0 (MSIE 8.0; Windows NT 6.0)" "TESTCOOKIE=home; __qca=P0-1723085677-1324437850783; wordpress_eli=1; optimizelyEndUserId=oeu1324440316105r0.4909619414681726; optimizelyBuckets=%7B%2215893198%22%3A15892182%7D"`

!SLIDE

# `read.table()`

* Reads line by line into a data frame
* Splits on whitespace; quote-aware

!SLIDE 

`Dec 25 00:00:03 10.8.1.12 apache2: 115300 somedomain.com 479 465 - 31 0 0 345572 -- 72.122.1.102 - - [25/Dec/2011:00:00:03 -0800] "GET /feed/ HTTP/1.1" 302 - "-" "Windows-RSS-Platform/2.0 (MSIE 8.0; Windows NT 6.0)" "TESTCOOKIE=home; __qca=P0-1723085677-1324437850783; wordpress_eli=1; optimizelyEndUserId=oeu1324440316105r0.4909619414681726; optimizelyBuckets=%7B%2215893198%22%3A15892182%7D"`

* Good news everybody!

!SLIDE code smaller

    parse_apache_log <- function(logfile) {
      log_data <- read.table(file=logfile)
      return(log_data)
    }
    apache_data <- parse_apache_log("~/my_logs.txt")

!SLIDE

# FAIL
* These logs are malformed
* 1k truncation issue 

!SLIDE code smaller
# Preprocessing #1
  
    @@@perl
    my $test = $_;
    $test =~ s/$RE{quoted}//g;
    if($test =~ /\"/) {
      # there should be no quote characters left after 
      # we nuke all quoted strings
      # too hard to tell what kind of 
      # corruption we are dealing with here
      next;
    } else {
      print "$_"; 
    }

!SLIDE smaller
 
# Still blows up

* Column counts don't match
* Adding `fill=TRUE` makes it read lines anyway
* Will deal with bad data in a minute

      @@@r
      parse_apache_log <- function(logfile) {
        log_data <- read.table(file=logfile, fill=TRUE)
        return(log_data)
      }


!SLIDE code smaller

# Name the columns

    @@@r
    parse_apache_log <- function(logfile) {
      colnames <- c("month", "day", "time", "host_ip", "cruft_1", 
        "site_id", "vhost", "in_bytes", "out_bytes", "ssl", 
        "jiffies", "read_ops", "write_ops", "firstbyte_us", 
        "cruft_2", "client_ip", "ident", "userid", "datetime", 
        "timezone", "request", "status", "reply_bytes", "referrer", 
        "user_agent", "cookie")
      log_data <- read.table(file=logfile, col.names = colnames, 
        fill=TRUE)

!SLIDE code smaller

# Nuke the useless columns
  
    @@@r
    colclasses <- c("month"="NULL", "day"="NULL", "time"="NULL", 
      "host_ip"="character", "ssl"="character", 
      "request"="character", "reply_bytes"="character", 
      "cruft_1"="NULL", "cruft_2"="NULL", "ident"="NULL", 
      "userid"="NULL", "timezone"="NULL", "reply_bytes"="NULL", 
      "datetime"="character", "client_ip"="character", 
      "referrer"="character", "user_agent"="character", 
      "cookie"="character")
    
    log_data <- read.table(file=logfile, col.names = colnames, 
      colClasses = colclasses, fill=TRUE)

!SLIDE code smaller

# Now deal with bad logs

    @@@r
    # Logs with NA in odd fields are probably bad.
    # Trash them.
    # Trailing Comma is important; (RC Cola)
    log_data <- log_data[!is.na(log_data$vhost),]

!SLIDE code
# Fix SSL Type (boolean)

    @@@r
    # convert SSL into a boolean
    log_data <- within(log_data, {
        ssl[ssl == "on"] <- T
        ssl[ssl == "-" ] <- F
      })
    log_data$ssl <- as.logical(log_data$ssl)

!SLIDE code smaller
# Fix Timestamps and Status Codes 

    @@@r
    # fix the datestamps to be POSIXlt 
    log_data$datetime <- strptime(log_data$datetime, 
      "[%d/%b/%Y:%H:%M:%S")

    # Status codes are numeric, but are unordered factors
    log_data$status <- as.factor(log_data$status)

!SLIDE code smaller
# Switch from IP to Hostname

    @@@r
    # fix up the host IPs to node names so they are more readable
    log_data$host_ip <- as.factor(sub("^\\d+\\.\\d+\\.\\d+\\.", 
      "n", log_data$host_ip, perl=TRUE))

!SLIDE

# Next mission: How much data is enough data?

* R works best when the data fits in RAM
* How much data do we end up with?

!SLIDE smaller
# Do the math

* 50 million logs a day 
* 450 million lines total
* One Log (614Mb/1.4M lines == 440 bytes/line)
* We want about 500M of logs.
* Turns out, 1.19 Million lines, 1/750 lines

!SLIDE code smaller
    @@@perl
    # Given a set of files (compressed ok)
    # and a sample rate, choose a random subset
    for my $file (@ARGV) {
        my $fh;
        print ".... $file\n";
        if($file =~ /\.gz$/) {
            $fh = new IO::Zlib($file, "rb") or 
              die "Couldn't open $file: $!\n";
        } else {
            $fh = new IO::File($file, "r") or 
              die "couldn't open $file: $!\n";
        }
        while(my $line = $fh->getline()) {
            if(int(rand($opt->{samplerate})) == 0) {
                print $of "$line";
            }
        }
        $fh->close;
    }

!SLIDE commandline

    $ source("~/work/r/apache/log_analysis.r")
    $ full_logs <- parse_apache_log("~/logs_to_grok.txt")
      Error in `[.data.frame`(log_data, !is.na(log_data$vhost)) : 
        undefined columns selected

!SLIDE code

      log_data <- read.table(file=logfile, 
        col.names = colnames, colClasses = colclasses, 
        fill=TRUE)
      
      str(log_data) # great debugging

!SLIDE commandline
# Well THERE's your problem

    $ source("~/work/r/apache/log_analysis.r")
    $ full_logs <- parse_apache_log("~/logs_to_grok.txt")
      'data.frame':412758 obs. of  17 variables:
       $ host_ip     : chr   "10.8.1.12" "10.8.1.26" "10.8.1.14" "10.8.1.25"
      ...
       $ site_id     : Factor w/ 6171 levels
      "","%0A%2F*%0A%D7%90%D7%A4%D7%A9_4_show%2Cja-zin_%D7%9C%D7%99%D7%99%D7%A3%20%D7%A1%D7%98%D7%99%D7%99%D7%9C%0A%2F*%0A%D7%90%D7%A4%D7"|
      __truncated__,..: 129 129 5194 3900 1016 2381 4377 3353 1581 51 ...

!SLIDE

# FAIL (again)

* This time the type of "site" is bad
* Product Bug #2 Discovered!
  * Grokking INDEED

!SLIDE code

    @@@perl
    if(!/apache2:\s+\d+\s+/) {
      # all lines should have 
        # apache2: <siteID>
      # corrupt ones often don't, good filter
      next; # so just skip 'em
    }

!SLIDE commandline

    $ ./apache_log_clean logs.txt > clean_logs.txt
    $  wc -l logs.txt clean_logs.txt 
      412733 logs.txt
      392012 clean_logs.txt #21k bad logs!

!SLIDE
# Making More Columns

## `GET /feed/ HTTP/1.1` is 'Request'
### Let's make it...

* method (GET, POST, PUT, OPTIONS, ...)
* resource (/feed, /, /totoro.jpg)
* http_ver

!SLIDE code smaller
  
    log_data <- data.frame(log_data, 
      colsplit(log_data$request, 
        split = " ", 
        names = 
        c("method", "resource", "http_ver")))

    # unordered factors, again
    log_data$method <- as.factor(log_data$method)
    log_data$http_ver <- as.factor(log_data$http_ver)

!SLIDE code smaller
# Uh oh
## Really? 44 more bad lines?

    Error in data.frame(log_data, 
      colsplit(log_data$request, split = " ",  : 
    arguments imply differing number of rows: 392039, 391995
    In addition: Warning message:
    In function (..., deparse.level = 1)  :
    number of columns of result is not a multiple 
      of vector length (arg 1)

!SLIDE
# FALL BACK! FALL BACK!

* Comment out the new trick so we get raw data in the IDE
* Take a look at the weird lines
* Where strsplit(request, " ") doesn't make 3 parts
* want a `c(TRUE, FALSE)` vector to index the table

!SLIDE commandline incremental
# Putting tricks together

    $ strsplit(c("a b", "a b c"), " ")
    [[1]] # hey look, a vector of vectors (matrix)
    [1] "a" "b"

    [[2]]
    [1] "a" "b" "c"

    $ length(strsplit(c("a b", "a b c"), " "))
    [1] 2 # oops. length does (list) => (number)

!SLIDE
# `sapply`: foreach on crack

`> help(sapply)`


`lapply` returns a list of the same length as `X`, each element of which is
the result of applying `function` to the corresponding element of `X`.

`sapply` is a user-friendly version and wrapper of `lapply`, by default
returning a vector or matrix.

!SLIDE commandline incremental
# `sapply` in Action

    $ sapply(strsplit(c("a b", "a b c"), " "), length)
    [1] 2 3

    > full_logs[sapply(
      strsplit(full_logs$request, " "), length) != 3,]
      $request
    # note trailing comma 
    [1] "GET /2006/upload/post/kellychan0721/last smile.mp3 HTTP/1.1"
    ...
    [8] "" #huh? empty strings?
    [9] "-0800]" #time zone?

    $ full_logs[full_logs$request == "",] # drill down

!SLIDE code smaller
# Let's just trash them

      # Logs with NA in odd fields are probably bad logs. Trash them.
      log_data <- log_data[!is.na(log_data$status),]
      
      # Let's do ones that are still left but have bad requests, too
      log_data <- log_data[!is.na(log_data$request),]
      
      # And jiffies, while we're at it...
      log_data <- log_data[!is.na(log_data$jiffies),]

      # And all the requests that don't have 3 chunks
      log_data <- log_data[sapply(
        strsplit(log_data$request, " "), length) == 3,] 

!SLIDE commandline
# FINALLY. Data == In.

    $ source("~/work/r/apache/log_analysis.r")
    $ full_logs <- parse_apache_log("~/clean_logs.txt")
    $
    :)

!SLIDE full-page
![About To Grok](about_to_grok.jpg "About To Grok")

