time = require './time'
generators = require './generators'
instanceGenerators = require './instanceGenerators'
conditions = require './conditions'
predicates = require './predicates'
filters = require './filters'


###
@fileoverview
An implementation of RFC 2445 RRULEs in Cajita.

<h4>Glossary</h4>
Period - year|month|day|...<br>
Day of the week - an int in [0-6].  See RRULE_WDAY_* in rrule.js<br>
Day of the year - zero indexed in [0,365]<br>
Day of the month - 1 indexed in [1,31]<br>
Month - 1 indexed integer in [1,12]
Recurrence iterator - an object that produces a series of
monotonically increasing dates.  Provides next, advance, and reset
operations.

<h4>Abstractions</h4>
Generator - a function corresponding to an RRULE part that takes a date and
returns a later (year or month or day depending on its period) within the
next larger period.
A generator ignores all periods in its input smaller than its period.
<p>
Filter - a function that returns true iff the given date matches the subrule.
<p>
Condition - returns true if the given date is past the end of the recurrence.

<p>All the generators and conditions are stateful, but filters are not.
Generators and conditions can be reset via their reset method.

A recurrence iterator has the form:<pre>
{
reset: function () { ... },  // resets to dtStart
next: function () { ...; return time.date* },  // returns a UTC date value
hasNext: function () { return Boolean(...); },  // true if next() will work
// Consumes values until the value returned by next is >= dateValueUtc.
// Possibly more efficient than just consuming values in a loop.
advanceTo: function (dateValueUtc) { ... }
}</pre>

@author mikesamuel@gmail.com
@author adam@hmlad.com 
- Node/Coffeescript port
###

module.exports = rrule = {}
  
###
@enum {number}
###
Frequency =
  SECONDLY: 0
  MINUTELY: 1
  HOURLY: 2
  DAILY: 3
  WEEKLY: 4
  MONTHLY: 5
  YEARLY: 6

###
A weekday & number pattern.
2TU -> 2nd Tuesday of the month or year.
WE -> Every Wednesday of the month or year.
-1FR -> The last Friday of the month or year.
###
WeekDayNum = (ical) ->
  m = ical.match(/^(-?\d+)?(MO|TU|WE|TH|FR|SA|SU)$/i)
  throw new Error("Invalid weekday number: " + ical)  unless m
  return
    wday: WeekDay[m[2].toUpperCase()]
    num: Number(m[1]) or 0


