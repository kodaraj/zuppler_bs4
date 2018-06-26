React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
createReactClass = require 'create-react-class'

orderStore = require 'stores/order'
rdsOrderStore = require 'stores/rds-order'
ordersStore = require 'stores/orders'
uiStore = require 'stores/ui'

{Row, Col, Button} = require 'reactstrap'

orderUtils = require './components/utils'

{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToTable, pairsToList, googleMapsLinkToAddress } = orderUtils
{ UserIs, UserIsNot, UserWants } = orderUtils

OrderInfo               = require './sections/info'
CustomerInfo            = require './sections/customer'
RestaurantInfo          = require './sections/restaurant'
OrderItems              = require './sections/items'
OrderEvents             = require './sections/events'
RestaurantNotifications = require './sections/notifications'
OrderTotal              = require './sections/total'
OrderHeading            = require './sections/heading'
DeliveryInfo            = require './sections/delivery'

OrderToolbar            = require './toolbar'

Order = require 'models/order'

OrderPage = createReactClass
  displayName: 'OrderPage'
  mixins: [ReactBacon.BaconMixin, require('./loader')]

  shouldComponentUpdate: (p, s) ->
    !s.reloading or !!s.error

  render: ->
    if !@state.order or !@state.restaurant
      return @renderLoadingWithErrors()

    @renderOrder(@state.order, @getLocale())

  onPinTab: ->
    ordersStore.pin @state.order.id

  renderOrder: (order, locale) ->
    state = if @state.events.length then @state.events[0].state else "n/a"

    <Col key={order.id} md={9} sm={9} style={paddingTop: "10px"}>
      <Row>
        <Col xs={12}>
          {@_renderError()}
          <OrderHeading key={R.join("-", [@state.order.id, @state.restaurant.permalink])} order={@state.order} rdsOrder={@state.rdsOrder} restaurant={@state.restaurant} state={state} locale={locale}/>
          <OrderToolbar key={@state.order.id} model={orderStore} rdsOrder={@state.rdsOrder} order={@state.order} actions={@state.actions} notifications={@state.notifications}>
            <Button onClick={@onPinTab}> <Icon fixedWidth name="thumb-tack"/> </Button>
          </OrderToolbar>
        </Col>
        <Col xs={12} sm={12} md={6} lg={6}>
          <OrderInfo key="order_info_#{@state.order.id}" order={@state.order} locale={locale} restaurant={@state.restaurant} events={@state.events} />
          <RestaurantInfo key={@state.restaurant.permalink} restaurant={@state.restaurant} channel={@state.channel} order={@state.order} />
        </Col>
        <Col xs={12} sm={12} md={6} lg={6}>
          {
            if @state.rdsOrder
              <UserIs role="dispatcher">
                <DeliveryInfo order={@state.rdsOrder} locale={locale} restaurant={@state.restaurant}/>
              </UserIs>
          }
          <OrderTotal order={@state.order} locale={locale} restaurant={@state.restaurant} />
          <OrderItems order={@state.order} locale={locale} restaurant={@state.restaurant} />
          <UserIs role="restaurant_admin" or="config">
            <UserWants name="show-order-events">
              <OrderEvents order={@state.order} locale={locale} restaurant={@state.restaurant} events={@state.events}/>
            </UserWants>
          </UserIs>
          <RestaurantNotifications order={@state.order} locale={locale} restaurant={@state.restaurant} notifications={@state.notifications}/>
        </Col>
      </Row>
    </Col>

module.exports = OrderPage
