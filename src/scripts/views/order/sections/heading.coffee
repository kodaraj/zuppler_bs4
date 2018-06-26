React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
{Icon }= require 'react-fa'
cx = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

{ UserIs } = require 'views/order/components/utils'
{ Grid, Row, Col } = require 'reactstrap'

orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToTable, pairsToList, googleMapsLinkToAddress, Money } = orderUtils

shortenUUID = (uuid) -> uuid.split(/-/)[0]

presenceStore = require 'stores/presence'

UserPresence = createReactClass
  displayName: "UserPresence"
  mixins: [ReactBacon.BaconMixin]

  propTypes:
    orderId: PropTypes.string.isRequired

  getInitialState: ->
    orders: {}

  componentDidMount: ->
    @plug presenceStore.orders, 'orders'

  users: ->
    @state.orders[@props.orderId] || []

  render: ->
    initials = R.compose(R.join(""), R.map((str)-> str.substring(0,1)), R.split(/\s+/))
    roles = R.join(", ")
    roleToClass = R.map (n) -> "presence-role-#{n}"

    usersTags = @users().map (u) ->
      className = cx "label", "label-default", roleToClass(u.roles).join(" ")
      title = "#{u.user} is #{roles(u.roles)}"
      <span key={u.email} className={className} title={title}>{initials u.user || "N A"}</span>

    <span className="presence-info">
      {usersTags}
    </span>

OrderHeading = createReactClass
  displayName: 'OrderHeading'
  propTypes:
    order: PropTypes.object.isRequired
    rdsOrder: PropTypes.object
    restaurant: PropTypes.object.isRequired
    state: PropTypes.string.isRequired
    locale: PropTypes.string.isRequired

  _serviceAddress: (order) ->
    switch order.service.id
      when 'DELIVERY' then order.service.value.address
      when 'PICKUP', 'DINEIN' then order.service.value.location
      when 'CURBSIDE' then order.service.value.location

  _renderPayment: (order) ->
    paidLabel = if order.tender.value.paid then "Paid" else "To Pay"
    switch order.tender.id
      when 'CARD'
        <OrderHeadingInfo key="payment" label="payment" icon="money">
          <span key="l" className="label">{paidLabel}</span>
          <span key="t">{order.tender.value.type}</span>
          <span key="c" className="label">Card</span>
          <span key="e">ending {order.tender.value.last_4_digits}</span>
        </OrderHeadingInfo>
      when 'BUCKID', 'ACCOUNT'
        <OrderHeadingInfo key="payment" label="payment" icon="money">
          <span key="l" className="label">{paidLabel}</span>
          <span key="a">{order.tender.value.account}</span>
        </OrderHeadingInfo>
      else
        <OrderHeadingInfo key="payment" label="payment" icon="money">
          <span key="t" className="label">{order.tender.label}</span>
        </OrderHeadingInfo>

  _renderTime: (order) ->
    formatTime = R.partial(formatTimeWithOffset, [@props.restaurant.timezone.offset])
    asapClass = cx 'label', 'hidden': order.time.id isnt 'ASAP'
    <OrderHeadingInfo key="time" label="Due" icon="clock-o">
      <span key="asap" className={asapClass}>ASAP</span>
      <span key="time">{formatTime(order.time.value)}</span>
    </OrderHeadingInfo>

  render: ->
    cn = cx "order-heading", "order-#{@props.state}"
    <Row key={@props.order.id} className={cn}>
      <Col xs={12} md={2}>
        <OrderHeadingInfo key="id" label="id">{shortenUUID @props.order.id}</OrderHeadingInfo>
        <OrderHeadingInfo key="state" label="state">{@props.state}</OrderHeadingInfo>
        {
          if @props.rdsOrder
            <UserIs role="dispatcher">
              <OrderHeadingInfo key="deliveryStatus" label="Delivery Status">{@delivery_label(@props.rdsOrder.state)}</OrderHeadingInfo>
            </UserIs>
        }

        <OrderHeadingInfo key="type" label="type">
          <span key="svc">{@props.order.service.label}</span>
          <span key="total" className="label"><Money amount={@props.order.totals.total} locale={@props.locale} alwaysShow={true}/></span>
        </OrderHeadingInfo>
      </Col>
      <Col xs={12} md={5} className="icons-section">
        <OrderHeadingInfo key="customer" label="customer" icon="male">
          <span>{@props.order.customer.name} {@renderRegisterIndicator(@props.order.customer)}</span><br />
          <span>{@props.order.customer.email}</span> <span>{@props.order.customer.phone}</span>
        </OrderHeadingInfo>
        <OrderHeadingInfo key="address" label="address" icon="globe">{@_serviceAddress(@props.order)}</OrderHeadingInfo>
        {
          if @props.rdsOrder
            <UserIs role="dispatcher">
              <OrderHeadingInfo key="driver" label="Driver" icon="car">
                {@props.rdsOrder.driverName}
              </OrderHeadingInfo>
            </UserIs>
        }
      </Col>
      <Col xs={12} md={5} className="icons-section">
        <OrderHeadingInfo key="restaurant" label="restaurant" icon="university">{@props.restaurant.name}</OrderHeadingInfo>
        {@_renderPayment(@props.order)}
        {@_renderTime(@props.order)}
        <UserPresence key={@props.order.id} orderId={@props.order.id} />
      </Col>
    </Row>

  renderRegisterIndicator: (customer) ->
    if customer.resource_url
      <Icon name="registered" />

  delivery_label: (state)->
    switch state
      when 'confirmed' then 'pending driver assigment'
      when 'sent_to_acceptance' then 'pending driver acceptance'
      when 'accepted' then 'accepted'
      when 'zuppler_notified' then 'delivering'
      when 'error_state' then 'error'
      when 'delivered' then 'delivered'
      when 'delivery_canceled' then 'delivery canceled'
      else state

OrderHeadingInfo = createReactClass
  displayName: 'OrderHeadingInfo'
  renderIcon: ->
    if !!@props.icon
      <Icon name={@props.icon} className="info-icon" />
    else
      null

  render: ->
    sufix = @props.label.toLowerCase().split(/\s+/).join("")
    classes = cx "info", "info-" + sufix
    valueClasses = cx "info-value", "info-value-" + sufix
    <p className={classes}>
      {@renderIcon()}
      <span key="label" className="info-label">{@props.label}: </span>
      <span key="content" className={valueClasses}>{@props.children}</span>
    </p>


module.exports = OrderHeading
