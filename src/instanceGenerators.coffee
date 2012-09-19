time = require './time'
time_util = require './time_util'

###
@fileoverview
An instance generator operates on groups of generators to generate full
dates, and has the same form as a generator.

@author mikesamuel@gmail.com
@author adam@hmlad
- Node/Coffeescript port
###

module.exports = instanceGenerators = {}

###
a collector that yields each date in the period without doing any set
collecting.

@param {Object} filter a filter as described in filters.js.
@param {Object} yearGenerator
a throttled generator as described in generators.js.
@param {Object} monthGenerator a generator as described in generators.js.
@param {Object} dayGenerator a generator as described in generators.js.
###
instanceGenerators.serialInstanceGenerator = (filter, yearGenerator, monthGenerator, dayGenerator) ->
  generate: (builder) ->
    # Cascade through periods to compute the next date
    loop
      # until we run out of days in the current month
      until dayGenerator.generate(builder)
        # until we run out of months in the current year
        until monthGenerator.generate(builder)
          # if there are more years available fetch one
          unless yearGenerator.generate(builder)
            # otherwise the recurrence is exhausted
            return false
        # apply filters to generated dates
      break if filter(builder[0])
    true

  reset: (builder) ->

###
@param {Array.<number>} setPos indices into all the dates for one of the
recurrences primary periods (a MONTH for FREQ=MONTHLY).
@param {Frequency} freq the primary period which defines how many dates
are collected before applying the BYSETPOS rules.
@param {WeekDay} wkst the day of the week on which the week starts.
@param {Object} filter a filter as described in filters.js.
@param {Object} yearGenerator
a throttled generator as described in generators.js.
@param {Object} monthGenerator a generator as described in generators.js.
@param {Object} dayGenerator a generator as described in generators.js.
###
instanceGenerators.bySetPosInstanceGenerator = (setPos, freq, wkst, filter, yearGenerator,
                                                monthGenerator, dayGenerator) ->
  setPos = time_util.uniquify(setPos)
  
  # Create a simpler generator to generate the dates for a primary period.
  serialInstanceGenerator = instanceGenerators.serialInstanceGenerator(
    filter
    yearGenerator
    monthGenerator
    dayGenerator
  )

  
  # True if all of the BYSETPOS indices are positive.  Negative indices are
  # relative to the end of the period.
  # If they are then we need not iterate every period to exhaustion which is
  # nice for rules like FREQ=YEARLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=50 --
  # the fiftieth weekday of the year.
  # since setPos is sorted.
  allPositive = setPos[0] > 0
  # The maximum SETPOS used to short circuit a period if we have enough.
  maxPos = setPos[setPos.length - 1]
  
  pushback = null
  ###
  Is this the first instance we generate?
  We need to know so that we don't clobber dtStart.
  ###
  first = true
  
  ###
  Do we need to halt iteration once the current set has been used?
  ###
  done = false
  
  ###
  The elements in the current set, filtered by set pos
  ###
  candidates = undefined
  
  ###
  index into candidates.  The number of elements in candidates already
  consumed.
  ###
  i = undefined

  reset: ->
    pushback = null
    first = true
    done = false
    candidates = null
    i = 0

  generate: (builder) ->
    while null is candidates or i >= candidates.length
      return false  if done
      
      # (1) Make sure that builder is appropriately initialized so that
      # we only generate instances in the next set
      d0 = null
      if null isnt pushback
        d0 = pushback
        builder[0] = time.withDate(builder[0], d0)
        pushback = null
      else unless first
        
        # We need to skip ahead to the next item since we didn't exhaust
        # the last period.
        switch freq

          when rrule.Frequence.YEARLY, rrule.Frequency.MONTHLY
            if freq is rrule.Frequency.YEARLY
              return false  unless yearGenerator.generate(builder)
            until monthGenerator.generate(builder)
              return false  unless yearGenerator.generate(builder)

          when rrule.Frequency.WEEKLY
            # Consume because just incrementing date doesn't do anything.
            nextWeek = time_util.nextWeekStart(builder[0], wkst)
            loop
              return false  unless serialInstanceGenerator.generate(builder)
              break unless builder[0] < nextWeek
            d0 = time.toDate(builder[0])
          else
      else
        first = false
      
      # (2) Build a set of the dates in the year/month/week that match
      # the other rule.
      dates = []
      dates.push d0  if null isnt d0
      
      # Optimization: if min(bySetPos) > 0 then we already have absolute
      # positions, so we don't need to generate all of the instances for
      # the period.
      # This speeds up things like the first weekday of the year:
      #     RRULE:FREQ=YEARLY;BYDAY=MO,TU,WE,TH,FR,BYSETPOS=1
      # that would otherwise generate 260+ instances per one emitted
      # TODO(mikesamuel): this may be premature.  If needed, We could
      # improve more generally by inferring a BYMONTH generator based on
      # distribution of set positions within the year.
      limit = (if allPositive then maxPos else Infinity)
      while limit > dates.length
        
        # If we can't generate any, then make sure we return false
        # once the instances we have generated are exhausted.
        # If this is returning false due to some artificial limit, such
        # as the 100 year limit in serialYearGenerator, then we exit
        # via an exception because otherwise we would pick the wrong
        # elements for some uSetPoses that contain negative elements.
        done = true  unless serialInstanceGenerator.generate(builder)
        d = time.toDate(builder[0])
        contained = false
        if null is d0
          d0 = d
          contained = true
        else
          switch freq
            when rrule.Frequency.WEEKLY
              nb = time.daysBetween(d, d0)
              
              # Two dates (d, d0) are in the same week
              # if there isn't a whole week in between them and the
              # later day is later in the week than the earlier day.
              contained = (nb < 7 and ((7 + time.weekDayOf(d) - wkst) % 7) > ((7 + time.weekDayOf(d0) - wkst) % 7))
            when rrule.Frequency.MONTHLY
              contained = time.sameMonth(d0, d)
            when rrule.Frequency.YEARLY
              contained = time.year(d0) is time.year(d)
            else
        if contained
          dates.push d
        else
          
          # reached end of the set
          pushback = d # save d so we can use it later
          break
      
      # (3) Resolve the positions to absolute positions and order them
      absSetPos = undefined
      if allPositive
        absSetPos = setPos
      else
        uAbsSetPos = {}
        j = setPos.length

        while --j >= 0
          p = setPos[j]
          p = dates.length + p + 1  if p < 0
          uAbsSetPos[p] = true
        absSetPos = []
        for k of uAbsSetPos
          absSetPos.push Number(k)
        absSetPos.sort time_util.numericComparator
      candidates = []
      j = 0

      while j < absSetPos.length
        p = absSetPos[j] - 1
        candidates.push dates[p]  if p >= 0 and p < dates.length
        ++j
      i = 0
      unless candidates.length
        
        # none in this region, so keep looking
        candidates = null
        continue
    
    # (5) Emit a date.  It will be checked against the end condition and
    # dtStart elsewhere.
    d = candidates[i++]
    builder[0] = time.withDate(builder[0], d)
    true
