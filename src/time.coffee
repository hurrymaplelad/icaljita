###
Calendrical calculations on dates values represented as opaque numbers.

Glossary
date: a day such as 1 Jan 1970
date-time: a particular time such as Noon of 1 Jan 1970, but not specific
  to any timezone.
date value: a date or a date-time

Since they are represented as numbers, date values can be compared
with the normal < > == operators.  They may *not* be added or subtracted
though, since this is not a units-since-epoch representation.

We chose not to use a units-since-epoch representation since that doesn't
allow efficient access to fields.  We also ignore seconds and smaller units.

@author mikesamuel@gmail.com
@author adam@hmlad.com 
- Node/Coffeescript port
###

time = module.exports

###
Time representation
===================
Both date and date times are represented as a number with 32 bits.
struct Date {
  signed   year        : 12
  unsigned month       :  4
  unsigned dayOfMonth  :  5
  unsigned minuteInDay : 11
}
This allows us to represent dates in the range
0-01-01 to 4095/12/31 12:59

We do not attempt to represent negative years since those are not
representable in ICAL which specifies that a date has the form
/\d{4}\d{2}\d{2}/.

If Date is a date, the minute is 0, otherwise it is 1 +
the actual minute, causing dates to sort before midnight of that day.
###

###
returns a date or date time value parsed from an ical string.
@param {string} ical
@return {number} a date value.
###
time.parseIcal = (ical) ->
  dateEnd = ical.length
  if dateEnd < 8 then throw new Error('bad ical ' + ical)

  hasTime = ('T' is ical.charAt(dateEnd - 7))
  if hasTime then dateEnd -= 7

  year = Number(ical.substring(0, dateEnd - 4))
  month = Number(ical.substring(dateEnd - 4, dateEnd - 2))
  day = Number(ical.substring(dateEnd - 2, dateEnd))
  if isNaN(year + month + day) then throw new Error('bad ical ' + ical)
  if hasTime
    hour = Number(ical.substring(dateEnd + 1, dateEnd + 3))
    min = Number(ical.substring(dateEnd + 3, dateEnd + 5))
    # ignore seconds
    if isNaN(hour + min) then throw new Error('bad ical ' + ical)
    return time.normalizedDateTime(year, month, day, hour, min)
  else
    return time.normalizedDate(year, month, day)

###
parses a duration from an ical string.
@return {number} of seconds assuming all days are 24 hours and all minutes
     have 60 seconds.
###
###
time.parseDuration = (ical) ->
  match = ical.match(
      /^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/)
  weeks = Number(match[1] || 0)
  days = Number(match[2] || 0)
  hours = Number(match[3] || 0)
  minutes = Number(match[4] || 0)
  seconds = Number(match[5] || 0)
  return time.duration(weeks * 7 + days, hours, minutes, seconds)

###

###
returns an ICAL string representing the given date or date-time value.
@param {number} dateValue
@return {string} ical
###

time.toIcal = (->
  padZero = (n) -> n < 10 and '0'+n or n.toString()
  
  (dateValue) ->
    year = (
      (time.year(dateValue) < 0 and '-' or '') +
      ('0000' + Math.abs(time.year(dateValue)))[-4..-1]
    )
    month = padZero time.month(dateValue)
    day = padZero time.day(dateValue)

    unless time.isDate(dateValue)
      hour = padZero time.hour(dateValue)
      minute = padZero time.minute(dateValue)
      return [year, month, day, 'T', hour, minute, '00'].join ''
    else
      return [year, month, day].join ''
)()

###
Produces a date assuming normalized inputs.
@param {number} year
@param {number} month
@param {number} day
@return {number} a date
###
time.date = (year, month, day) ->
  (((((year + 0x800) << 4) | month) << 5) | day) << 11

