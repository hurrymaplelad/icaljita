time = require '../src/time'

describe 'parseIcal', ->
  it 'parses iCal formatted date strings into icaljita dates', ->
    expect(time.parseIcal('20061125')).toEqual time.date(2006, 11, 25)
    expect(time.parseIcal('19001125')).toEqual time.date(1900, 11, 25)
    expect(time.parseIcal('19000228')).toEqual time.date(1900, 2, 28)
    expect(time.parseIcal('20061125T110000'))
      .toEqual time.dateTime(2006, 11, 25, 11, 0, 0)
    expect(time.parseIcal('20061125T113000'))
      .toEqual time.dateTime(2006, 11, 25, 11, 30, 0)
    expect(time.parseIcal('20061125T000000'))
      .toEqual time.dateTime(2006, 11, 25, 0, 0, 0)
    
  it 'normalizes parsed dates', ->
    # 2400 -> next day
    expect(time.parseIcal('20061125T240000'))
      .toEqual time.dateTime(2006, 11, 26, 0, 0, 0)
  
  describe 'bad strings', ->
    badStrings = [
      '20060101T', 'foo', '', '123', '1234',
      'D123456', 'P1D', '20060102/20060103',
      null, undefined, '20060101T12',
      '20060101TT120', '2006Ja01'
    ]
    for string in badStrings
      it "fails for #{string}", ->
        expect(-> time.parseIcal(string)).toThrow()

describe 'date', ->
  it 'creates icaljita dates', ->
    expect(time.date(2006, 1, 1)).toEqual time.date(2006, 1, 1)
    expect(time.date(2006, 1, 1)).toBeLessThan time.date(2006, 1, 2)
    expect(time.date(2006, 1, 1)).toBeLessThan time.date(2006, 2, 1)
    expect(time.date(2006, 1, 3)).toBeLessThan time.date(2006, 2, 1)
    expect(time.date(2005, 12, 31)).toBeLessThan time.date(2006, 1, 1)
    expect(time.date(1, 1, 1)).toEqual time.date(1, 1, 1)
    expect(time.date(1, 1, 1)).toBeLessThan time.date(1, 1, 2)
    expect(time.date(1, 1, 1)).toBeLessThan time.date(2006, 1, 1)
    expect(time.date(1, 1, 1)).toBeLessThan time.date(1, 2, 1)
    expect(time.date(0, 12, 31)).toBeLessThan time.date(1, 1, 1)
    expect(time.MIN_DATE_VALUE).toBeLessThan time.MAX_DATE_VALUE

