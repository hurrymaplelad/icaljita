time = require './time'

###
@fileoverview
Complements to generators (see generators.js) that filter out dates which
do not match some criteria.

The generators are stateful objects that generate candidate dates, and
filters are stateless predicates that accept or reject candidate dates.

An example of a filter is the BYDAY in the rule below
RRULE:FREQ=MONTHLY;BYMONTHDAY=13;BYDAY=FR   # Every Friday the 13th

The BYMONTHDAY generator generates the 13th of the month, and a BYDAY
filter rejects any that are not Fridays.

This could be done the other way -- a BYDAY generator could generate all
Fridays which could then be rejected if they were not the 13th day of the
month, but rrule.js chooses generators so as to minimize the number of
candidates.

Filters are represented as pure functions from dateValues to booleans.

@author mikesamuel@gmail.com
@author adam@hmlad.com 
- Node/Coffeescript port
###

module.exports = filters =
  
  ###
  constructs a day filter based on a BYDAY rule.
  @param {Array.<WeekDayNum>} days
  @param {boolean} weeksInYear are the week numbers meant to be weeks in the
  current year, or weeks in the current month.
  @param {WeekDay} wkst the day of the week on which the week starts.
  ###
  byDayFilter: (days, weeksInYear, wkst) ->
    (dateValue) ->
      dow = time.weekDayOf(dateValue)
      nDays = undefined
      
      # First day of the week in the given year or month
      dow0 = undefined
      
      # Where does date appear in the year or month?
      # in [0, lengthOfMonthOrYear - 1]
      instance = undefined
      if weeksInYear
        nDays = time.daysInYear(time.year(dateValue))
        
        # Day of week of the 1st of the year.
        dow0 = time.weekDayOf(time.date(time.year(dateValue), 1, 1))
        instance = time.dayOfYear(dateValue)
      else
        nDays = time.daysInMonth(time.year(dateValue), time.month(dateValue))
        
        # Day of week of the 1st of the month.
        dow0 = time.weekDayOf(time.withDay(dateValue, 1))
        instance = time.day(dateValue) - 1
      
      # Which week of the year or month does this date fall on?  1-indexed
      dateWeekNo = undefined
      if wkst <= dow
        dateWeekNo = 1 + ((instance / 7) | 0)
      else
        dateWeekNo = ((instance / 7) | 0)
      
      # TODO(mikesamuel): according to section 4.3.10
      #     Week number one of the calendar year is the first week which
      #     contains at least four (4) days in that calendar year. This
      #     rule part is only valid for YEARLY rules.
      # That's mentioned under the BYWEEKNO rule, and there's no mention
      # of it in the earlier discussion of the BYDAY rule.
      # Does it apply to yearly week numbers calculated for BYDAY rules in
      # a FREQ=YEARLY rule?
      i = days.length

      while --i >= 0
        day = days[i]
        if day.wday is dow
          weekNo = day.num
          return true  if 0 is weekNo
          weekNo = time_util.invertWeekdayNum(day, dow0, nDays)  if weekNo < 0
          return true  if dateWeekNo is weekNo
      return false

  
  ###
  constructs a day filter based on a BYMONTHDAY rule.
  @param {Array.<number>} monthDays days of the month in [-31, 31] !== 0
  ###
  byMonthDayFilter: (monthDays) ->
    (dateValue) ->
      nDays = time.daysInMonth(time.year(dateValue), time.month(dateValue))
      dvDay = time.day(dateValue)
      i = monthDays.length

      while --i >= 0
        day = monthDays[i]
        day += nDays + 1  if day < 0
        return true  if dvDay is day
      false

  
  ###
  constructs a filter that accepts only every interval-th week from the week
  containing dtStart.
  @param {number} interval > 0 number of weeks
  @param {WeekDay} wkst day of the week that the week starts on.
  @param {number} dtStart date value
  ###
  weekIntervalFilter: (interval, wkst, dtStart) ->
    
    # The latest day with day of week wkst on or before dtStart.
    wkStart = time.plusDays(dtStart, -((7 + time.weekDayOf(dtStart) - wkst) % 7))
    (dateValue) ->
      daysBetween = time.daysBetween(dateValue, wkStart)
      
      # date must be before dtStart.  Shouldn't occur in practice.
      daysBetween += (interval * 7 * ((1 + daysBetween / (-7 * interval)) | 0))  if daysBetween < 0
      offset = ((daysBetween / 7) | 0) % interval
      0 is offset

