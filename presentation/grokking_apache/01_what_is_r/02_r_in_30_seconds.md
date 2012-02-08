!SLIDE incremental

# R in 30 Seconds
* (almost)

!SLIDE code

# Assignment

    a <- b

!SLIDE smaller
# Single Variable Types

* Boolean
* Factors
  * Ordered: ("High", "Medium", "Low")
  * Not: ("Apple", "Orange")
* Integer, Number
* String
* Date/Time/Datetime

!SLIDE smaller
# Homogenous Collection Types

* Vector
  * `a <- c('foo', 'bar', 'baz')`
* Matrix
  * 2D Vector: 
* Array
  * ?D Vector

!SLIDE smaller
# Heterogenous Collection Types

* List
  * Like a `perl` hash
  * `e <- list(thing="hat", size="8.25")`
  * `e$thing <- "ball"`
* Data Frame
  * Like a spreadsheet
  * Columns have names
  * Columns are homogenous

!SLIDE commandline incremental
# R ♥ 's Math

    $ c(1, 2, 3)/c(4, 5, 6)
    [1] 0.25 0.40 0.50 # Don't try that in perl
    
    $ c(1, 2, 3)/2
    [1] 0.5 1.0 1.5

    $ c(1, 2, 3)/c(1, 2)
    [1] 1 1 3
    Warning message:
    In c(1, 2, 3)/c(1, 2) :
      longer object length is not a multiple of 
      shorter object length

    $ c(1, 2, 3, 4)/c(2, 4)
    [1] 0.5 0.5 1.5 1.0 # So green! ♻
    # Example 2 is just a special case then

!SLIDE commandline incremental
# Fun with Indexing

    $ foo <- c(1, 2, 3, 4, 5, 6)
    $ foo[1]
    [1] 1 # 1-indexed, not 0-indexed
    $ foo[c(1, 2, 3)]
    [1] 1 2 3 # index with another vector
    $ foo %% 2
    [1] 1 0 1 0 1 0 # operation on vector = vector
    $ foo[foo %% 2 == 0]
    [1] 2 4 6 # so give me all even numbers
    $ foo[-1]
    [1] 2 3 4 5 6 # (-)index drops items
    $ foo[c(-1,-6)]
    [1] 2 3 4 5 # can do a vector of those too