describe 'dateTime', ->
  it 'creates icaljita dateTimes', ->
    expect(time.dateTime(2006, 1, 1, 0, 0))
      .toEqual time.dateTime(2006, 1, 1, 0, 0)
    expect(time.dateTime(2006, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(2006, 1, 1, 1, 0)
    expect(time.dateTime(2006, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(2006, 1, 1, 0, 1)
    expect(time.dateTime(2006, 1, 1, 12, 59))
      .toBeLessThan time.dateTime(2006, 1, 2, 0, 0)
    expect(time.dateTime(2006, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(2006, 1, 2, 0, 0)
    expect(time.dateTime(2006, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(2006, 2, 1, 0, 0)
    expect(time.dateTime(2006, 1, 3, 0, 0))
      .toBeLessThan time.dateTime(2006, 2, 1, 0, 0)
    expect(time.dateTime(2005, 12, 31, 0, 0))
      .toBeLessThan time.dateTime(2006, 1, 1, 0, 0)
    expect(time.dateTime(1, 1, 1, 0, 0))
      .toEqual time.dateTime(1, 1, 1, 0, 0)
    expect(time.dateTime(1, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(1, 1, 2, 0, 0)
    expect(time.dateTime(1, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(2006, 1, 1, 0, 0)
    expect(time.dateTime(1, 1, 1, 0, 0))
      .toBeLessThan time.dateTime(1, 2, 1, 0, 0)
    expect(time.dateTime(0, 12, 31, 0, 0))
      .toBeLessThan time.dateTime(1, 1, 1, 0, 0)

  it 'can be compared with dates', ->
    expect(time.date(2006, 1, 1))
      .toBeLessThan time.dateTime(2006, 1, 1, 0, 0)
    expect(time.dateTime(2006, 1, 1, 12, 59))
      .toBeLessThan time.date(2006, 1, 2)


describe 'normalizedDate', ->
  it 'normalizes overflown and negative date attributes', ->
    expect(time.toIcal(time.normalizedDate(2006,  2, 29))).toEqual '20060301'
    expect(time.toIcal(time.normalizedDate(2006, 22, 1))).toEqual '20071001'
    expect(time.toIcal(time.normalizedDate(2006, -4, 1))).toEqual '20050801'
    expect(time.toIcal(time.normalizedDate(2006,  4, 50))).toEqual '20060520'
    expect(time.toIcal(time.normalizedDate(2006,  4, 0))).toEqual '20060331'
    expect(time.toIcal(time.normalizedDate(2006,  4, -10))).toEqual '20060321'

    expect(time.toIcal(time.normalizedDate(2006, -13, 15))).toEqual '20041115'
    expect(time.toIcal(time.normalizedDate(2006, -12, 15))).toEqual '20041215'
    expect(time.toIcal(time.normalizedDate(2006, -11, 15))).toEqual '20050115'
    expect(time.toIcal(time.normalizedDate(2006,   0, 15))).toEqual '20051215'
    expect(time.toIcal(time.normalizedDate(2006,  11, 15))).toEqual '20061115'
    expect(time.toIcal(time.normalizedDate(2006,  12, 15))).toEqual '20061215'
    expect(time.toIcal(time.normalizedDate(2006,  13, 15))).toEqual '20070115'
    expect(time.toIcal(time.normalizedDate(2006,  35, 15))).toEqual '20081115'
    expect(time.toIcal(time.normalizedDate(2006,  36, 15))).toEqual '20081215'
    expect(time.toIcal(time.normalizedDate(2006,  37, 15))).toEqual '20090115'

    expect(time.toIcal(time.normalizedDate(2006, 4, 10015))).toEqual '20330831'
    expect(time.toIcal(time.normalizedDate(2006, 4, -9985))).toEqual '19781128'


describe 'normalizedDateTime', ->
  it 'normalizes overflown and negative attributes', ->
    expect(time.toIcal(time.normalizedDateTime(2006,  2, 29, 12, 0)))
      .toEqual '20060301T120000'
    expect(time.toIcal(time.normalizedDateTime(2006,  2, 28, 24, 0)))
      .toEqual '20060301T000000'
    expect(time.toIcal(time.normalizedDateTime(2006,  2, 28, 50, 0)))
      .toEqual '20060302T020000'
    expect(time.toIcal(time.normalizedDateTime(2006,  2, 28, 50, 90)))
      .toEqual '20060302T033000'
    expect(time.toIcal(time.normalizedDateTime(2006,  2, 28, -1, 30)))
      .toEqual '20060227T233000'
    expect(time.toIcal(time.normalizedDateTime(2006,  3, 1, -1, 30)))
      .toEqual '20060228T233000'
    expect(time.toIcal(time.normalizedDateTime(2006,  1, 1, -1, 30)))
      .toEqual '20051231T233000'

describe 'year', ->
  it 'returns the integer year of the dateValue', ->
    expect(time.year(time.date(2006, 1, 1))).toEqual 2006
    expect(time.year(time.dateTime(2006, 1, 1, 12, 0))).toEqual 2006
    expect(time.year(time.date(1900, 1, 1))).toEqual 1900
    expect(time.year(time.date(4000, 1, 1))).toEqual 4000
    expect(time.year(time.date(50, 1, 1))).toEqual 50

describe 'month', ->
  it 'returns the integer month of the dateValue', ->
    for month in [1..12]
      expect(time.month(time.date(2006, month, 1))).toEqual month
    expect(time.month(time.dateTime(2006, 6, 1, 12, 59))).toEqual 6

describe 'day', ->
  it 'returns the integer day of the dateValue', ->
    expect(time.day(time.date(2006, 1, 31))).toEqual 31
    expect(time.day(time.dateTime(2006, 1, 27, 12, 0))).toEqual 27
    expect(time.day(time.date(2006, 1, 12))).toEqual 12
    expect(time.day(time.date(3000, 9, 14))).toEqual 14
    expect(time.day(time.date(-47, 3, 15))).toEqual 15

describe 'hour', ->
  it 'returns the integer hour of the dateValue', ->
    expect(time.hour(time.dateTime(2006, 1, 31, 0, 0))).toEqual 0
    expect(time.hour(time.dateTime(2006, 1, 27, 4, 15))).toEqual 4
    expect(time.hour(time.dateTime(2006, 1, 12, 12, 45))).toEqual 12
    expect(time.hour(time.dateTime(3000, 9, 14, 18, 30))).toEqual 18
    expect(time.hour(time.dateTime(-47, 3, 15, 23, 59))).toEqual 23

describe 'minute', ->
  it 'returns the integer minute of the dateValue', ->
    expect(time.minute(time.dateTime(2006, 1, 31, 0, 0))).toEqual 0
    expect(time.minute(time.dateTime(2006, 1, 27, 4, 15))).toEqual 15
    expect(time.minute(time.dateTime(2006, 1, 12, 12, 45))).toEqual 45
    expect(time.minute(time.dateTime(3000, 9, 14, 18, 30))).toEqual 30
    expect(time.minute(time.dateTime(-47, 3, 15, 23, 59))).toEqual 59

describe 'minuteInDay', ->
  it 'returns the integer number of minutes since the start of the day', ->
    expect(time.minuteInDay(time.dateTime(2006, 1, 31, 0, 0))).toEqual 0
    expect(time.minuteInDay(time.dateTime(2006, 1, 27, 4, 15))).toEqual 255
    expect(time.minuteInDay(time.dateTime(2006, 1, 12, 12, 45))).toEqual 765
    expect(time.minuteInDay(time.dateTime(3000, 9, 14, 18, 30))).toEqual 1110
    expect(time.minuteInDay(time.dateTime(-47, 3, 15, 23, 59))).toEqual 1439

describe 'isDate', ->
  it 'is false for dateTimes', ->
    expect(time.isDate(time.date(2006, 1, 1))).toBeTruthy()
    expect(time.isDate(time.date(2006, 12, 31))).toBeTruthy()
    expect(time.isDate(time.date(2006, 2, 28))).toBeTruthy()
    expect(time.isDate(time.date(2006, 2, 29))).toBeTruthy()

    expect(time.isDate(time.dateTime(2006, 1, 1, 0, 0))).toBeFalsy()
    expect(time.isDate(time.dateTime(2006, 1, 1, 4, 0))).toBeFalsy()
    expect(time.isDate(time.dateTime(2006, 12, 31, 0, 0))).toBeFalsy()
    expect(time.isDate(time.dateTime(2006, 2, 28, 12, 59))).toBeFalsy()
    expect(time.isDate(time.dateTime(2006, 2, 28, 0, 0))).toBeFalsy()
    expect(time.isDate(time.dateTime(2006, 2, 29, 6, 30))).toBeFalsy()


describe 'plusDays', ->
  it 'adds and subtracts days', ->
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 0)))
      .toEqual '20080101'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), -1)))
      .toEqual '20071231'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), -31)))
      .toEqual '20071201'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 1)))
      .toEqual '20080102'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 30)))
      .toEqual '20080131'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 31)))
      .toEqual '20080201'
    expect(time.toIcal(time.plusDays(time.date(2008, 2, 1), 30)))
      .toEqual '20080302'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 365)))
      .toEqual '20081231'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), 366)))
      .toEqual '20090101'
    expect(time.toIcal(time.plusDays(time.date(2007, 1, 1), 365)))
      .toEqual '20080101'
    expect(time.toIcal(time.plusDays(time.date(2007, 1, 1), 366)))
      .toEqual '20080102'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), -365)))
      .toEqual '20070101'
    expect(time.toIcal(time.plusDays(time.date(2008, 1, 1), -366)))
      .toEqual '20061231'
    expect(time.toIcal(time.plusDays(time.dateTime(2008, 1, 1, 12, 30), -31)))
      .toEqual '20071201T123000'
    expect(time.toIcal(time.plusDays(time.dateTime(2008, 1, 1, 4, 0), 1)))
      .toEqual '20080102T040000'
    expect(time.toIcal(time.plusDays(time.dateTime(2008, 1, 1, 15, 15), 30)))
      .toEqual '20080131T151500'