###
create a recurrence iterator from an RRULE or EXRULE.
@param {Object} rule the recurrence rule to iterate with a getAttribute
method that returns the string value corresponding to the given key.
@param {number} dtStart the start of the series, in timezone.
@param {function} timezone the timezone to iterate in.
A function from times in one timezone to times in another.
Takes a date or date-time and
@return {Object} with methods reset, next, hasNext, and advanceTo.
###
createRecurrenceIterator = (rule, dtStart, timezone) ->
  soleValue = (name) ->
    values = rule.getAttribute(name)
    console.assert values is null or values instanceof Array
    values and values[0].toUpperCase()
  apply = (array, xform) ->
    console.assert typeof xform is "function"
    out = []
    if array isnt null
      i = -1
      k = -1
      n = array.length

      while ++i < n
        xformed = xform(array[i])
        out[++k] = xformed  if xformed isnt `undefined`
    out
  intBetween = (minInclusive, maxInclusive) ->
    (v) ->
      n = Number(v)
      return `undefined`  if n isnt (n | 0) # excludes non-ints & NaN
      return `undefined`  unless n >= minInclusive and n <= maxInclusive
      n
  intWithMagBetween = (minInclusive, maxInclusive) ->
    (v) ->
      n = Number(v)
      return `undefined`  if n isnt (n | 0) # excludes non-ints & NaN
      mag = Math.abs(n)
      return `undefined`  unless mag >= minInclusive and mag <= maxInclusive
      n
  positiveInt = (v) ->
    n = Number(v)
    return `undefined`  if n isnt (n | 0) # excludes non-ints & NaN
    return `undefined`  unless n > 0
    n
  console.assert "function" is typeof timezone
  console.assert "number" is typeof dtStart
  console.assert "function" is typeof rule.getAttribute
  freq = Frequency[soleValue("FREQ")]
  wkst = WeekDay[soleValue("WKST")]
  wkst = WeekDay.MO  if wkst is `undefined`
  untilUtc = soleValue("UNTIL") or null
  untilUtc = time.parseIcal(untilUtc.replace(/Z$/, ""))  if untilUtc
  count = positiveInt(soleValue("COUNT")) or null
  interval = positiveInt(soleValue("INTERVAL")) or 1
  byDay = apply(rule.getAttribute("BYDAY"), WeekDayNum)
  byMonth = apply(rule.getAttribute("BYMONTH"), intBetween(1, 12))
  byMonthDay = apply(rule.getAttribute("BYMONTHDAY"), intWithMagBetween(1, 31))
  byWeekNo = apply(rule.getAttribute("BYWEEKNO"), intWithMagBetween(1, 53))
  byYearDay = apply(rule.getAttribute("BYYEARDAY"), intWithMagBetween(1, 366))
  bySetPos = apply(rule.getAttribute("BYSETPOS"), intWithMagBetween(1, Infinity))
  byHour = apply(rule.getAttribute("BYHOUR"), intBetween(0, 23))
  byMinute = apply(rule.getAttribute("BYMINUTE"), intBetween(0, 59))
  bySecond = apply(rule.getAttribute("BYSECOND"), intBetween(0, 59))
  
  # Make sure that BYMINUTE, BYHOUR, and BYSECOND rules are respected if they
  # have exactly one iteration, so not causing frequency to exceed daily.
  startTime = null
  startTime = time.dateTime(0, 1, 1, (if 1 is byHour.length then byHour[0] else tv.hour()), (if 1 is byMinute.length then byMinute[0] else tv.minute()), (if 1 is bySecond.length then bySecond[0] else tv.second()))  if 1 is (byHour.length | byMinute.length | bySecond.length) and not time.isDate(dtStart)
  
  # recurrences are implemented as a sequence of periodic generators.
  # First a year is generated, and then months, and within months, days
  yearGenerator = generators.serialYearGenerator((if freq is Frequency.YEARLY then interval else 1), dtStart)
  monthGenerator = null
  dayGenerator = undefined
  
  # When multiple generators are specified for a period, they act as a union
  # operator.  We could have multiple generators (for day say) and then
  # run each and merge the results, but some generators are more efficient
  # than others, so to avoid generating 53 sundays and throwing away all but
  # 1 for RRULE:FREQ=YEARLY;BYDAY=TU;BYWEEKNO=1, we reimplement some of the
  # more prolific generators as filters.
  # TODO(mikesamuel): don't need a list here
  filterList = []
  
  # Choose the appropriate generators and filters.
  switch freq
    when Frequency.DAILY
      if 0 is byMonthDay.length
        dayGenerator = generators.serialDayGenerator(interval, dtStart)
      else
        dayGenerator = generators.byMonthDayGenerator(byMonthDay, dtStart)
      
      # TODO(mikesamuel): the spec is not clear on this.  Treat the week
      # numbers as weeks in the year.  This is only implemented for
      # conformance with libical.
      filterList.push filters.byDayFilter(byDay, true, wkst)  if 0 isnt byDay.length
    when Frequency.WEEKLY
      
      # week is not considered a period because a week may span multiple
      # months &| years.  There are no week generators, but so a filter is
      # used to make sure that FREQ=WEEKLY;INTERVAL=2 only generates dates
      # within the proper week.
      if 0 isnt byDay.length
        dayGenerator = generators.byDayGenerator(byDay, false, dtStart)
        filterList.push filters.weekIntervalFilter(interval, wkst, dtStart)  if interval > 1
      else
        dayGenerator = generators.serialDayGenerator(interval * 7, dtStart)
      filterList.push filters.byMonthDayFilter(byMonthDay)  if 0 isnt byMonthDay.length
    when Frequency.YEARLY
      if 0 isnt byYearDay.length
        
        # The BYYEARDAY rule part specifies a COMMA separated list of days of
        # the year. Valid values are 1 to 366 or -366 to -1. For example, -1
        # represents the last day of the year (December 31st) and -306
        # represents the 306th to the last day of the year (March 1st).
        dayGenerator = generators.byYearDayGenerator(byYearDay, dtStart)
        filterList.push filters.byDayFilter(byDay, true, wkst)  if 0 isnt byDay.length
        filterList.push filters.byMonthDayFilter(byMonthDay)  if 0 isnt byMonthDay.length
        
        # TODO(mikesamuel): filter byWeekNo and write unit tests
        break
    
    # fallthru to monthly cases
    when Frequency.MONTHLY
      if 0 isnt byMonthDay.length
        
        # The BYMONTHDAY rule part specifies a COMMA separated list of days
        # of the month. Valid values are 1 to 31 or -31 to -1. For example,
        # -10 represents the tenth to the last day of the month.
        dayGenerator = generators.byMonthDayGenerator(byMonthDay, dtStart)
        filterList.push filters.byDayFilter(byDay, Frequency.YEARLY is freq, wkst)  if 0 isnt byDay.length
      
      # TODO(mikesamuel): filter byWeekNo and write unit tests
      else if 0 isnt byWeekNo.length and Frequency.YEARLY is freq
        
        # The BYWEEKNO rule part specifies a COMMA separated list of ordinals
        # specifying weeks of the year.  This rule part is only valid for
        # YEARLY rules.
        dayGenerator = generators.byWeekNoGenerator(byWeekNo, wkst, dtStart)
        filterList.push filters.byDayFilter(byDay, true, wkst)  if 0 isnt byDay.length
      else if 0 isnt byDay.length
        
        # Each BYDAY value can also be preceded by a positive (n) or negative
        # (-n) integer. If present, this indicates the nth occurrence of the
        # specific day within the MONTHLY or YEARLY RRULE. For example,
        # within a MONTHLY rule, +1MO (or simply 1MO) represents the first
        # Monday within the month, whereas -1MO represents the last Monday of
        # the month. If an integer modifier is not present, it means all days
        # of this type within the specified frequency. For example, within a
        # MONTHLY rule, MO represents all Mondays within the month.
        dayGenerator = generators.byDayGenerator(byDay, Frequency.YEARLY is freq and 0 is byMonth.length, dtStart)
      else
        monthGenerator = generators.byMonthGenerator([time.month(dtStart)], dtStart)  if Frequency.YEARLY is freq
        dayGenerator = generators.byMonthDayGenerator([time.day(dtStart)], dtStart)
    else
      throw new Error("Can't iterate more frequently than daily")
  
  # generator inference common to all periods
  if 0 isnt byMonth.length
    monthGenerator = generators.byMonthGenerator(byMonth, dtStart)
  else monthGenerator = generators.serialMonthGenerator((if freq is Frequency.MONTHLY then interval else 1), dtStart)  if null is monthGenerator
  
  # The condition tells the iterator when to halt.
  # The condition is exclusive, so the date that triggers it will not be
  # included.
  condition = undefined
  canShortcutAdvance = true
  if count isnt null
    condition = conditions.countCondition(count)
    
    # We can't shortcut because the countCondition must see every generated
    # instance.
    # TODO(mikesamuel): if count is large, we might try predicting the end
    # date so that we can convert the COUNT condition to an UNTIL condition.
    canShortcutAdvance = false
  else if null isnt untilUtc
    if time.isDate(untilUtc) isnt time.isDate(dtStart)
      
      # TODO(mikesamuel): warn
      if time.isDate(dtStart)
        untilUtc = time.toDate(untilUtc)
      else
        untilUtc = time.withTime(untilUtc, 0, 0)
    condition = conditions.untilCondition(untilUtc)
  else
    condition = conditions.unboundedCondition()
  
  # combine filters into a single function
  filter = undefined
  switch filterList.length
    when 0
      filter = predicates.ALWAYS_TRUE
    when 1
      filter = filterList[0]
    else
      filter = predicates.and(filterList)
  instanceGenerator = undefined
  if bySetPos.length
    switch freq
      when Frequency.WEEKLY, Frequency.MONTHLY
    , Frequency.YEARLY
        instanceGenerator = instanceGenerators.bySetPosInstanceGenerator(bySetPos, freq, wkst, filter, yearGenerator, monthGenerator, dayGenerator)
      else
        
        # TODO(mikesamuel): if we allow iteration more frequently than daily
        # then we will need to implement bysetpos for hours, minutes, and
        # seconds.  It should be sufficient though to simply choose the
        # instance of the set statically for every occurrence except the
        # first.
        # E.g. RRULE:FREQ=DAILY;BYHOUR=0,6,12,18;BYSETPOS=1
        # for DTSTART:20000101T130000
        # will yield
        # 20000101T180000
        # 20000102T000000
        # 20000103T000000
        # ...
        instanceGenerator = instanceGenerators.serialInstanceGenerator(filter, yearGenerator, monthGenerator, dayGenerator)
  else
    instanceGenerator = instanceGenerators.serialInstanceGenerator(filter, yearGenerator, monthGenerator, dayGenerator)
  rruleIteratorImpl dtStart, timezone, condition, filter, instanceGenerator, yearGenerator, monthGenerator, dayGenerator, canShortcutAdvance, startTime

