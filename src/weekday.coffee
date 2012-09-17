###
@fileoverview
An enumeration of weekdays.
@author mikesamuel@gmail.com
@author adam@hmlad.com
   - port to node/coffescript
###


###
Agrees with {code Date.getDay()}.
@enum {number}
###
module.exports = WeekDay =
  SU: 0
  MO: 1
  TU: 2
  WE: 3
  TH: 4
  FR: 5
  SA: 6

WeekDay.successor = (weekDay) ->
  (weekDay + 1) % 7

WeekDay.predecessor = (weekDay) ->
  (weekDay + 6) % 7

WeekDay.names = []
(->
  # Create a reverse mapping of enum values to names.
  for k of WeekDay
    continue  unless WeekDay.hasOwnProperty(k)
    v = Number(WeekDay[k])
    # Is a non-negative integer.
    WeekDay.names[v] = k  if v is (v & 0x7fffffff)
)()
