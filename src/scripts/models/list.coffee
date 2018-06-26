Bacon = require 'baconjs'
Immutable = require 'immutable'
R = require 'ramda'
uuid = require 'uuid'
ordersApi = require 'api/orders'
conditionsUtils = require 'utils/conditionsToQuery'
ChangeTracker = require 'utils/trackSeenOrders'

optimisticUpdates = require 'models/list-optimistic'

{ conditionsToQuery } = conditionsUtils

userStore = require 'stores/user'

POLLING_TIME = 60 * 1000

trackingId = (order) ->
  "#{order.id}-#{order.state}"

ordersStreamProducer = (searchParam) ->
  { event, pageInfo, conditions, appliesTo} = searchParam
  sortDir = if pageInfo.sortAsc then "asc" else "desc"

  Bacon.retry
    source: ->
      console.info "Loading orders from event #{event}"
      Bacon.fromPromise ordersApi.search appliesTo,
        pageInfo.sort,
        sortDir,
        pageInfo.page,
        conditionsToQuery conditions, userStore.timezone()
    retries: 5
    isRetryable: (error) ->
      !error
    delay: (context) ->
      5000

eventsGenerator = (isPolling, manualRefresh) ->
  offset = Math.ceil(Math.random() * 20 - 10)
  seconds = POLLING_TIME + offset
  Bacon.mergeAll [
    Bacon.later(offset, "Initial loading #{new Date}")
    Bacon.interval(seconds).filter(isPolling).flatMapLatest (-> "polling at #{new Date}")
    manualRefresh.map -> "manual refresh #{new Date} (#{seconds})"
  ]

class List
  @MODEL_VERSION: 1
  constructor: (payload) ->
    { @id, @name, @appliesTo, @conditions, @system, @priority, @locked, @version, @soundName, @_version } = payload
    @id ||= uuid()
    @locked = !!@locked
    @version ||= 1
    @_version ||= List.MODEL_VERSION

    @pollingEnabled = new Bacon.Bus
    @isPolling = @pollingEnabled.toProperty(payload.isPolling || false)
    @manualRefresh = new Bacon.Bus
    @active = true
    @sounds = new Bacon.Bus
    @soundName ||= "notification"
    @useSounds = @sounds.toProperty(payload.useSounds || false)


    @_sort = new Bacon.Bus
    @_page = new Bacon.Bus

    @sortProp = @_sort.toProperty {prop: payload.sortProp?.prop || 'time', asc: payload.sortProp?.asc || false}
    @page = @_page.toProperty 1

    @_paginationInfo = Bacon.combineWith ((sortInfo, page) ->
      {sort: sortInfo.prop, sortAsc: sortInfo.asc, page: page}), @sortProp, @page

    @priority ||= 1

    searchParams = Bacon.combineTemplate
      event: eventsGenerator(@isPolling, @manualRefresh)
      pageInfo: @_paginationInfo
      appliesTo: @appliesTo
      conditions: @conditions

    ordersStreamData = searchParams.flatMapLatest(ordersStreamProducer).toProperty()

    orders = ordersStreamData
      .skipErrors()
      .flatMap R.prop('orders')
      .map R.defaultTo([])
      .toProperty([])

    @orders = Bacon
      .combineWith orders, optimisticUpdates.orders, optimisticUpdates.combineData

    @ordersMeta = ordersStreamData
      .skipErrors()
      .flatMap R.prop('meta')
      .toProperty({total: 0, page: 1, count: 1})

    clearErrors = @orders.map -> null
    errorValues = ordersStreamData
      .mapError (error) -> error
      .filter (error) -> !error.success
    @errors = Bacon.mergeAll(errorValues, clearErrors)

    changeTracker = ordersStreamData
      .scan new ChangeTracker, (t, data) -> t.track data.orders.map trackingId
      .skip 2 # Skip first 2 events as they are initial and first read

    @newOrders = changeTracker.map (t) -> t.lastChange > 0
    @makeNoise = changeTracker
      .filter (t) -> t.lastChange > 0
      .filter @useSounds
      .map R.always @soundName

    @changes = @ordersMeta
      .skip 1
      .scan Immutable.List([]), (list, meta) ->
        list = list.unshift date: new Date, value: meta.total
        list = list.setSize(90) if list.count() > 90
        list

    @loadingOrders = searchParams.awaiting(ordersStreamData)

    # ----- new tab interface
    @type     = 'lists'
    @loading  = @loadingOrders
    @activity = @newOrders
    @noise    = @makeNoise
    @meta     = @ordersMeta
    @data     = @orders

  setPolling: (enabled) ->
    @pollingEnabled.push enabled

  setUseSounds: (b) ->
    @sounds.push b

  sortOn: (prop, ascending) ->
    @_sort.push {prop: prop, asc: ascending}

  setPage: (page) ->
    @_page.push page

  refresh: ->
    @manualRefresh.push new Date

  toExternalForm: ->
    R.pick ['id', 'name', 'type', 'conditions', 'version', '_version', 'appliesTo', 'soundName', 'isPolling', 'useSounds', 'sortProp', 'locked'], @

module.exports = List
