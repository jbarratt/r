# load with 'source("..../citydiff.r")'
# returns a data frame tagged by city
library("plyr")

citydiff <- function(city1_name, city1_logfile, city2_name, city2_logfile) {

  first_city <- read.csv(city1_logfile);
  second_city <- read.csv(city2_logfile);

  first_city$city <- city1_name;
  second_city$city <- city2_name;

  weather <- rbind(first_city, second_city);
  weather$city <- factor(weather$city, levels=c(city1_name, city2_name))

  # drop the rows that don't have me mean temp
  #weather <- weather[complete.cases(weather[,"Mean.TemperatureF"]),]

  weather$PrecipitationIn <- as.numeric(weather$PrecipitationIn)

  weather$PST <- as.Date(weather$PST, "%Y-%m-%d")

  # want to bucket the data by week number so we can see trends year on year
  weather$weeknum <- sapply(1 + as.POSIXlt(weather$PST)$yday %/% 7, function(x) { min(x, 52)})

  # Also going to want to sum up by months
  weather$month <- factor(format(weather$PST, "%B"), order=TRUE, levels=c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"))

  png(filename="overall_temp_ranges.png", height=354, width=572)
  print(qplot(Max.TemperatureF, color=city, data = weather, geom="density"))
  dev.off()
  
  png(filename="temps_over_year.png", height=354, width=572)
  print(ggplot(weather, aes(x=weeknum, Max.TemperatureF, colour=Max.TemperatureF)) + facet_grid(city~.) + geom_point(alpha=1/6, position=position_jitter(width=3)) + scale_colour_gradient(low="blue", high="red") + geom_hline(yintercept=90) + geom_hline(yintercept=60) + geom_smooth(method="loess", size=1) + scale_x_continuous(formatter=function(x) format(strptime(paste("1990 1 ", x), format="%Y %w %U"), "%B")) + xlab("Month") + ylab("Maximum Temperature (F)"))
  dev.off()
 
  png(filename="cloud_cover_by_week.png", height=354, width=572)
  print(qplot(weeknum, CloudCover, data = weather, geom="smooth", color=city, span=1))
  dev.off()

  png(filename="cloud_cover_improved.png", height=354, width=572)
  print(ggplot(weather, aes(x=weeknum, CloudCover, colour=CloudCover)) + facet_grid(city~.) + geom_point(position=position_jitter(width=0.5, height=0.5), alpha=I(1/6)) + geom_smooth(size=1) + scale_colour_gradient(low="blue", high="black") + scale_x_continuous(formatter=function(x) format(strptime(paste("1990 1 ", x), format="%Y %w %U"), "%B")) + xlab("Month") + ylab("Cloud Cover"))
  dev.off()

  # ideal day:
    # cloud cover <= 2
    # max temp >= 60 && <= 90
  # find the count of those by month. (Or probability? perfect days/total days)
  weather$ideal <- F
  weather <- within(weather, {
      ideal[Max.TemperatureF >= 60 & Max.TemperatureF <= 90 & CloudCover <= 4] <- T
    })
  weather$ideal <- as.logical(weather$ideal)

  png(filename="ideal_by_month.png", height=354, width=572)
  print(ggplot(weather, aes(x=month, fill=ideal)) + geom_histogram() + facet_grid(city~.) + opts(axis.text.x  = theme_text(angle=90, size=10)))
  dev.off()

  ideal_days <- weather[weather$ideal==TRUE,]

  png(filename="ideal_summary.png", height=354, width=572)
  print(qplot(city, data=ideal_days))
  dev.off()

  return(weather)
}
