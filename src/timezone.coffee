###
@fileoverview
A partial javascript timezone library.

A timezone maps date-times in one calendar to date-times in another.
We represent a timezone as a function that takes a date value and returns a
date value.

This glosses over the fact that a calendar can map a given date-time to
0 or 2 instants during daylight-savings/standard transitions as does RFC 2445
itself.

A timezone function takes two arguments,
(1) A time value.
(2) isUtc.

If isUtc is true, then the function maps from UTC to local time,
and otherwise maps from local time to UTC.

Since the function takes both dates and date-times, it could be used to
handle the different Julian<->Gregorian switchover for different locales
though this implementation does not.

@author mikesamuel@gmail.com
@author adam@hmlad.com
- port to node/coffeescript
###

###
@namespace
###
module.exports = timezone = {}

###
@param {number} dateValue
@param {boolean} isUtc
###
timezone.utc = (dateValue, isUtc) ->
  console.assert "number" is typeof dateValue
  dateValue


###
@param {number} dateValue
@param {boolean} isUtc
###
timezone.local = (dateValue, isUtc) ->
  return dateValue  if time.isDate(dateValue)
  jsDate = undefined
  if isUtc
    jsDate = new Date(
      Date.UTC(
        time.year(dateValue)
        time.month(dateValue) - 1
        time.day(dateValue)
        time.hour(dateValue)
        time.minute(dateValue)
        0
      )
    )
    return time.dateTime(
      jsDate.getFullYear()
      jsDate.getMonth() + 1
      jsDate.getDate()
      jsDate.getHours()
      jsDate.getMinutes()
      jsDate.getSeconds()
    )
  else
    jsDate = new Date(
      time.year(dateValue)
      time.month(dateValue) - 1
      time.day(dateValue)
      time.hour(dateValue)
      time.minute(dateValue)
      0
    )
    return time.dateTime(
      jsDate.getUTCFullYear()
      jsDate.getUTCMonth() + 1
      jsDate.getUTCDate()
      jsDate.getUTCHours()
      jsDate.getUTCMinutes()
      jsDate.getUTCSeconds()
    )


###
Given a timezone offset in seconds, returns a timezone function.
@param {number} offsetSeconds
@return {Function}
###
timezone.fromOffset = (offsetSeconds) ->
  ###
  @param {number} dateValue
  @param {boolean} isUtc
  ###
  return (dateValue, isUtc) ->
    if time.isDate(dateValue)
      dateValue
    else
      time.plusSeconds dateValue, (if isUtc then offsetSeconds else -offsetSeconds)