###
like {@link time#dateTime} but forces values to be in the appropriate ranges.

<p>The normalization is done so that it is safe to add or subtract a
period fieldwise from a date, and the normalized date will be the proper
number of years,months,days,hour&minutes from the original.
<p>E.g. <code>time.normalizedDate(time.year(d), time.month(d) + 2,
time.day(d) + 1)</code> will return a date 2 months and 1 day later than
d.</p>
@param {number} year
@param {number} month
@param {number} day
@return {number} a date
###
time.normalizedDate = (year, month, day) ->
  while day <= 0
    day += time.daysInYear(if month > 2 then year else year - 1)
    --year

  if month <= 0
    years = ((month / 12) | 0) - 1
    year += years
    month -= 12 * years

  else if month > 12
    years = ((month - 1) / 12) | 0
    year += years
    month -= 12 * years

  while true
    if month is 1
      yearLength = time.daysInYear(year)
      if day > yearLength
        ++year
        day -= yearLength

    monthLength = time.daysInMonth(year, month)
    if day > monthLength
      day -= monthLength
      if ++month > 12
        month -= 12
        ++year
    else
      break

  if year < 0
    year = 0
    month = day = 1
  else if year > 0xfff
    year = 0xfff
    month = 12
    day = 31

  return time.date(year, month, day)

###
produces a date-time given normalized inputs.
 *
@param {number} year
@param {number} month
@param {number} day
@param {number} hour
@param {number} minute
@return {number} a date
###
time.dateTime = (year, month, day, hour, minute) ->
  (
    (((((year + 0x800) << 4) | month) << 5) | day) << 11
  ) | (
    1 + hour * 60 + minute
  )

###
like {@link time#dateTime} but forces values to be in the appropriate ranges.
 *
<p>The normalization is done so that it is safe to add or subtract a
period fieldwise from a date, and the normalized date will be the proper
number of years,months,days,hour&minutes from the original.
<p>E.g.
<code>time.normalizedDateTime(time.year(d), time.month(d) + 2, time.day(d),
time.hour(d), time.minute(d))</code> will return a date 2 months later than d
even if d falls in November or December.</p>
 *
@param {number} year
@param {number} month
@param {number} day
@param {number} hour
@param {number} minute
@return {number} a date
###
time.normalizedDateTime = (year, month, day, hour, minute) ->
  minutes = hour * 60 + minute
  if minutes < 0
    nDays = (((24 * 60 - 1) - minutes) / (24 * 60)) | 0
    minutes += nDays * (24 * 60)
    day -= nDays
  else if minutes >= (24 * 60)
    nDays = (minutes / (24 * 60)) | 0
    minutes -= nDays * (24 * 60)
    day += nDays
  return time.normalizedDate(year, month, day) | (minutes + 1)

###
produces a duration from a number of units.
@param {number} days
@param {number} hours
@param {number} minutes
@param {number} seconds
@return {number} a duration.  Not a dateValue.
###
###
time.duration = (days, hours, minutes, seconds) ->
  return seconds + 60 * (minutes + 60 * (hours + 24 * (days)))

###

###
the year in [0,4097]
@param {number} dateValue
@return {number}
###
time.year = (dateValue) -> (dateValue >> 20) + 2048

###
The input date value but with a different year.
@param {number} dateValue
@param {number} year
@return {number}
###
time.withYear = (dateValue, year) ->
  (dateValue & 0xfffff) | ((year - 2048) << 20)


###
the month in [1,12]
@param {number} dateValue
@return {number}
###
time.month = (dateValue) ->
  (dateValue >> 16) & 0xf

###
The input date value but with a different month.
@param {number} dateValue
@param {number} month
@return {number}
###
time.withMonth = (dateValue, month) ->
  (dateValue & 0xfff0ffff) | ((month & 0xf) << 16)


###
the day of the month in [1,31]
@param {number} dateValue
@return {number}
###
time.day = (dateValue) ->
  (dateValue >> 11) & 0x1f

###
The input date value but with a different day.
@param {number} dateValue
@param {number} day
@return {number}
###
time.withDay = (dateValue, day) ->
  (dateValue & 0xffff07ff) | ((day & 0x1f) << 11)

###
the minute portion in [0,23]
@param {number} dateTime
@return {number}
###
time.hour = (dateTime) ->
  (((dateTime & 0x7ff) - 1) / 60) | 0

###
The input date but with a different hour.
If given a date, has no effect.
@param {number} dateTime
@param {number} day
@return {number}
###
time.withHour = (dateTime, hour) ->
  minutes = dateTime & 0x7ff
  return (
    dateTime & 0xfffff800
  ) | (
    minutes && ((hour & 0x1f) * 60 + ((minutes - 1) % 60) + 1)
  )


###
the minute portion in [0,59]
@param {number} dateTime
@return {number}
###
time.minute = (dateTime) ->
  (((dateTime & 0x7ff) - 1) % 60) | 0


###
The input date but with a different minute.
If given a date, has no effect.
@param {number} dateTime
@param {number} day
@return {number}
###
time.withMinute = (dateTime, minute) ->
  minutes = dateTime & 0x7ff
  (
    dateTime & 0xfffff800
  ) | (
    minutes && (((minute & 0x3f) + 1) + 60 * ((minutes / 60) | 0))
  )


###
the number of minutes from the beginning of the day.
Equivalent to <code>time.hour(dateTime) * 60 + time.minute(dateTime)</code>.
###
time.minuteInDay = (dateTime) ->
  (dateTime & 0x7ff) - 1


###
The input date but with the given time of day.
If given a date, converts to a date-time.
@param {number} dateValue
@param {number} day
@return {number} dateTime
###
time.withTime = (dateValue, hour, minute) ->
  (dateValue & 0xfffff800) | ((hour * 60 + minute + 1) & 0x7ff)


###
Returns dateValue's time components if any with dateValue2's date components.
@param {number} dateValue
@param {number} dateValue2
@return {number} a date if dateValue2 is a date or a date-time otherwise.
###
time.withDate = (dateValue, dateValue2) ->
  (dateValue & 0x7ff) | (dateValue2 & 0xfffff800)


###
true iff the given value is a date, not a date-time.
@param {number} dateValue
@return {boolean} date
###
time.isDate = (dateValue) ->
  not (dateValue & 0x7ff)


###
returns the same date if this is a date, otherwise the date portion of
the given date-time.
@param {number} dateValue
@return {number} date
###
time.toDate = (dateValue) ->
  dateValue & 0xfffff800


###
the earliest day that doesn't contain any seconds before the given date
or date time.
@param {number} dateValue
@return {number} date
###
time.toDateOnOrAfter = (dateValue) ->
  minutes = (dateValue & 0x7ff) - 1
  if (minutes <= 0)
    # is either a date or midnight
    dateValue & 0xfffff800
  else
    time.nextDate(dateValue & 0xfffff800)


###
the same value if the given value is a date-time, or midnight of the given
day otherwise.
@param {number} dateValue
@return {number} date-time
###
time.toDateTime = (dateValue) ->
  dateValue & 0x7ff ? dateValue : (dateValue | 1)


###
The day after the given day, with the same time of day if any.
This allows efficient iteration over days.
@param {number} dateValue
@return {number}
###
time.nextDate = (dateValue) ->
  if (dateValue & 0xf800) < (28 << 11)
    # simple case works (12*27/365.25) 88.7% of the time
    return dateValue + (1 << 11)

  day = time.day(dateValue)
  month = time.month(dateValue)
  year = time.year(dateValue)
  if day < time.daysInMonth(year, month)
    return dateValue + (1 << 11) # reached 8% of the time
  else
    # final (12/365.25) 3.3% may step to next year
    if ++month > 12
      month = 1
      if (++year > 0xfff) then throw new Error('year overflow')
    return time.date(year, month, 1) | (dateValue & 0x7ff)

###
@param {number} year
@return {boolean}
###
time.isLeapYear = (year) ->
  (year % 4 is 0) && ((year % 100 isnt 0) || (year % 400 is 0))


### 
the number of days in the given year
###
time.daysInMonth = (year, month) ->
  if month isnt 2
    30 + ((if month > 7 then month + 1 else month) & 1)
  else
    if time.isLeapYear(year) then 29 else 28


### 
the number of days in the given year
###
time.daysInYear = (year) ->
  time.isLeapYear(year) and 366 or 365


### 
The index (zero-indexed) of the day in the year
###
time.dayOfYear = (->
  # OPT-NOTE: see if we can optimize this out when time.dayOfYear isn't used.
  daysBeforeFirstOfMonth = [undefined] # In a non leap-year.
  count = 0
  for month in [1..12]
    daysBeforeFirstOfMonth[month] = count
    count += time.daysInMonth(1999, month)

  return (dateValue) ->
    day = time.day(dateValue)
    month = time.month(dateValue)

    doy = day + daysBeforeFirstOfMonth[month]
    # Subtract one when not a leap year since day is one-indexed and
    # day-of-year is zero-indexed.
    unless month > 2 && time.isLeapYear(time.year(dateValue))
      doy -= 1
    return doy
)()

###
the number of days between two dates, which will be > 0 if the first is
later.  This ignores any time-of-day portion.
@param {number} dateValue1
@param {number} dateValue2
@return {number} days
###
time.daysBetween = (dateValue1, dateValue2) ->
  if (dateValue1 & 0xffff0000) is (dateValue2 & 0xffff0000)
    # Optimization -- if in same month just subtract day of month.
    # In practice, checks in the same month far outnumber checks across
    # months.
    ((dateValue1 & 0x0000f800) - (dateValue2 & 0x0000f800)) >> 11

  time.fixedFromGregorian(dateValue1) - time.fixedFromGregorian(dateValue2)

###
time.durationBetween = (dateValue1, dateValue2) ->
  m1 = time.isDate(dateValue1) ? time.minuteInDay(dateValue1) : 0
  m2 = time.isDate(dateValue2) ? time.minuteInDay(dateValue2) : 0

  return time.daysBetween(dateValue1, dateValue2) * 86400 + (m1 - m2) * 60
###


###
the day of the week that the given date or date-time falls on.
@param {number} dateValue
@return {WeekDay}
###
time.weekDayOf = (dateValue) ->
  dayOffset = time.fixedFromGregorian(dateValue) % 7
  if dayOffset < 0 then dayOffset += 7
  return dayOffset


###
nDays after the given date or date time.
@param {number} dateValue
@param {number} nDays an integral number of days.
@return {number} a normalized date if dateValue has not time, or a normalized
    date time otherwise.
###
time.plusDays = (dateValue, nDays) ->
  if time.isDate(dateValue)
    time.normalizedDate(
      time.year(dateValue)
      time.month(dateValue)
      time.day(dateValue) + nDays
    )
  else
    time.normalizedDateTime(
      time.year(dateValue)
      time.month(dateValue)
      time.day(dateValue) + nDays,
      time.hour(dateValue)
      time.minute(dateValue)
    )

###
time.plusSeconds = (dateTime, nSeconds) ->
  return time.normalizedDateTime(
        time.year(dateTime), time.month(dateTime), time.day(dateTime),
        time.hour(dateTime), time.minute(dateTime) + ((nSeconds / 60) | 0))
###

###
Adds a duration as parsed by {@code time.parseDuration}.
@param {number} dateValue
@param {number} duration
@return {number} a date iff dateValue is a date.
###
###
time.plusDuration = (dateValue, duration) ->
  if (time.isDate(dateValue)) {
    return time.plusDays(dateValue, (duration / 86400) | 0)
  } else {
    return time.plusSeconds(dateValue, duration)
  }
###

###
Convert a date value into a number of days since <em>epoch</em>,
which is the imaginary beginning of year zero in a hypothetical
backward extension of the Gregorian calendar through time.
See Calendrical Calculations, Reingold and Dershowitz.
@param {number} dateValue
@param {number} of days since an epoch.
###
time.fixedFromGregorian = (dateValue) ->
  year = time.year(dateValue)
  month = time.month(dateValue)
  day = time.day(dateValue)
  yearM1 = year - 1
  return 365 * yearM1 +
    ((yearM1 / 4) | 0) -
    ((yearM1 / 100) | 0) +
    ((yearM1 / 400) | 0) +
    (((367 * month - 362) / 12) | 0) +
    (if month <= 2 then 0 else (if time.isLeapYear(year) then -1 else -2)) +
    day


###
Are the two date values in the same month of the same year?
@param {number} d0 a date value
@param {number} d1 a date value
@return {boolean}
###
time.sameMonth = (d0, d1) ->
  (d0 & 0xffff0000) is (d1 & 0xffff0000)


# Represent the min and max as date values so that timezone conversions don't
# cause underflow/overflow.
time.MAX_DATE_VALUE = time.date(0xfff, 12, 31)
time.MIN_DATE_VALUE = time.date(0, 1, 1)
