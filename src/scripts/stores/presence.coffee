R = require 'ramda'
Bacon = require 'baconjs'
Immutable = require 'immutable'

orderStore = require 'stores/order'
userStore = require 'stores/user'

ws = require 'api/ws'

notStream = (b) -> !b

presenceStream = ws.input

messagesStream = orderStore.current
  .toEventStream()
  .holdWhen userStore.loggedIn.map notStream
  .map (o) -> if o then o.id else null
  .map (uuid) ->
    id: uuid
    user: userStore.name()
    email: userStore.email()
    roles: userStore.roles()
    date: new Date

ws.output.plug messagesStream

updateUser = (prev, orderInfo) ->
  if orderInfo.id
    prev.update orderInfo.email, (value) -> orderInfo
  else
    prev.delete orderInfo.email

usersCurrentOrder = Bacon.update Immutable.Map({}),
  [presenceStream], updateUser

usersCurrentOrder
  .map (userOrders) -> userOrders.toJS()

sortByDate = R.sortBy R.prop 'date'

addOrder = (prev, orderInfo) ->
  prev.update orderInfo.key, (value) -> sortByDate R.concat value, [R.dissoc 'id', orderInfo]

ordersPresence = usersCurrentOrder
  .map (usersOrders) ->
    usersOrders.reduce (sum, orderInfo) ->
      sum[orderInfo.id] = sortByDate R.concat sum[orderInfo.id] || [], [R.dissoc 'id', orderInfo]
      sum
    , {}

module.exports =
  orders: ordersPresence
  users: usersCurrentOrder
