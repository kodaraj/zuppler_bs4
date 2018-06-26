Bacon = require 'baconjs'
R = require 'ramda'

Dispatcher = require 'utils/dispatcher'
userStore = require 'stores/user'
List = require 'models/list'
d = new Dispatcher("lists")
{ makeDefaultLists } = require 'models/list-defaults'

makeList = (payload) -> new List payload
tabs = userStore
  .tabs
  .map R.filter R.propEq('type', 'lists')
  .map R.filter R.propEq('_version', List.MODEL_VERSION)
  .map R.map makeList
  .map (tabs) ->
    if tabs.length == 0
      R.map makeList, makeDefaultLists(userStore.roles())
    else
      tabs

Condition = require 'models/condition'

makeCondition = R.curry (value, key) -> new Condition key, 'contains', value
makeConditions = (value) ->
  R.map makeCondition(value), [
    'uuid'
    'customer_name'
    'customer_phone'
    'customer_email'
    'delivery_address'
    'code'
    'restaurant_name'
    'channel_name'
  ]

addListFromQuickSearch = (value) ->
  list = new List
    name: "Search: #{value}"
    appliesTo: 'any'
    conditions: makeConditions value
    locked: false
  d.push 'addList', list
  list

findListById = (lists, listId) ->
  [lists, R.find R.propEq('id', listId), lists]
findListIndexById = (lists, listId) ->
  [lists, R.findIndex R.propEq('id', listId), lists]
removeList = ([lists, listIndex]) ->
  R.remove listIndex, 1, lists

lists = Bacon.update [],
  [ userStore.lists ], (prev, lists) -> R.map(makeList, lists)
  # Overwrite the lists from storage if there is something saved as tabs
  [ tabs.toEventStream() ], (prev, lists) -> if lists.length then lists else prev
  [d.stream('addList')], (prev, list) ->
    R.append list, prev
  [d.stream('removeList')], R.compose removeList, findListIndexById
  [d.stream('updateList')], (lists, {id, list}) ->
    index = R.findIndex R.propEq('id', id), lists
    R.insert index, list, R.filter(R.compose(R.not, R.propEq('id', id)), lists)

soundStream = lists
  .map (lists) ->
    noises = lists.map (list) -> list.makeNoise
    # noises.toArray()
  .flatMap (streams) ->
    Bacon.mergeAll streams

module.exports =
    lists: lists
    addList: (list) -> d.push 'addList', list
    updateList: (id, list) -> d.push 'updateList', id: id, list: list
    removeList: (id) -> d.push 'removeList', id
    addListFromQuickSearch: addListFromQuickSearch
    soundStream: soundStream