describe 'nextDate', ->
  it 'returns the day after the given day, with the same time', ->
    expect(time.toIcal(time.nextDate(time.date(2007, 12, 31)))).toEqual '20080101'
    expect(time.toIcal(time.nextDate(time.date(2008, 1, 1)))).toEqual '20080102'
    expect(time.toIcal(time.nextDate(time.date(2008, 1, 2)))).toEqual '20080103'
    expect(time.toIcal(time.nextDate(time.date(2008, 1, 3)))).toEqual '20080104'
    expect(time.toIcal(time.nextDate(time.date(2008, 1, 30)))).toEqual '20080131'
    expect(time.toIcal(time.nextDate(time.date(2008, 1, 31)))).toEqual '20080201'
    expect(time.toIcal(time.nextDate(time.date(2008, 2, 1)))).toEqual '20080202'
    expect(time.toIcal(time.nextDate(time.date(2008, 2, 27)))).toEqual '20080228'
    expect(time.toIcal(time.nextDate(time.date(2008, 2, 28)))).toEqual '20080229'
    expect(time.toIcal(time.nextDate(time.date(2008, 2, 29)))).toEqual '20080301'
    expect(time.toIcal(time.nextDate(time.date(2007, 2, 27)))).toEqual '20070228'
    expect(time.toIcal(time.nextDate(time.date(2007, 2, 28)))).toEqual '20070301'
    expect(time.toIcal(time.nextDate(time.date(2007, 3, 1)))).toEqual '20070302'

    expect(time.toIcal(time.nextDate(time.dateTime(2007, 12, 31, 12, 30)))).toEqual '20080101T123000'
    expect(time.toIcal(time.nextDate(time.dateTime(2008, 1, 1, 4, 30)))).toEqual '20080102T043000'
    expect(time.toIcal(time.nextDate(time.dateTime(2008, 1, 30, 16, 45)))).toEqual '20080131T164500'
    expect(time.toIcal(time.nextDate(time.dateTime(2008, 1, 31, 12, 30)))).toEqual '20080201T123000'

