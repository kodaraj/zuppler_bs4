Bacon = require 'baconjs'
R = require 'ramda'
Immutable = require 'immutable'

ordersApi = require 'api/orders'

Dispatcher = require 'utils/dispatcher'
resUtil = require 'utils/resources'

userStore = require 'stores/user'

d = new Dispatcher("order")

sender = ->
  "Customer Service by #{userStore.name()}/#{userStore.email()}"

downloadOrder = (url) ->
  wrapWithRetry(R.partial ordersApi.loadFromURL, [url]).map (data) -> data.order

wrapWithRetry = (apiCall, delay = 300) ->
  Bacon
    .retry
      source: ->
        Bacon.fromPromise apiCall()
      retries: 5
      isRetryable: (data) -> data.status.code != 500
      delay: (ctx) ->
        delay * ctx.retriesDone

urlLoader = d.stream('openOrder-url')
  .flatMap downloadOrder

orderLoader = d.stream('openOrder')
  .filter (order) -> !!order
  .map (order) ->
    resUtil.findResourceLink order, "self", "get"
  .flatMap downloadOrder

executeActionStream = d.stream('executeAction')
  .flatMap (payload) ->
    params = R.merge payload.params, sender: sender()
    Bacon.fromPromise ordersApi.executeAction payload.action.url, params

executeNotificationActionStream = d.stream('executeNotificationAction')
  .flatMap (payload) ->
    params = R.merge payload.params, sender: sender()
    Bacon.fromPromise ordersApi.executeAction payload.url, params

createManualEvent = d.stream('createManualEvent')
  .flatMap (payload) ->
    params = R.merge payload.params, sender: sender()
    Bacon.fromPromise ordersApi.createEvent payload.url, params

# enable this if reload is required after an actions is executed
# order updates should come through push notifications however
# d.stream('reload').plug executeActionStream

setCurrent = (prev, current) -> current

reloadOrder = (prev, time) ->
  d.stream('openOrder-url').push resUtil.findResourceLink(prev, "self", "get")
  prev

isSameOrder = (old, current) ->
  !!old and !!current and old.id == current.id

noop = (prev, actionResult) -> prev

currentOrder = Bacon.update null,
  [urlLoader], setCurrent,
  [orderLoader], setCurrent,
  [d.stream('reload')], reloadOrder,
  [executeActionStream], noop,
  [executeNotificationActionStream], noop,
  [createManualEvent], noop,
  [d.stream('closeOrder')], -> null

notifications = currentOrder
  .skipDuplicates isSameOrder
  .flatMap (order) ->
    if order
      notificationsURI = resUtil.findResourceLink order, "notifications", "get"
      wrapWithRetry R.partial ordersApi.loadFromURL, [notificationsURI]
    else
      Bacon.once notifications: []
  .map (data) -> data.notifications

events = currentOrder
  .flatMap (order) ->
    if order
      eventsURI = resUtil.findResourceLink order, "events", "get"
      wrapWithRetry R.partial ordersApi.loadFromURL, [eventsURI]
    else
      Bacon.once events: []
  .map (data) -> data.events
  .map R.reverse

restaurant = currentOrder
  .skipDuplicates isSameOrder
  .flatMap (order) ->
    if order
      restaurantURI = order.restaurant.resource_url
      wrapWithRetry R.partial ordersApi.loadFromURL, [restaurantURI, true]
    else
      Bacon.once {}
  .map (data) -> data.restaurant

channel = currentOrder
  .skipDuplicates isSameOrder
  .flatMap (order) ->
    if order
      channelURI = order.channel.resource_url
      wrapWithRetry R.partial ordersApi.loadFromURL, [channelURI, true]
    else
      Bacon.once {}
  .map (data) -> data.channel

allStreams = Bacon
  .mergeAll currentOrder, channel, restaurant, events, notifications
errors = allStreams.errors()
  .mapError (error) -> error
clearErrors = allStreams.map -> null
errorsStream = Bacon
  .mergeAll errors, clearErrors
  .skipDuplicates()

actions = currentOrder
  .map R.defaultTo {}
  .map R.prop('links')
  .map R.defaultTo []
  .map R.filter (link) ->
    !R.contains link.name, ['self', 'notifications', "events"]
  .map (links) ->
    R.filter resUtil.onlyInteractive, links

loadingOrder = d.stream('openOrder')
  .skipDuplicates(isSameOrder)
  .awaiting(orderLoader).toProperty()

executingAction = d.stream('executeAction')
  .awaiting(executeActionStream).toProperty()
executingNotificationAction = d.stream('executeNotificationAction')
  .awaiting(executeNotificationActionStream).toProperty()
executingCreateManualEvent = d.stream('createManualEvent')
  .awaiting(createManualEvent).toProperty()
reloadingOrder = d.stream('openOrder-url').awaiting(urlLoader).skipDuplicates().toProperty()

module.exports =
  current: currentOrder
  currentInfo: d.stream('openOrder').toProperty()

  notifications: notifications.toProperty()
  events: events.toProperty()
  restaurant: restaurant.toProperty()
  channel: channel.toProperty()
  actions: actions.toProperty()
  errors: errorsStream.toProperty()

  loading: loadingOrder
  executingAction: executingAction
  executingNotificationAction: executingNotificationAction
  executingCreateManualEvent: executingCreateManualEvent
  reloadingOrder: reloadingOrder

  openOrderFromURL: (url) ->
    d.stream('openOrder-url').push url
  openOrder: (order) ->
    d.stream('openOrder').push order
  openOrderById: (orderId) ->
    d.stream('openOrder-url').push "#{ORDERS_SVC}/v4/orders/#{orderId}.json"
  executeAction: (action, params = {}) ->
    d.stream('executeAction').push action: action, params: params
  executeNotificationAction: (url, method, params = {}) ->
    d.stream('executeNotificationAction').push url: url, params: params, method: method
  createManualEvent: (url, message) ->
    d.stream('createManualEvent').push url: url, params: { message: message }
  reload: ->
    d.stream('reload').push new Date
  closeOrder: ->
    d.stream('closeOrder').push true
    d.stream('openOrder').push null
