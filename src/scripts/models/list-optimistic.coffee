Bacon = require 'baconjs'
R = require 'ramda'
moment = require 'moment'
Dispatcher = require 'utils/dispatcher'

d = new Dispatcher "OPTIMIST"

orders = Bacon.update {},
  [d.stream('update-order')], (orders, {id, state}) ->
    expire = moment().add(5, 'minutes').toDate()
    R.assoc id, { id, state, expire: expire}, orders
  [ Bacon.interval(1000*60) ], (orders, _) ->
    ids = R.map R.prop('id'), R.defaultTo [], R.filter R.pipe(R.prop('expire'), R.gt(new Date)), R.values orders
    if ids.length then R.omit(ids, orders) else orders

updateOrder = R.curry (states, order) ->
  if states[order.id]
    ostate = states[order.id].state
    R.merge order, state: ostate, pending: order.state != ostate
  else
    order

module.exports =
  orders: orders
  updateOrderState: (order, state) ->
    d.stream('update-order').push { id: order.id, state: state }
  combineData: (orders, optimisticOrders) ->
    if 0 < R.length R.keys optimisticOrders
      R.map updateOrder(optimisticOrders), orders
    else
      orders
