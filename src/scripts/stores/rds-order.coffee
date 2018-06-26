Bacon = require 'baconjs'
R = require 'ramda'
Immutable = require 'immutable'

ordersApi = require 'api/orders'

Dispatcher = require 'utils/dispatcher'
resUtil = require 'utils/resources'

orderStore = require "stores/order"
userStore = require 'stores/user'

d = new Dispatcher("rds-order")

sender = ->
  "Customer Service by #{userStore.name()}/#{userStore.email()}"

downloadOrder = (url) ->
  Bacon.combineTemplate
    event: Bacon.mergeAll(Bacon.interval(60000), Bacon.once(1))
    url: url
  .flatMapLatest (data)-> wrapWithRetry(R.partial ordersApi.loadFromURL, [data.url])
  .map (data) -> data.order
  .flatMapError (err)-> null

wrapWithRetry = (apiCall, delay = 300) ->
  Bacon
    .retry
      source: ->
        Bacon.fromPromise apiCall()
      retries: 5
      isRetryable: (data) -> data.status.code != 500 && data.status.code != 404
      delay: (ctx) ->
        delay * ctx.retriesDone

setCurrent = (prev, current) -> current

orderLoader = orderStore.current
  .filter (order) -> !!order
  .map (order) -> "#{RDSAAS_SVC}/v1/api/orders/#{order.id}.json"
  .skipDuplicates()
  .flatMap downloadOrder

d.stream('closeOrder')
  .plug orderStore.current.filter(R.isNil)

isSameOrder = (old, current) ->
  !!old and !!current and old.id == current.id

noop = (prev, actionResult) -> prev

currentOrder = Bacon.update null,
  [orderLoader], setCurrent,
  [d.stream('closeOrder')], -> null

allStreams = Bacon
  .mergeAll currentOrder
errors = allStreams.errors()
  .mapError (error) -> error
clearErrors = allStreams.map -> null

errorsStream = Bacon
  .mergeAll errors, clearErrors
  .skipDuplicates()

loadingOrder = d.stream('openOrder')
  .skipDuplicates(isSameOrder)
  .awaiting(orderLoader).toProperty()

actions = currentOrder
  .map R.defaultTo {}
  .map R.prop('links')
  .map R.defaultTo []
  .map R.filter (link) ->
    !R.contains link.name, ['self', 'notifications', 'events']
  .map (links) ->
    R.filter resUtil.onlyInteractive, links

driverStream = Bacon.combineTemplate order: currentOrder.toProperty(), driver: d.stream('driver')

assignDriverResult = driverStream
  .flatMapLatest (params) ->
    url = resUtil.findResourceLink(params.order, 'assign', 'put')
    ordersApi.executeAction(url, driver_id: params.driver.id)

#Cancel Delivery
cancelResult = currentOrder
  .sampledBy d.stream('cancelDelivery')
  .flatMap (order) ->
    url = resUtil.findResourceLink(order, 'cancel_delivery', 'put')
    ordersApi.executeAction(url)

module.exports =
  current: currentOrder
  actions: actions.toProperty()
  errors: errorsStream.toProperty()

  loading: loadingOrder

  assignDriver: (driver)->
    d.stream('driver').push driver
  assignDriverResult: assignDriverResult

  cancelDelivery: ->
    d.stream('cancelDelivery').push true

  cancelDeliveryResult: cancelResult

  closeOrder: ->
    orderStore.closeOrder()
    d.stream('closeOrder').push true
