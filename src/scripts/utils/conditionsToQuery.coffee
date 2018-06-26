R = require 'ramda'
moment = require 'moment-timezone'

relativeTimeFor = (timezone, value) ->
  startOfDay = moment().tz(timezone).set('hour', 0).set('minute', 0).set('second', 0).set('millisecond', 0)
  endOfDay = moment().tz(timezone).set('hour', 23).set('minute', 59).set('second', 59).set('millisecond', 999)
  console.log startOfDay
  console.log "startOfDay"

  switch value
    when 'today'
      startDate: startOfDay.toJSON()
      endDate: endOfDay.toJSON()
    when 'tomorrow'
      startDate: startOfDay.add(1, 'day').toJSON()
      endDate: endOfDay.add(1, 'day').toJSON()
    when 'yesterday'
      startDate: startOfDay.subtract(1, 'day').toJSON()
      endDate: endOfDay.subtract(1, 'day').toJSON()
    when 'this_week'
      startDate: startOfDay.set('day', 1).toJSON()
      endDate: endOfDay.set('day', 7).toJSON()
    when 'next_week'
      startDate: startOfDay.add(1, 'week').set('day', 1).toJSON()
      endDate: endOfDay.add(1, 'week').set('day', 7).toJSON()
    when 'last_week'
      startDate: startOfDay.subtract(1, 'week').set('day', 1).toJSON()
      endDate: endOfDay.subtract(1, 'week').set('day', 7).toJSON()
    when 'last_week_today'
      startDate: startOfDay.subtract(1, 'week').toJSON()
      endDate: endOfDay.subtract(1, 'week').toJSON()

relativeUnitTimeFor = (timezone, count, unit) ->
  intervalStart = moment().tz(timezone).set('minute', 0).set('second', 0).set('millisecond', 0)
  intervalEnd = moment().tz(timezone).set('minute', 59).set('second', 59).set('millisecond', 999)
  switch unit
    when 'hour' then # noop
    when 'day'
      intervalStart.set('hour', 0)
      intervalEnd.set('hour', 23)
    when 'week'
      intervalStart.set('hour', 0).set('day', 1)
      intervalEnd.set('hour', 23).set('day', 7)
    when 'month'
      intervalStart.set('hour', 0).set('date', 1)
      intervalEnd.set('hour', 23).set('date', 1).subtract(1, 'day').add(1, 'month')
    else
      throw "Unit #{unit} is not allowed"

  startDate: intervalStart.add(count, unit).toJSON()
  endDate: intervalEnd.add(count, unit).toJSON()

relativeShiftTimeFor = (timezone, value) ->
  startOfDay = moment().tz(timezone).set('hour', 4).set('minute', 0).set('second', 0).set('millisecond', 0)
  endOfDay = moment().tz(timezone).add(1, 'day').set('hour', 3).set('minute', 59).set('second', 59).set('millisecond', 999)

  switch value
    when 'today'
      startDate: startOfDay.toJSON()
      endDate: endOfDay.toJSON()
    when 'yesterday'
      startDate: startOfDay.subtract(1, 'day').toJSON()
      endDate: endOfDay.subtract(1, 'day').toJSON()
    when '2_days_ago'
      startDate: startOfDay.subtract(2, 'day').toJSON()
      endDate: endOfDay.subtract(2, 'day').toJSON()

relativeNowUnitTimeFor = (timezone, count, unit) ->
  intervalStart = moment().tz(timezone)
  intervalEnd = moment().tz(timezone)
  startDate: intervalStart.toJSON()
  endDate: intervalEnd.add(count, unit).toJSON()

relativeUntilNowUnitTimeFor = (timezone, count, unit) ->
  intervalStart = moment().tz(timezone)
  intervalEnd = moment().tz(timezone)
  startDate: intervalEnd.subtract(count, unit).toJSON()
  endDate: intervalStart.toJSON()

isDateTimeCondition = R.where field: R.contains R.__, ['time', 'placed', 'created_at', 'updated_at']
isExactRestaurantCondition = R.whereEq field: 'restaurant_name', op: 'equal'
isDriverCondition = R.anyPass([R.whereEq(field: 'rds.driver_id', op: 'equal'), R.whereEq(field: 'rds.driver_id', op: '!equal')])
isDeliveryServiceCondition = R.anyPass([R.whereEq(field: 'rds.delivery_service', op: 'equal'), R.whereEq(field: 'rds.delivery_service', op: '!equal')])

conditionToQuery = (timezone, condition) ->
  if isDateTimeCondition condition
    condFieldOp = R.pick(['field'], condition)
    switch condition.op
      when '~=' # date is
        R.mergeAll [condFieldOp, op: "between", relativeTimeFor(timezone, condition.value)]
      when '~<>' # date is in count unit
        R.mergeAll [condFieldOp, op: "between", relativeUnitTimeFor(timezone, condition.value.count, condition.value.unit)]
      when 'gt'
        R.mergeAll [condFieldOp, op: "gt", value: relativeUnitTimeFor(timezone, condition.value.count, condition.value.unit).startDate]
      when 'lt'
        R.mergeAll [condFieldOp, op: "lt", value: relativeUnitTimeFor(timezone, condition.value.count, condition.value.unit).endDate]
      when 'within'
        R.mergeAll [condFieldOp, op: "between", relativeNowUnitTimeFor(timezone, condition.value.count, condition.value.unit)]
      when 'within past'
        R.mergeAll [condFieldOp, op: "between", relativeUntilNowUnitTimeFor(timezone, condition.value.count, condition.value.unit)]
      when 'in'
        R.assoc 'op', 'between', R.merge R.pick(['field'], condition), condition.value
      when '!in'
        R.assoc 'op', '!between', R.merge R.pick(['field'], condition), condition.value
      when 's~='
        R.mergeAll [condFieldOp, op: 'between', relativeShiftTimeFor(timezone, condition.value)]
      else # for <> or ><
        R.merge R.pick(['field', 'op'], condition), condition.value
  else if isExactRestaurantCondition condition
    R.merge R.pick(['op'], condition), field: 'restaurant_id', value: condition.value.id
  else if isDriverCondition condition
    R.merge R.pick(['op'], condition), field: 'rds.driver_id', value: condition.value.id
  else if isDeliveryServiceCondition condition
    R.merge R.pick(['op'], condition), field: 'rds.delivery_service', value: condition.value.id
  else
    R.pick(['field', 'op', 'value'], condition)

conditionsToQuery = (conditions, timezone = "EET") ->
  idx = 0
  res = R.reduce (sum, cond) ->
    sum["queries[#{idx}][field]"] = cond.field
    sum["queries[#{idx}][op]"] = cond.op
    if cond.startDate || cond.endDate
      sum["queries[#{idx}][start_date]"] = cond.startDate
      sum["queries[#{idx}][end_date]"] = cond.endDate
    else
      sum["queries[#{idx}][value]"] = cond.value
    idx = idx + 1
    sum
  , {}, translateConditions conditions, timezone
  res

translateConditions = (conditions, timezone = "EET") ->
  query = R.map conditionToQuery.bind(@, timezone), conditions
  onlyValid = R.filter (cond) -> cond.value or cond.startDate or cond.endDate
  onlyValid query

module.exports =
  conditionsToQuery: conditionsToQuery
  translateConditions: translateConditions
