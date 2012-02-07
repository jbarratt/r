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
    log_data <- log_data[!is.na(log_data$status)]

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
