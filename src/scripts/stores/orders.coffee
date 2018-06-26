Bacon = require 'baconjs'
R = require 'ramda'
Order = require 'models/order'
Dispatcher = require 'utils/dispatcher'
userStore = require 'stores/user'

d = new Dispatcher("orders")

tabs = userStore
  .tabs
  .map R.filter R.propEq('type', 'orders')
  .map R.filter R.propEq('_version', Order.MODEL_VERSION)
  .map R.map (payload) -> new Order payload

state = Bacon.update [],
    [tabs.toEventStream()], (_, orders) -> orders
    [d.stream('pin')], (prev, order) ->
      R.append order, prev
    [d.stream('unpin')], (prev, orderId) ->
      R.remove R.findIndex(R.propEq('id', orderId), prev), 1, prev

# Prevent double pinning
orders = state
  .map R.uniqBy(R.prop('id'))

module.exports =
    orders: orders
    pin: (orderId, temporary = false) ->
      d.stream('pin').push new Order id: orderId, temporary: temporary
    unpin: (orderId) -> d.stream('unpin').push orderId
