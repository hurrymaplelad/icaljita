###
@fileoverview
Conditions that determine when a recurrence ends.

There are two conditions defined in RFC 2445.
UNTIL conditions iterate until a date is reached or passed.
COUNT conditions iterate until a certain number of results have been
produced.
In the absence of either of those conditions, the recurrence is unbounded.

The COUNT condition is not stateless.

A condition has the form:<pre>
{
  test: function (dateValueUtc) { return shouldContinue; }
  reset: function () { ... }
}</pre>

@author mikesamuel@gmail.com
@author adam@hmlad.com 
- Node/Coffeescript port
###

module.exports = conditions =
  countCondition: (count) ->
    i = count
    return
      test: (dateValueUtc) -> --i >= 0
      reset: -> i = count


  untilCondition: (untilDateValueUtc) ->
    return
      test: (dateValueUtc) -> dateValueUtc <= untilDateValueUtc
      reset: ->


  unboundedCondition: ->
    return
      test: -> true
      reset: ->

