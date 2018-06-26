React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

orderStore = require 'stores/order'
rdsOrderStore = require 'stores/rds-order'
ordersStore = require 'stores/orders'
uiStore = require 'stores/ui'
{ Container, Col, Row, Button } = require 'reactstrap'

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

OrderTab = createReactClass
  displayName: 'OrderTab'
  mixins: [ReactBacon.BaconMixin, require('./loader')]

  componentWillMount: ->
    uiStore.setCurrentUI("orders", "orderId")

  render: ->
    if !@state.order or !@state.restaurant
      return @renderLoadingWithErrors()

    if @state.order
      <Container fluid={true} style={paddingLeft: "0px", paddingRight: "0px"} key={@state.order.id}>
        { @renderToolbarRow(@state.order, @state.rdsOrder) }
        { @renderContentRow(@state.order, @getLocale()) }
      </Container>
    else
      null

  onRemoveTab: ->
    ordersStore.unpin @state.order.id
    uiStore.switchToFirst()

  renderToolbarRow: (order, rdsOrder) ->
    <Row key="toobar">
      <Col sm={12}>
        <OrderToolbar key={@state.order.id} model={orderStore} order={order} rdsOrder={rdsOrder} actions={@state.actions} notifications={@state.notifications}>
          <Button onClick={@onRemoveTab}> <Icon fixedWidth name="remove"/> </Button>
        </OrderToolbar>
      </Col>
    </Row>

  renderContentRow: (order, locale) ->
    state = if @state.events.length then @state.events[0].state else "n/a"

    <Row key="content" key={order.id}>
      <Col xs={12} sm={12} key={@state.order.id}>
        {@_renderError()}
        <OrderHeading order={@state.order} rdsOrder={@state.rdsOrder} restaurant={@state.restaurant} state={state} locale={locale}/>
      </Col>
      <Col xs={12} sm={12} md={6} lg={4}>
        <OrderInfo key="order_info_#{@state.order.id}" order={@state.order} locale={locale} restaurant={@state.restaurant} events={@state.events} />
        <RestaurantInfo key={@state.restaurant.permalink} restaurant={@state.restaurant} channel={@state.channel} order={@state.order} />
      </Col>
      <Col xs={12} sm={12} md={6} lg={4}>
        {
          if @state.rdsOrder
            <UserIs role="dispatcher">
              <DeliveryInfo order={@state.rdsOrder} locale={locale} restaurant={@state.restaurant}/>
            </UserIs>
        }
        <OrderItems order={@state.order} locale={locale} restaurant={@state.restaurant} />
      </Col>
      <Col xs={12} sm={12} md={6} lg={4}>
        <OrderTotal order={@state.order} locale={locale} restaurant={@state.restaurant} />
        <RestaurantNotifications order={@state.order} locale={locale} restaurant={@state.restaurant} notifications={@state.notifications}/>
        <UserWants name="show-order-events">
          <OrderEvents order={@state.order} locale={locale} restaurant={@state.restaurant} events={@state.events}/>
        </UserWants>
      </Col>
    </Row>

module.exports = OrderTab
