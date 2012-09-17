time = require './time'

module.exports = time_util =
  
  ###
  Given an array, produces a sorted array of the unique elements in the same.
  
  Different NaN values are considered the same for purposes of comparison,
  but otherwise comparison is as by the <code>===</code> operator.
  This implementation assumes that array elements coerce to a string
  consistently across subsequent calls.
  
  @param {Array} array
  @return {Array} an array containing only elements in the input that is only
  empty if the input is empty.
  ###
  uniquify: (array) ->
    seen = {}
    uniq = []
    nNumbers = 0

    for el in array.slice().reverse()
      do (el) ->
        switch typeof el
          # Use a different path to optimize for arrays of primitives.
          when 'number'
            ++nNumbers
            return if seen[el]
            seen[el] = true

          when 'boolean', 'undefined'
            return if seen[el]
            seen[el] = true

          when 'string'
            # Need to distinguish '0' from 0.
            k = 's' + el
            return if seen[el]
            seen[el] = true

          else
            # Coercion to a string occurs here.  Use string form as a proxy for
            # hashcode.
            k = 'o' + el
            matches = seen[k]
            if matches
              for match in matches
                return if match is el
            else
              seen[k] = matches = []
            matches.push el

        uniq.push el

    if nNumbers is uniq.length
      uniq.sort(time_util.numericComparator)
    else
      uniq.sort()
    return uniq
   
  ###
  given a weekday number, such as -1SU, returns the day of the month that it
  falls on.
  The weekday number may be refer to a week in the current month in some
  contexts or a week in the current year in other contexts.
  @param {number} dow0 the {@link WeekDay} of the first day in the current
  year/month.
  @param {number} nDays the number of days in the current year/month.
  In [28,29,30,31,365,366].
  @param {number} weekNum -1 in the example above.
  @param {number} dow WeekDay.SU in the example above.
  @param {number} d0 the number of days between the 1st day of the current
  year/month and the first of the current month.
  @param {number} nDaysInMonth the number of days in the current month.
  @return {number} a day of the month or 0 if no such day.
  ###
  dayNumToDate: (dow0, nDays, weekNum, dow, d0, nDaysInMonth) ->
    
    # if dow is wednesday, then this is the date of the first wednesday
    firstDateOfGivenDow = 1 + ((7 + dow - dow0) % 7)
    date = undefined
    if weekNum > 0
      date = ((weekNum - 1) * 7) + firstDateOfGivenDow - d0
    else
      # Count weeks from end of month.
      # Calculate last day of the given dow.
      # Since nDays <= 366, this should be > nDays.
      lastDateOfGivenDow = firstDateOfGivenDow + (7 * 54)
      lastDateOfGivenDow -= 7 * (((lastDateOfGivenDow - nDays + 6) / 7) | 0)
      date = lastDateOfGivenDow + 7 * (weekNum + 1) - d0
    return if date <= 0 or date > nDaysInMonth then 0 else date

  numericComparator: (a, b) ->
    a -= 0
    b -= 0
    if a is b then 0
    else if a < b then -1
    else 1
  
  ###
  Compute an absolute week number given a relative one.
  The day number -1SU refers to the last Sunday, so if there are 5 Sundays
  in a period that starts on dow0 with nDays, then -1SU is 5SU.
  Depending on where its used it may refer to the last Sunday of the year
  or of the month.
  
  @param {WeekDayNum} weekdayNum -1SU in the example above.
  @param {WeekDay} dow0 the day of the week of the first day of the month or
  year.
  @param {number} nDays the number of days in the month or year.
  @return {number} an abolute week number, e.g. 5 in the example above.
  Valid if in [1,53].
  ###
  invertWeekdayNum: (weekdayNum, dow0, nDays) ->
    console.assert weekdayNum.num < 0
    
    # How many are there of that week?
    time_util.countInPeriod(weekdayNum.wday, dow0, nDays) + weekdayNum.num + 1

  
  ###
  the number of occurences of dow in a period nDays long where the first day
  of the period has day of week dow0.
  
  @param {WeekDay} dow a day of the week.
  @param {WeekDay} dow0 the day of the week of the first day of the month or
  year.
  @param {number} nDays the number of days in the month or year.
  ###
  countInPeriod: (dow, dow0, nDays) ->
    
    # Two cases
    #    (1a) dow >= dow0: count === (nDays - (dow - dow0)) / 7
    #    (1b) dow < dow0:  count === (nDays - (7 - dow0 - dow)) / 7
    if dow >= dow0
      1 + (((nDays - (dow - dow0) - 1) / 7) | 0)
    else
      1 + (((nDays - (7 - (dow0 - dow)) - 1) / 7) | 0)

  
  ###
  The earliest day on or after d that falls on wkst.
  @param {number} dateValue
  @param {WeekDay} wkst the day of the week on which the week starts.
  ###
  nextWeekStart: (dateValue, wkst) ->
    delta = (7 - ((7 + (time.weekDayOf(dateValue) - wkst)) % 7)) % 7
    time.plusDays dateValue, delta