describe 'daysBetween', ->
  it 'returns the number of days between two dates', ->
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2003, 12, 31))).toEqual 0
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2004, 2, 29))).toEqual -60
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2004, 3, 6))).toEqual -66
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2004, 3, 9))).toEqual -69
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2004, 10, 31))).toEqual -305
    expect(time.daysBetween(time.date(2003, 12, 31), time.date(2004, 11, 1))).toEqual -306

    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2003, 12, 31))).toEqual 60
    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2004, 2, 29))).toEqual 0
    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2004, 3, 6))).toEqual -6
    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2004, 3, 9))).toEqual -9
    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2004, 10, 31))).toEqual -245
    expect(time.daysBetween(time.date(2004, 2, 29), time.date(2004, 11, 1))).toEqual -246

    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2003, 12, 31))).toEqual 66
    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2004, 2, 29))).toEqual 6
    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2004, 3, 6))).toEqual 0
    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2004, 3, 9))).toEqual -3
    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2004, 10, 31))).toEqual -239
    expect(time.daysBetween(time.date(2004, 3, 6), time.date(2004, 11, 1))).toEqual -240

    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2003, 12, 31))).toEqual 69
    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2004, 2, 29))).toEqual 9
    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2004, 3, 6))).toEqual 3
    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2004, 3, 9))).toEqual 0
    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2004, 10, 31))).toEqual -236
    expect(time.daysBetween(time.date(2004, 3, 9), time.date(2004, 11, 1))).toEqual -237

    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2003, 12, 31))).toEqual 305
    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2004, 2, 29))).toEqual 245
    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2004, 3, 6))).toEqual 239
    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2004, 3, 9))).toEqual 236
    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2004, 10, 31))).toEqual 0
    expect(time.daysBetween(time.date(2004, 10, 31), time.date(2004, 11, 1))).toEqual -1

    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2003, 12, 31))).toEqual 306
    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2004, 2, 29))).toEqual 246
    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2004, 3, 6))).toEqual 240
    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2004, 3, 9))).toEqual 237
    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2004, 10, 31))).toEqual 1
    expect(time.daysBetween(time.date(2004, 11, 1), time.date(2004, 11, 1))).toEqual 0

    expect(time.daysBetween(time.date(2003, 1, 1), time.date(2004, 1, 1))).toEqual -365
    expect(time.daysBetween(time.date(2004, 1, 1), time.date(2005, 1, 1))).toEqual -366
    expect(time.daysBetween(time.date(2005, 1, 1), time.date(2006, 1, 1))).toEqual -365


