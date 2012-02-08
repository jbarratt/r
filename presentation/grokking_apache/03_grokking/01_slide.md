!SLIDE
# The grokking can begin!
`> summary(full_logs)`
![Groks Already](groks_already.jpg "Groks Already")

!SLIDE commandline incremental
# One little problem

    $ qplot(datetime, firstbyte_us, data=full_logs)
    $ ....
    $ (gets coffee)
    $ (bathroom)
    $ (surfs http://planetr.stderr.org/)
    $ ^C

!SLIDE

# Too much data


### (*for some tasks*)

!SLIDE commandline incremental
# "`:`" and `sample`

    $ 1:10
    [1]  1  2  3  4  5  6  7  8  9 10
    $ sample(1:10, 3, replace=FALSE)
    [1] 10  9  6
    $ sort(sample(1:10, 3))
    [1]  7  8 10
    $ nrow(full_logs)
    [1] 391850 
    $ short_logs <- full_logs[
      sort(sample(1:nrow(full_logs), 10^4,
      replace=FALSE)),]
    $ system.time(
      qplot(jiffies, firstbyte_us, data=short_logs))
     user  system elapsed 
     0.042   0.015   0.063

!SLIDE code smaller
# Bake it in

    # subset the data to make it easier to work with 
    logs.small <- logs.full[
      sort(sample(
        1:nrow(logs.full), 10^4,
        replace=FALSE)),]
    return(
      list(small=logs.small, 
      full=logs.full))
    ...
    logs$small$jiffies

!SLIDE commandline incremental
# It's not the same!
### Still good for finding grok-worth questions faster.

    $ quantile(logs$small$jiffies, c(.5, .8, .9, .95, .99))
    50% 80% 90% 95% 99% 
      0   4  30  49  90 
    $ quantile(logs$full$jiffies, c(.5, .8, .9, .95, .99))
    50% 80% 90% 95% 99% 
      0   4  27  47  88 # close, but not quite the same 