###
@param {number} dtStart the start date of the recurrence
@param timezone the timezone that result dates should be converted
<b>from</b>.  All date fields, parameters, and local variables in this
class are in the tzid_ timezone, unless they carry the Utc suffix.
@param condition a predicate over date-values that determines when the
recurrence ends, applied <b>after</b> the date is converted to UTC.
@param filter a function that applies secondary rules to eliminate some
dates.
@param instanceGenerator a function that applies the various period
generators to generate an entire date.
This may involve generating a set of dates and discarding all but those
that match the BYSETPOS rule.
@param yearGenerator a function that takes a date value and replaces the year
field.
Returns false if no more years available.
@param monthGenerator a function that takes a date value and
replaces the month field.  Returns false if no more months
available in the input's year.
@param dayGenerator a function that takes a date value and replaces
the day of month.  Returns false if no more days available in the
input's month.
@param {boolean} canShortcutAdvance false iff shorcutting advance would break
the semantics of the iteration.  This may happen when, for example, the
end condition requires that it see every item.
@param {number?} a date-time whose hour and minute fields should be used for
the first iteration value.
###
rruleIteratorImpl = (dtStart, timezone, condition, filter, instanceGenerator, yearGenerator, monthGenerator, dayGenerator, canShortcutAdvance, startTime) ->
  
  ###
  a date value that has been computed but not yet yielded to the user.
  @type number?
  ###
  
  ###
  a date value used to build successive results.
  At the start of the building process, contains the last date generated.
  Different periods are successively inserted into it.
  @type number
  ###
  
  ###
  true iff the recurrence has been exhausted.
  @type boolean
  ###
  
  ###
  A box used to shuttle the currentDate to generators for modification.
  @type Array.<number>
  ###
  reset = ->
    condition.reset()
    yearGenerator.reset()
    monthGenerator.reset()
    dayGenerator.reset()
    instanceGenerator.reset()
    pendingUtc = null
    done = false
    currentDate = dtStart
    currentDate = time.withTime(dtStart, time)  if startTime isnt null
    
    # Apply the year and month generators so that we can start with the day
    # generator on the first call to fetchNext.
    try
      builder[0] = currentDate
      yearGenerator.generate builder
      monthGenerator.generate builder
      currentDate = builder[0]
    catch ex # Year generator has done too many cycles without result.
      if ex is generators.STOP_ITERATION
        done = true
      else
        throw ex
    dtStartUtc = timezone(dtStart, false)
    until done
      pendingUtc = generateInstance()
      if pendingUtc is null
        done = true
        break
      else if pendingUtc >= dtStartUtc
        
        # We only apply the condition to the ones past dtStart to avoid
        # counting useless instances
        unless condition.test(pendingUtc)
          done = true
          pendingUtc = null
        break
  hasNext = ->
    fetchNext()  if pendingUtc is null
    pendingUtc isnt null
  next = ->
    fetchNext()  if pendingUtc is null
    nextUtc = pendingUtc
    pendingUtc = null
    nextUtc
  
  ###
  skip over all instances of the recurrence before the given date, so that
  the next call to {@link next} will return a date on or after the given
  date, assuming the recurrence includes such a date.
  ###
  advanceTo = (dateUtc) ->
    dateLocal = timezone(dateUtc, true)
    return  if dateLocal < currentDate
    pendingUtc = null
    try
      if canShortcutAdvance
        
        # skip years before date.year
        if time.year(currentDate) < time.year(dateLocal)
          builder[0] = currentDate
          loop
            unless yearGenerator.generate(builder)
              done = true
              return
            currentDate = builder[0]
            break unless time.year(currentDate) < time.year(dateLocal)
          until monthGenerator.generate(builder)
            unless yearGenerator.generate(builder)
              done = true
              return
          currentDate = builder[0]
        
        # skip months before date.year/date.month
        while time.year(currentDate) is time.year(dateLocal) and time.month(currentDate) < time.month(dateLocal)
          until monthGenerator.generate(builder)
            
            # if there are more years available fetch one
            unless yearGenerator.generate(builder)
              
              # otherwise the recurrence is exhausted
              done = true
              return
          currentDate = builder[0]
      
      # consume any remaining instances
      until done
        dUtc = generateInstance()
        if dUtc is null
          done = true
        else
          unless condition.test(dUtc)
            done = true
          else if dUtc >= dateUtc
            pendingUtc = dUtc
            break
    catch ex # Year generator has done too many cycles without result.
      # Can happen for rules like FREQ=YEARLY;INTERVAL=4;BYMONTHDAY=29 when
      # dtStart is 1 Feb 2001.
      if ex is generators.STOP_ITERATION
        done = true
      else
        throw ex
  
  ###
  calculates and stored the next date in this recurrence.
  ###
  fetchNext = ->
    return  if pendingUtc isnt null or done
    dUtc = generateInstance()
    
    # check the exit condition
    if dUtc isnt null and condition.test(dUtc)
      pendingUtc = dUtc
      
      # Tell the yearGenerator that it generated a valid date, to reset the
      # too many cycles counter.  See the catch blcok above.
      yearGenerator.workDone()
    else
      done = true
  
  ###
  make sure the iterator is monotonically increasing.
  The local time is guaranteed to be monotonic, but because of daylight
  savings shifts, the time in UTC may not be.
  ###
  
  ###
  @return {number} a date value in UTC.
  ###
  generateInstance = ->
    try
      
      # Make sure that the date is monotonically increasing in the output
      # timezone.
      loop
        builder[0] = currentDate
        return null  unless instanceGenerator.generate(builder)
        currentDate = builder[0]
        
        # TODO(mikesamuel): apply byhour, byminute, bysecond rules here
        dUtc = timezone(currentDate, false)
        return dUtc  if dUtc > lastUtc
    catch ex
      
      # Year generator has done too many cycles without result.
      return null  if ex is generators.STOP_ITERATION
      throw ex
  pendingUtc = undefined
  currentDate = undefined
  done = undefined
  builder = [null]
  lastUtc = time.MIN_DATE_VALUE
  reset()
  return
    reset: reset
    next: next
    hasNext: hasNext
    advanceTo: advanceTo

rrule.createRecurrenceIterator = createRecurrenceIterator
rrule.Frequency = Frequency