describe 'dayOfYear', ->
  it 'returns the index (zero-indexed) of the day in the year', ->
    expect(time.dayOfYear(time.date(2005, 1, 1))).toEqual 0
    expect(time.dayOfYear(time.date(2006, 2, 1))).toEqual 31
    expect(time.dayOfYear(time.date(2007, 3, 1))).toEqual 31 + 28
    expect(time.dayOfYear(time.date(2009, 4, 1))).toEqual 31 + 28 + 31
    expect(time.dayOfYear(time.date(2010, 5, 1))).toEqual 31 + 28 + 31 + 30
    expect(time.dayOfYear(time.date(2011, 5, 1))).toEqual 31 + 28 + 31 + 30
    expect(time.dayOfYear(time.date(2013, 6, 1))).toEqual 31 + 28 + 31 + 30 + 31
    expect(time.dayOfYear(time.date(2014, 7, 1))).toEqual 31 + 28 + 31 + 30 + 31 + 30
    expect(time.dayOfYear(time.date(2015, 8, 1))).toEqual 31 + 28 + 31 + 30 + 31 + 30 + 31
    expect(time.dayOfYear(time.date(2017, 9, 1))).toEqual 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31
    expect(time.dayOfYear(time.date(2018, 10, 1))).toEqual 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30
    expect(time.dayOfYear(time.date(2019, 11, 21))).toEqual 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 20
    expect(time.dayOfYear(time.date(2021, 12, 1))).toEqual 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
    expect(time.dayOfYear(time.date(2022, 12, 31))).toEqual 364

    expect(time.dayOfYear(time.date(2004, 1, 1))).toEqual 0
    expect(time.dayOfYear(time.date(2004, 1, 21))).toEqual 20
    expect(time.dayOfYear(time.date(2004, 2, 1))).toEqual 31
    expect(time.dayOfYear(time.date(2004, 3, 1))).toEqual 31 + 29
    expect(time.dayOfYear(time.date(2008, 4, 1))).toEqual 31 + 29 + 31
    expect(time.dayOfYear(time.date(2012, 5, 1))).toEqual 31 + 29 + 31 + 30
    expect(time.dayOfYear(time.date(2020, 6, 8))).toEqual 31 + 29 + 31 + 30 + 31 + 7
    expect(time.dayOfYear(time.date(2024, 7, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30
    expect(time.dayOfYear(time.date(2028, 8, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30 + 31
    expect(time.dayOfYear(time.date(2032, 9, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31
    expect(time.dayOfYear(time.date(2036, 10, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30
    expect(time.dayOfYear(time.date(2040, 11, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31
    expect(time.dayOfYear(time.date(2044, 12, 1))).toEqual 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
    expect(time.dayOfYear(time.date(2048, 12, 31))).toEqual 365


describe 'toDateOnOrAfter', ->
  it "returns the earliest day that doesn't contain any seconds before the given date", ->
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080101')))).toEqual '20080101'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080102')))).toEqual '20080102'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080615')))).toEqual '20080615'

    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080101T000000')))).toEqual '20080101'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080102T000000')))).toEqual '20080102'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080615T000000')))).toEqual '20080615'

    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080101T000100')))).toEqual '20080102'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080102T120000')))).toEqual '20080103'
    expect(time.toIcal(time.toDateOnOrAfter(time.parseIcal('20080615T235900')))).toEqual '20080616'

describe 'withYear', ->
  it 'returns the input date with a different year', ->
    expect(time.toIcal(time.withYear(time.date(2007, 1, 1), 2007))).toEqual '20070101'
    expect(time.toIcal(time.withYear(time.date(0, 3, 1), 2008))).toEqual '20080301'
    expect(time.toIcal(time.withYear(time.date(2107, 1, 3), 7))).toEqual '00070103'
    expect(time.toIcal(time.withYear(time.date(2007, 6, 15), 2007))).toEqual '20070615'
    expect(time.toIcal(time.withYear(time.date(3007, 11, 14), 2008))).toEqual '20081114'
    expect(time.toIcal(time.withYear(time.dateTime(2007, 4, 1, 12, 45), 3000))).toEqual '30000401T124500'

describe 'withMonth', ->
  it 'returns the input date with a different month', ->
    expect(time.toIcal(time.withMonth(time.date(2007, 1, 1), 1))).toEqual '20070101'
    expect(time.toIcal(time.withMonth(time.date(0, 3, 1), 4))).toEqual '00000401'
    expect(time.toIcal(time.withMonth(time.date(2107, 1, 3), 12))).toEqual '21071203'
    expect(time.toIcal(time.withMonth(time.date(2007, 6, 15), 7))).toEqual '20070715'
    expect(time.toIcal(time.withMonth(time.date(3007, 11, 14), 1))).toEqual '30070114'
    expect(time.toIcal(time.withMonth(time.dateTime(2007, 4, 1, 12, 45), 12))).toEqual '20071201T124500'

describe 'withDay', ->
  it 'returns the input date with a different day', ->
    expect(time.toIcal(time.withDay(time.date(2007, 1, 1), 1))).toEqual '20070101'
    expect(time.toIcal(time.withDay(time.date(0, 3, 1), 4))).toEqual '00000304'
    expect(time.toIcal(time.withDay(time.date(2107, 1, 3), 31))).toEqual '21070131'
    expect(time.toIcal(time.withDay(time.date(2007, 6, 15), 7))).toEqual '20070607'
    expect(time.toIcal(time.withDay(time.date(3007, 11, 14), 1))).toEqual '30071101'
    expect(time.toIcal(time.withDay(time.dateTime(2007, 4, 1, 12, 45), 12))).toEqual '20070412T124500'

describe 'withHour', ->
  it 'returns the input date with a different hour', ->
    expect(time.toIcal(time.withHour(time.dateTime(2007, 4, 1, 12, 45), 12))).toEqual '20070401T124500'
    expect(time.toIcal(time.withHour(time.dateTime(2007, 6, 6, 12, 45), 3))).toEqual '20070606T034500'
    expect(time.toIcal(time.withHour(time.dateTime(2007, 12, 31, 12, 45), 23))).toEqual '20071231T234500'
    expect(time.toIcal(time.withHour(time.date(2007, 12, 31), 23))).toEqual '20071231'

describe 'withMinute', ->
  it 'returns the input date with different minutes', ->
    expect(time.toIcal(time.withMinute(time.dateTime(2007, 4, 1, 12, 45), 45))).toEqual '20070401T124500'
    expect(time.toIcal(time.withMinute(time.dateTime(2007, 6, 6, 12, 45), 15))).toEqual '20070606T121500'
    expect(time.toIcal(time.withMinute(time.dateTime(2007, 12, 31, 12, 45), 59))).toEqual '20071231T125900'
    expect(time.toIcal(time.withMinute(time.date(2007, 12, 31), 23))).toEqual '20071231'

describe 'withTime', ->
  it 'returns the input date with different time', ->
    expect(time.toIcal(time.withTime(time.dateTime(2007, 4, 1, 12, 45), 12, 45))).toEqual '20070401T124500'
    expect(time.toIcal(time.withTime(time.dateTime(2007, 6, 6, 12, 45), 3, 1))).toEqual '20070606T030100'
    expect(time.toIcal(time.withTime(time.dateTime(2007, 12, 31, 12, 45), 23, 59))).toEqual '20071231T235900'
    expect(time.toIcal(time.withTime(time.date(2007, 12, 31), 6, 15))).toEqual '20071231T061500'
