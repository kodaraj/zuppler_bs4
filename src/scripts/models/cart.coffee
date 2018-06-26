Bacon = require 'baconjs'
R = require 'ramda'
userStore = require 'stores/user'

SERVER_URL = API3_SVC

client = require 'api/auth'
{ wrapRequest } = require 'utils/request'
{ findResourceLink, resourceLink } = require 'utils/resources'

Dispatcher = require 'utils/dispatcher'

moment = require 'moment'

CONFIG_CHANNEL =
  name: "Zuppler"
  links: [ resourceLink("self", "get", "#{SERVER_URL}/v3/channels/zuppler.json") ]

state = (cart) ->
  state = 'channel'
  state = 'user' if cart.channel
  state = 'integration' if cart.user
  state = 'cart' if cart.integration

channelUrl = (id) ->
  "#{SERVER_URL}/v3/channels/#{id}.json"

loadResource = (url) ->
  Bacon.fromPromise wrapRequest client.api(url)

loadChannels = (channel_ids) ->
  Bacon
    .once(channel_ids)
    .map R.map channelUrl
    .flatMap (urls) -> Bacon.zipAsArray R.map loadResource, urls
    .map R.map R.prop('channel')
    .toProperty()

setProp = R.curry (prop, state, value) ->
  R.assoc prop, value, state

pushProp = R.curry (propName, value) ->
  @d.stream("set-#{propName}").push value

capitalize = (x) ->
  R.toUpper(R.head(x)) + R.tail(x)

class Cart
  @MODEL_VERSION: 2

  constructor: (payload = {}) ->
    @type = 'carts'
    { @id, @name, channel, orderTime, orderType, address, location, cart, user, integration, @_version } = payload
    @name ||= R.pipe(R.split(/-/), R.nth(0))(@id)

    @_version ||= @constructor.MODEL_VERSION
    @loading = Bacon.never()

    @d = new Dispatcher("model::cart")

    if userStore.hasRole('config')
      @availableChannels = Bacon.constant [ CONFIG_CHANNEL ]
    else
      @availableChannels = loadChannels userStore.acls['channel']

    defaultChannel = @availableChannels
      .filter R.pipe R.length, R.equals(1)
      .map R.nth(0)

    @managedProps = ['channel', 'cart', 'user', 'orderTime', 'orderType', 'address', 'location', 'integration']

    initialState = R.pickAll @managedProps, payload

    setupDefaultChannel = (state, channel) ->
      if state.channel then state else R.assoc 'channel', channel, state

    @state = Bacon.update initialState,
      [ defaultChannel.toEventStream() ], setupDefaultChannel
      [ @d.stream('set-channel') ],     setProp('channel')
      [ @d.stream('set-user') ],        setProp('user')
      [ @d.stream('set-cart') ],        setProp('cart')
      [ @d.stream('set-orderType') ],   setProp('orderType')
      [ @d.stream('set-orderTime') ],   setProp('orderTime')
      [ @d.stream('set-address') ],     setProp('address')
      [ @d.stream('set-location') ],    setProp('location')
      [ @d.stream('set-integration') ], setProp('integration')

    @channel     = @state.map R.prop('channel')
    @cart        = @state.map R.prop('cart')
    @user        = @state.map R.prop('user')
    @orderTime   = @state.map R.prop('orderTime')
    @orderType   = @state.map R.prop('orderType')
    @address     = @state.map R.prop('address')
    @location    = @state.map R.prop('location')
    @integration = @state.map R.prop('integration')

  setChannel:     pushProp('channel')
  setUser:        pushProp('user')
  setCart:        pushProp('cart')
  setOrderType:   pushProp('orderType')
  setOrderTime:   pushProp('orderTime')
  setAddress:     pushProp('address')
  setLocation:    pushProp('location')
  setIntegration: pushProp('integration')

  toExternalForm: ->
    R.pickAll R.concat(['id', 'type', 'name', '_version'], @managedProps), @

module.exports = Cart
