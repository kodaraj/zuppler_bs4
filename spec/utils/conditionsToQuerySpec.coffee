define ['utils/conditionsToQuery', 'models/condition', 'moment-timezone'], (conditionsUtils, Condition, moment) ->
  { conditionsToQuery } = conditionsUtils
  now = moment.tz("2015-06-09T14:45:00", "Europe/Bucharest")

  describe 'all conditions', ->
    it 'should return valid data', ->
      c = new Condition 'customer_name', '~', 'test'
      expect(conditionsToQuery([c])).toEqual
        "queries[0][field]": 'customer_name'
        "queries[0][op]": '~'
        "queries[0][value]": 'test'

  describe "time conditions", ->
    timezone = "America/Los_Angeles"
    beforeEach ->
      moment.tz().zoneName()
      @fakeTimer = new sinon.useFakeTimers(now.toDate().getTime())

    afterEach ->
      @fakeTimer.restore()


    it "#today", ->
      c = new Condition 'time', '~=', 'today'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-09T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-10T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#tomorrow", ->
      c = new Condition 'time', '~=', 'tomorrow'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-10T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-11T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#yesterday", ->
      c = new Condition 'time', '~=', 'yesterday'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-08T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-09T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#this_week", ->
      c = new Condition 'time', '~=', 'this_week'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-08T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-15T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#last_week", ->
      c = new Condition 'time', '~=', 'last_week'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-01T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-08T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#next_week", ->
      c = new Condition 'time', '~=', 'next_week'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-15T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-22T06:59:59.999Z"
        'queries[0][op]': 'between'

  describe "placed conditions", ->
    timezone = "America/Los_Angeles"
    beforeEach ->
      @fakeTimer = new sinon.useFakeTimers(now.toDate().getTime());
    afterEach ->
      @fakeTimer.restore();

    it "#today", ->
      c = new Condition 'placed', '~=', 'today'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-09T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-10T06:59:59.999Z"
        'queries[0][op]': 'between'

  describe "relative time", ->
    timezone = "America/Los_Angeles"

    beforeEach ->
      @fakeTimer = new sinon.useFakeTimers(now.toDate().getTime())
    afterEach ->
      @fakeTimer.restore()

    it "#relative hour time", ->
      c = new Condition 'time', '~<>', count: 2, unit: 'hour'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-09T13:00:00.000Z" # 14 - 10 + 2 + 7
        'queries[0][end_date]': "2015-06-09T13:59:59.999Z"
        'queries[0][op]': 'between'

    it "#relative days time", ->
      c = new Condition 'time', '~<>', count: 2, unit: 'day'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-06-11T07:00:00.000Z"
        'queries[0][end_date]': "2015-06-12T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#relative weeks time", ->
      c = new Condition 'time', '~<>', count: 4, unit: 'week'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-07-06T07:00:00.000Z"
        'queries[0][end_date]': "2015-07-13T06:59:59.999Z"
        'queries[0][op]': 'between'

    it "#relative months time", ->
      c = new Condition 'time', '~<>', count: 4, unit: 'month'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][start_date]': "2015-10-01T07:00:00.000Z"
        'queries[0][end_date]': "2015-10-31T06:59:59.999Z"
        'queries[0][op]': 'between'

  describe "relative time gt", ->
    timezone = "America/Los_Angeles"

    beforeEach ->
      @fakeTimer = new sinon.useFakeTimers(now.toDate().getTime())
    afterEach ->
      @fakeTimer.restore()

    it "#relative hour time", ->
      c = new Condition 'time', 'gt', count: 2, unit: 'hour'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][value]': '2015-06-09T13:00:00.000Z'
        'queries[0][op]': 'gt'

      c = new Condition 'time', 'lt', count: 2, unit: 'hour'
      expect(conditionsToQuery([c], timezone)).toEqual jasmine.objectContaining
        'queries[0][value]': '2015-06-09T13:59:59.999Z'
        'queries[0][op]': 'lt'
