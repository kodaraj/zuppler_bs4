R = require 'ramda'
Bacon = require 'baconjs'
client = require 'api/auth'
reqUtil = require 'utils/request'
userStore = require 'stores/user'
conditionsUtils = require 'utils/conditionsToQuery'

ChangeTracker = require 'utils/trackSeenOrders'

{ conditionsToQuery, translateConditions } = conditionsUtils

toastr = require('components/toastr-config')

sortDir = (asc) ->
  if asc then 'asc' else 'desc'

takeout = (name, list, options, template = false) ->
  sortPropToParams = (listData) ->
    sortInfo = listData.sortProp
    R.merge sort_by: sortInfo.prop, sort_direction: sortDir(sortInfo.asc), R.dissoc 'sortProp', listData
  conditionsToParams = (listData) ->
    conditions = listData.conditions
    R.merge queries: translateConditions(conditions, userStore.timezone()), R.dissoc('conditions', listData)

  Bacon
    .combineTemplate R.pick ['id', 'appliesTo', 'conditions', 'sortProp'], list
    .map R.assoc 'name', name
    .map R.assoc 'options', options
    .map R.assoc 'template', template
    .map conditionsToParams
    .map sortPropToParams
    .flatMap (data) ->
      console.log "[POST] takeout", data
      Bacon.fromPromise reqUtil.wrapRequest client.api("takeout", 'post', data)
    .map (data) ->
      reloadTakeouts.push 'create reload'
      data.takeout

reloadTakeouts = new Bacon.Bus

allTakeouts = userStore
  .loggedIn
  .sampledBy(reloadTakeouts)
  .filter R.equals(true)
  .flatMap ->
    Bacon.fromPromise reqUtil.wrapRequest client.api('takeouts')
  .map R.prop('takeouts')
  .map R.map R.prop('takeout')

takeoutIdAndState = (takeout) -> "#{takeout.id}-#{takeout.state}"

isCompleted = R.curry (prev, takeout) ->
  ptakeout = prev[takeout.id] || state: "completed"
  ptakeout.state != takeout.state and takeout.state == "completed"

indexById = R.curry (func, sum, o) ->
  R.assoc func(o), o, sum

countCompleted = ({count, prev}, takeouts) ->
  count = R.filter(isCompleted(prev || {}), takeouts).length
  prev = R.reduce indexById(R.prop('id')), {}, takeouts
  { count, prev }

changeTracker = allTakeouts
  .scan {}, countCompleted
  .filter ({count, prev}) -> count > 0
  .onValue (data) ->
    toastr.info 'Order takeout processing completed. Check your email or download requests page for more info', "Order Takeout"

# Reloads the takeouts as long as there is one at least running
isProcessing = allTakeouts
  .map R.filter R.compose R.not, R.propEq('state', 'completed')
  .filter R.pipe(R.length, R.lt(0))
  .log "[Takeout] Running or waiting detected will trigger reload!"
  .throttle 1000*30

reloadTakeouts.plug isProcessing

templates = userStore
  .loggedIn
  .sampledBy(reloadTakeouts)
  .filter R.equals(true)
  .flatMap ->
    Bacon.fromPromise reqUtil.wrapRequest client.api("takeout_templates")
  .map R.prop('takeouts')
  .map R.map R.prop('takeout')

loading = reloadTakeouts.awaiting(allTakeouts.merge(templates))

module.exports =
  create: takeout
  all: allTakeouts.toProperty()
  templates: templates.log('TEMPLATES').toProperty()
  reload: -> reloadTakeouts.push new Date
  reloading: loading
