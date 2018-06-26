Bacon = require 'baconjs'
R = require 'ramda'
Dispatcher = require '../utils/dispatcher'

listStore = require './lists'
rdsListStore = require './rds-lists'
cartsStore = require './carts'
userStore = require './user'
feedbackStore = require './feedback'
ordersStore = require './orders'

d = new Dispatcher("ui")

stateTabs = (state) ->
  R.flatten R.values R.dissoc 'current', R.dissoc 'tabInfo', state

processList = R.curry (propName, state, data) ->
  newState = R.assoc(propName, data, state)
  if state.tabInfo
    current = findCurrent(newState, state.tabInfo)
    if current
      newState = R.assoc 'current', current, R.assoc 'tabInfo', null, newState
  d.stream('save-state').push stateTabs newState
  newState

findCurrent = (state, tabInfo) ->
  finder = R.whereEq(R.pick(['id', 'type'], tabInfo))
  R.find finder, stateTabs state

tabularData = Bacon.update { current: null, tabInfo: null, lists: [], rds: [], orders: [], feedbacks: [], carts: [] },
  [d.stream('current')], (prev, current) ->
    R.assoc 'current', current, prev

  [ feedbackStore.tabs.toEventStream() ], processList('feedbacks')
  [ listStore.lists.toEventStream() ], processList('lists')
  [ rdsListStore.lists.toEventStream() ], processList('rds')
  [ ordersStore.orders.toEventStream() ], processList('orders')
  [ cartsStore.carts.toEventStream() ], processList('carts')

  [ d.stream('save-state-command') ], (state, _) ->
    d.stream('save-state').push stateTabs state
    state

  [ d.stream('current-by-id') ], (state, tabInfo) ->
    current = findCurrent(state, tabInfo)
    if current
      R.assoc 'current', current, state
    else
      R.assoc 'tabInfo', tabInfo, R.assoc 'current', null, state

  [ d.stream('switch-first') ], (state, _) ->
    tabs = stateTabs state
    R.assoc 'current', tabs[0], state

active = tabularData
  .map stateTabs

current = tabularData
  .skipDuplicates()
  .map R.prop('current')
  .filter R.compose R.not, R.isNil

cartsStore.hookCurrent current, d.stream('save-state-command')

toBaconTemplate = (value, key, obj) ->
  if value and value.toString().startsWith('Bacon')
    value
  else
    Bacon.once(value)

d.stream('save-state')
  .debounce(2500)
  .skip(1)
  .filter R.length
  .map R.filter R.compose(R.equals(false), R.defaultTo(false), R.prop('temporary'))
  .map R.map (tab) -> tab.toExternalForm()
  .skipDuplicates(R.equals)
  .map R.map R.mapObjIndexed toBaconTemplate
  .flatMap R.pipe(R.map(R.partial(Bacon.combineTemplate.bind(Bacon), [])), Bacon.combineAsArray)
  .onValue userStore.saveTabs

sidebar = Bacon.update true,
  [ d.stream('toggle-sidebar') ], (sidebar, _) ->
    !sidebar

version = active
  .map R.map R.pipe R.prop('version'), R.defaultTo(0)
  .map R.sum

module.exports =
  setCurrentUI: (type, id) ->
    d.stream('current-by-id').push { id, type }
  version: version
  saveTabs: -> d.stream('save-state-command').push new Date
  switchToFirst: -> d.stream('switch-first').push new Date
  current: current
  active: active
  toggleSidebar: -> d.stream('toggle-sidebar').push new Date
  sidebar: sidebar
  # restoreInitialRoute: (nextState, replace, complete) ->
  #   # if there is a link to an order in a list we
  #   # redirect to the order as the list might not be present
  #   if nextState.params.orderId and nextState.location.pathname.match(/^\/lists\//)
  #     temporaryPins = userStore.settingFor 'dont-pin-orders-from-links'
  #     ordersStore.pin nextState.params.orderId, temporaryPins
  #     d.stream('current-by-id').push id: nextState.params.orderId, type: 'orders'
  #     replace("orders/#{nextState.params.orderId}")
  #   complete()
