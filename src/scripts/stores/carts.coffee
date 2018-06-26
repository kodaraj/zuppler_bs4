Bacon = require 'baconjs'
R = require 'ramda'
Order = require 'models/order'
Dispatcher = require 'utils/dispatcher'
userStore = require 'stores/user'
OrderingStorage = require 'zuppler-js/lib/utils/storage'
OrderingCache = require 'zuppler-js/lib/utils/cache'
LRUCache = require 'utils/lru'
uuid = require 'uuid'

Cart = require 'models/cart'

d = new Dispatcher("carts")

tabs = userStore
  .tabs
  .map R.filter R.propEq('type', 'carts')
  .map R.filter R.propEq('_version', Cart.MODEL_VERSION)
  .skipDuplicates()
  .map R.map (payload) -> new Cart payload

carts = Bacon.update [],
  [tabs.toEventStream()], (_, carts) -> carts
  [ d.stream('create-cart') ], (carts, payload) ->
    cart = new Cart(payload)
    R.append(cart, carts)

state = Bacon.update null,
  [ d.stream('current-cart') ], (_, cart) -> cart
  [ d.stream('set-current-cart-key') ], (current, { key, url } ) ->
    current.setCart {key, url}
    current
  [ d.stream('set-current-user-key') ], (current, { key, url } ) ->
    current.setUser {key, url}
    current

getStateProp = R.curry (prop, key) ->
  state
    .filter R.compose(R.not, R.isNil)
    .flatMap R.prop(prop)
    .map (prop) ->
      if prop and prop.key == key then prop.url else null
    .skipDuplicates()

dynamicStorage =
  getItem: (svc, key) ->
    switch svc
      when 'cart' then getStateProp('cart', key)
      when 'user' then getStateProp('user', key)

  setItem: (svc, key, url) ->
    d.stream("set-current-#{svc}-key").push { key, url }
    url

lruCacheImpl = new LRUCache 1000
lruCache =
  getItem: (key, cb) ->
    value = lruCacheImpl.get(key)
    # if value
    #   console.info "Cache hit", key
    # else
    #   console.info "Cache miss", key
    cb(null, value)
  setItem: (key, value, cb) ->
    if value
      lruCacheImpl.put(key, value)
      # console.info "Cache set", key
    cb(null, value)

OrderingStorage.setImpl dynamicStorage
OrderingCache.setImpl lruCache

hookCurrent = (currentTabStream, saveStream) ->
  current = currentTabStream
    .map (tab) -> if tab and tab.type == 'carts' then tab else null
    .skipDuplicates()
  d.plug('current-cart', current)
  saveStream.plug state

{ findResourceLink } = require 'utils/resources'
{ wrapRequest } = require 'utils/request'
client = require 'api/auth'

loginUser = d.stream('login-user')
  .map ({shopping_user, zuppler_user}) ->
    url = findResourceLink(shopping_user, "login_on_behalf", "put")
    user_id = zuppler_user.id
    { url, user_id }
  .flatMap ({url, user_id}) ->
    Bacon.fromPromise wrapRequest client.api url, 'put', _method: 'PUT', user_id: user_id

module.exports =
  carts: carts
  current: state
  hookCurrent: hookCurrent
  createCart: (uuid) ->
    d.stream('create-cart').push id: uuid
  createNewCartUI: (nextState, replace, complete) ->
    newCartUUID = uuid()
    d.stream('create-cart').push id: newCartUUID
    replace "/carts/#{newCartUUID}"
    complete()
  loggedInUser: loginUser
  loggedInLoading: d.stream('login-user').awaiting(loginUser)
  loginOnBehalf: (shopping_user, zuppler_user) ->
    d.stream('login-user').push {shopping_user, zuppler_user}
