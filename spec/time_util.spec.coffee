time = require '../src/time'
time_util = require '../src/time_util'
WeekDay = require '../src/weekday'

WeekDayNum = (num, wday) -> {num, wday}

describe 'dayNumToDate given a weekday number such as -1SU', ->
  describe 'in a month', ->
    dow0 = null
    nDays = null
    d0 = null

    beforeEach ->
        #        March 2006
        # Su Mo Tu We Th Fr Sa
        #           1  2  3  4
        #  5  6  7  8  9 10 11
        # 12 13 14 15 16 17 18
        # 19 20 21 22 23 24 25
        # 26 27 28 29 30 31
        dow0 = WeekDay.WE
        nDays = 31
        d0 = 0

    it 'returns the day of the month that it falls on', ->
      expect(time_util.dayNumToDate(dow0, nDays, 1, WeekDay.WE, d0, nDays)).toEqual 1
      expect(time_util.dayNumToDate(dow0, nDays, 2, WeekDay.WE, d0, nDays)).toEqual 8
      expect(time_util.dayNumToDate(dow0, nDays, -1, WeekDay.WE, d0, nDays)).toEqual 29
      expect(time_util.dayNumToDate(dow0, nDays, -2, WeekDay.WE, d0, nDays)).toEqual 22

      expect(time_util.dayNumToDate(dow0, nDays, 1, WeekDay.FR, d0, nDays)).toEqual 3
      expect(time_util.dayNumToDate(dow0, nDays, 2, WeekDay.FR, d0, nDays)).toEqual 10
      expect(time_util.dayNumToDate(dow0, nDays, -1, WeekDay.FR, d0, nDays)).toEqual 31
      expect(time_util.dayNumToDate(dow0, nDays, -2, WeekDay.FR, d0, nDays)).toEqual 24

      expect(time_util.dayNumToDate(dow0, nDays, 1, WeekDay.TU, d0, nDays)).toEqual 7
      expect(time_util.dayNumToDate(dow0, nDays, 2, WeekDay.TU, d0, nDays)).toEqual 14
      expect(time_util.dayNumToDate(dow0, nDays, 4, WeekDay.TU, d0, nDays)).toEqual 28
      expect(time_util.dayNumToDate(dow0, nDays, 5, WeekDay.TU, d0, nDays)).toEqual 0
      expect(time_util.dayNumToDate(dow0, nDays, -1, WeekDay.TU, d0, nDays)).toEqual 28
      expect(time_util.dayNumToDate(dow0, nDays, -2, WeekDay.TU, d0, nDays)).toEqual 21
      expect(time_util.dayNumToDate(dow0, nDays, -4, WeekDay.TU, d0, nDays)).toEqual 7
      expect(time_util.dayNumToDate(dow0, nDays, -5, WeekDay.TU, d0, nDays)).toEqual 0


  describe 'in a year', ->
    dow0 = null
    nInMonth = null
    nDays = null
    d0 = null

    beforeEach ->
      #        January 2006
      #  # Su Mo Tu We Th Fr Sa
      #  1  1  2  3  4  5  6  7
      #  2  8  9 10 11 12 13 14
      #  3 15 16 17 18 19 20 21
      #  4 22 23 24 25 26 27 28
      #  5 29 30 31

      #      February 2006
      #  # Su Mo Tu We Th Fr Sa
      #  5           1  2  3  4
      #  6  5  6  7  8  9 10 11
      #  7 12 13 14 15 16 17 18
      #  8 19 20 21 22 23 24 25
      #  9 26 27 28

      #           March 2006
      #  # Su Mo Tu We Th Fr Sa
      #  9           1  2  3  4
      # 10  5  6  7  8  9 10 11
      # 11 12 13 14 15 16 17 18
      # 12 19 20 21 22 23 24 25
      # 13 26 27 28 29 30 31

      dow0 = WeekDay.SU
      nInMonth = 31
      nDays = 365
      d0 = 59

    it 'returns the day of the month that it falls on', ->
      # TODO: check that these answers are right
      expect(time_util.dayNumToDate(dow0, nDays, 9, WeekDay.WE, d0, nInMonth)).toEqual 1
      expect(time_util.dayNumToDate(dow0, nDays, 10, WeekDay.WE, d0, nInMonth)).toEqual 8
      expect(time_util.dayNumToDate(dow0, nDays, -40, WeekDay.WE, d0, nInMonth)).toEqual 29
      expect(time_util.dayNumToDate(dow0, nDays, -41, WeekDay.WE, d0, nInMonth)).toEqual 22

      expect(time_util.dayNumToDate(dow0, nDays, 9, WeekDay.FR, d0, nInMonth)).toEqual 3
      expect(time_util.dayNumToDate(dow0, nDays, 10, WeekDay.FR, d0, nInMonth)).toEqual 10
      expect(time_util.dayNumToDate(dow0, nDays, -40, WeekDay.FR, d0, nInMonth)).toEqual 31
      expect(time_util.dayNumToDate(dow0, nDays, -41, WeekDay.FR, d0, nInMonth)).toEqual 24

      expect(time_util.dayNumToDate(dow0, nDays, 10, WeekDay.TU, d0, nInMonth)).toEqual 7
      expect(time_util.dayNumToDate(dow0, nDays, 11, WeekDay.TU, d0, nInMonth)).toEqual 14
      expect(time_util.dayNumToDate(dow0, nDays, 13, WeekDay.TU, d0, nInMonth)).toEqual 28
      expect(time_util.dayNumToDate(dow0, nDays, 14, WeekDay.TU, d0, nInMonth)).toEqual 0
      expect(time_util.dayNumToDate(dow0, nDays, -40, WeekDay.TU, d0, nInMonth)).toEqual 28
      expect(time_util.dayNumToDate(dow0, nDays, -41, WeekDay.TU, d0, nInMonth)).toEqual 21
      expect(time_util.dayNumToDate(dow0, nDays, -43, WeekDay.TU, d0, nInMonth)).toEqual 7
      expect(time_util.dayNumToDate(dow0, nDays, -44, WeekDay.TU, d0, nInMonth)).toEqual 0

