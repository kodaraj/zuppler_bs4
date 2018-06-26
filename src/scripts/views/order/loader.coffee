React = require 'react'
R = require 'ramda'

orderStore = require 'stores/order'
rdsOrderStore = require 'stores/rds-order'

Loader =
  getInitialState: ->
    order: null
    rdsOrder: null
    notifications: []
    events: []
    actions: []
    rdsActions: []
    orderInfo: null
    currentAction: null
    restaurant: null
    channel: null
    reloading: false
    error: null

  componentDidMount: ->
    @plug orderStore.current, 'order'
    @plug rdsOrderStore.current, 'rdsOrder'
    @plug orderStore.notifications, 'notifications'
    @plug orderStore.events, 'events'
    @plug orderStore.actions, 'actions'
    # @plug rdsOrderStore.rdsActions, 'rdsActions'
    @plug orderStore.reloadingOrder, 'reloading'
    @plug orderStore.restaurant, 'restaurant'
    @plug orderStore.channel, 'channel'
    @plug orderStore.errors, 'error'

    orderStore.openOrderById @props.match.params.orderId

  componentWillReceiveProps: (nextProps) ->
    if nextProps.match.params.orderId != R.path(['order', 'id'], @state)
      @setState order: null
      orderStore.openOrderById nextProps.match.params.orderId

  componentWillUnmount: ->
    orderStore.closeOrder()

  getLocale: ->
    if @state.restaurant then @state.restaurant.locale else 'en'

  renderLoadingWithErrors: ->
    React.createElement("div", null,
      ( @_renderError() ), """
      Please wait while loading the order information....
""")

  _renderError: ->
    if @state.error
      React.createElement("div", {"className": "alert alert-danger", "role": "alert"}, """
        There was an error trying to load data. """, React.createElement("br", null),
        (@state.error.status.code), " - ", (@state.error.status.message)
      )
    else
      null

module.exports = Loader
