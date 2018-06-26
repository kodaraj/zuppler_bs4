R = require 'ramda'

makeCondition = (condition) ->
  field: condition[0]
  op: condition[1]
  value: condition[2]

makeDefaultList = (type, name, appliesTo, polling, sounds, sortProp, sortAsc, soundName, conditions...) ->
  name: name
  type: type
  locked: true
  appliesTo: appliesTo
  isPolling: polling
  useSounds: sounds
  sortProp: { prop: sortProp, asc: sortAsc }
  soundName: soundName
  conditions: R.map makeCondition, conditions

isConfig = R.contains 'config'
isRestaurantOwner = R.contains 'restaurant'
isRestaurantStaff = R.contains 'restaurant_staff'
isRestaurant = R.anyPass [isRestaurantOwner, isRestaurantStaff]
isAmbassador = R.contains 'ambassador'
isDispatcher = R.contains 'dispatcher'

makeDefaultLists = (roles)->
  lists = []
  makeList = R.partial makeDefaultList, ['lists']

  if isRestaurant roles
    lists.push makeList "Unconfirmed Orders", "any", true, true, "time", true, 'neworder',
      [ "state", "equal", "executing"],
      [ "state", "equal", "missed"]

    lists.push makeList "Upcoming Orders for Today", "all", true, false, "time", true, 'notification',
      [ "time", "within", {count: 1, unit: 'day'} ],
      [ "state", "equal", "confirmed" ]

    lists.push makeList "Canceled", "all", true, true, "time", true, 'notification',
      [ "time", "within", {count: 1, unit: 'month'}],
      [ "state", "equal", "canceled"]

    lists.push makeList "Past", "all", false, false, "time", false, 'notification',
      [ "time", "within past", {count: 1, unit: 'month'}],
      [ "state", "!equal", "rejected"]

    lists.push makeList "Orders Placed Today", "all", false, false, "created_at", false, 'notification',
      [ "created_at", "~=", "today" ],
      [ "state", "equal", "confirmed" ]

  if isConfig(roles) or isAmbassador(roles)
    lists.push makeList "Pending Attention", "all", true, true, "time", true, 'notification',
      [ "time", "within", { count: 14, unit: 'day' } ],
      [ "state", "!equal", "confirmed"],
      [ "state", "!equal", "rejected"],
      [ "state", "!equal", "executing"]
      [ "state", "!equal", "invoiced"]

    lists.push makeList "Lost", "all", true, true, "time", true, 'notification',
      [ "time", "within past", {count: 7, unit: 'day'} ],
      [ "state", "equal", "missed"]

  lists

makeDefaultRdsLists = (roles) ->
  lists = []

  makeList = R.partial makeDefaultList, ['rds']
  if isDispatcher(roles)
    lists.push makeList "Pending RDS Orders", "all", true, true, "time", true, 'notification',
      [ "time", "within", { count: 2, unit: 'day' } ],
      [ 'service_id', 'equal', 'DELIVERY' ],
      [ 'rds.state', '!equal', 'delivered']
    lists.push makeList "Completed RDS Orders", "all", false, false, "time", true, 'notification',
      [ "time", "within past", { count: 1, unit: 'month' } ],
      [ 'service_id', 'equal', 'DELIVERY' ],
      [ 'rds.state', 'equal', 'delivered']
  lists

module.exports =
  makeDefaultLists: makeDefaultLists
  makeDefaultRdsLists: makeDefaultRdsLists