describe 'uniquify', ->
  it 'produces a sorted array of unique elements', ->
    ints = [ 1, 4, 4, 2, 7, 3, 8, 0, 0, 3 ]
    ints = time_util.uniquify(ints)
    expect(String(ints)).toEqual "0,1,2,3,4,7,8"

describe 'nextWeekStart', ->
  it 'returns the earliest day on or after d that falls on wkst', ->
    expect(time_util.nextWeekStart(time.date(2006, 1, 23), WeekDay.TU))
      .toEqual time.date(2006, 1, 24)

    expect(time_util.nextWeekStart(time.date(2006, 1, 24), WeekDay.TU))
      .toEqual time.date(2006, 1, 24)

    expect(time_util.nextWeekStart(time.date(2006, 1, 25), WeekDay.TU))
      .toEqual time.date(2006, 1, 31)

    expect(time_util.nextWeekStart(time.date(2006, 1, 23), WeekDay.MO))
      .toEqual time.date(2006, 1, 23)

    expect(time_util.nextWeekStart(time.date(2006, 1, 24), WeekDay.MO))
      .toEqual time.date(2006, 1, 30)

    expect(time_util.nextWeekStart(time.date(2006, 1, 25), WeekDay.MO))
      .toEqual time.date(2006, 1, 30)

    expect(time_util.nextWeekStart(time.date(2006, 1, 31), WeekDay.MO))
      .toEqual time.date(2006, 2, 6)

describe 'countInPeriod', ->
  it 'the number of occurences of dow', ->
    #        January 2006
    #  Su Mo Tu We Th Fr Sa
    #   1  2  3  4  5  6  7
    #   8  9 10 11 12 13 14
    #  15 16 17 18 19 20 21
    #  22 23 24 25 26 27 28
    #  29 30 31
    expect(time_util.countInPeriod(WeekDay.SU, WeekDay.SU, 31)).toEqual 5
    expect(time_util.countInPeriod(WeekDay.MO, WeekDay.SU, 31)).toEqual 5
    expect(time_util.countInPeriod(WeekDay.TU, WeekDay.SU, 31)).toEqual 5
    expect(time_util.countInPeriod(WeekDay.WE, WeekDay.SU, 31)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.TH, WeekDay.SU, 31)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.FR, WeekDay.SU, 31)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.SA, WeekDay.SU, 31)).toEqual 4

    #      February 2006
    #  Su Mo Tu We Th Fr Sa
    #            1  2  3  4
    #   5  6  7  8  9 10 11
    #  12 13 14 15 16 17 18
    #  19 20 21 22 23 24 25
    #  26 27 28
    expect(time_util.countInPeriod(WeekDay.SU, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.MO, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.TU, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.WE, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.TH, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.FR, WeekDay.WE, 28)).toEqual 4
    expect(time_util.countInPeriod(WeekDay.SA, WeekDay.WE, 28)).toEqual 4


describe 'invertWeekdayNum', ->
  it 'computes an absolute week number given a relative one', ->

    #        January 2006
    #  # Su Mo Tu We Th Fr Sa
    #  1  1  2  3  4  5  6  7
    #  2  8  9 10 11 12 13 14
    #  3 15 16 17 18 19 20 21
    #  4 22 23 24 25 26 27 28
    #  5 29 30 31

    # the 1st falls on a sunday, so dow0 == SU
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.SU)
      WeekDay.SU
      31)).toEqual 5
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.MO)
      WeekDay.SU
      31)).toEqual 5
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.TU)
      WeekDay.SU
      31)).toEqual 5
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.WE)
      WeekDay.SU
      31)).toEqual 4
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-2, WeekDay.WE)
      WeekDay.SU
      31)).toEqual 3


    #      February 2006
    #  # Su Mo Tu We Th Fr Sa
    #  1           1  2  3  4
    #  2  5  6  7  8  9 10 11
    #  3 12 13 14 15 16 17 18
    #  4 19 20 21 22 23 24 25
    #  5 26 27 28

    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.SU)
      WeekDay.WE
      28)).toEqual 4
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.MO)
      WeekDay.WE
      28)).toEqual 4
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.TU)
      WeekDay.WE
      28)).toEqual 4
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-1, WeekDay.WE)
      WeekDay.WE
      28)).toEqual 4
    expect(time_util.invertWeekdayNum(
      new WeekDayNum(-2, WeekDay.WE)
      WeekDay.WE
      28)).toEqual 3
