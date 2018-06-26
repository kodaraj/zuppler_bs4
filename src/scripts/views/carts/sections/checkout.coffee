R = require 'ramda'
Bacon = require 'baconjs'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


validate = require "validate.js"
moment = require "moment"
RS = require 'reactstrap'
import { CardBody, CardTitle, ButtonGroup, Button, Form} from 'reactstrap'
Cart = require './fields'

restaurantStore = require 'zuppler-js/lib/stores/restaurant'
cartStore = require 'zuppler-js/lib/stores/cart'
cartSettingsStore = require 'zuppler-js/lib/stores/cart/settings'
userStore = require 'zuppler-js/lib/stores/user'
uiStore = require 'stores/ui'
cartsStore = require 'stores/carts'

convertTime = (dateTimeString) ->
  moment(dateTimeString).format("YYYY-MM-DD HH:mm")

Card = createReactClass
  displayName: 'CheckoutCard'

  mixins: [ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin'), require('./cart-errors-mixin')]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    cart: null
    tender: null
    tip: null
    availableTenders: []
    errors: {}

  componentDidMount: ->
    @plug cartStore.cart, 'cart'
    @plug cartSettingsStore.tender.selected, 'tender'
    @plug cartSettingsStore.tip.value, 'tip'

    optionsStream = Bacon
      .combineTemplate
        orderTime: @props.cart.orderTime
        orderType: @props.cart.orderType
        address: @props.cart.address
      .filter ({orderTime, orderType, address}) -> !!orderTime and !!orderType

    @observeStream optionsStream, @setCartOptions

    @observeStream cartStore.errors, @setErrors('cart').bind(@)
    @observeStream cartSettingsStore.orderType.errors, @setErrors('order').bind(@)
    @observeStream cartSettingsStore.orderTime.errors, @setErrors('time').bind(@)
    @observeStream cartSettingsStore.tender.errors, @setErrors('tender').bind(@)
    @observeStream cartSettingsStore.tip.errors, @setErrors('tip').bind(@)

  setCartOptions: ({orderTime, orderType, address}) ->
    cartSettingsStore.orderType.setSelection orderType
    cartSettingsStore.orderType.setValue address if orderType is 'DELIVERY'
    # TODO: Use asap maybe?
    cartSettingsStore.orderTime.setSelection 'SCHEDULED'
    cartSettingsStore.orderTime.setValue convertTime(orderTime)

  setErrors: R.curry (key, errors) ->
    @setState errors: R.assoc key, errors, @state.errors

  render: ->
    return null if !@state.cart

    valid = @state.cart.valid
    className = cx "panel-success": valid, 'panel-danger': !valid
    onClick = R.partial @props.onChangeSection, ['checkout']
    <RS.Card onClick={onClick} className={className}>
      <CardBody>
        <CardTitle>{@renderHeader()}</CardTitle>
        { @renderContent() }
      </CardBody>
    </RS.Card>

  renderContent: ->
    errorCount = @cartErrorCount()
    errorClass = cx 'text-danger', 'hidden': errorCount == 0
    <div>
      { @renderTenderInfo() }
      { @renderTipInfo() }
      <small className={errorClass}><em>{ errorCount } error(s)</em></small>
    </div>

  renderTenderInfo: ->
    if @state.tender
      <div key="tender">Paying with {@state.tender.name}</div>

  renderTipInfo: ->
    if @state.tip
      <div key="tip"> Tip { @state.tip }%</div>

  renderHeader: ->
    <div>With options:</div>

Editor = createReactClass
  displayName: 'CheckoutEditor'

  mixins: [ ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin'), require('./cart-errors-mixin') ]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->

  onSave: ->
    @props.onClose('info')

  onClose: ->
    @props.onClose('info')

  render: ->
    <div>
      <Form>
        <Cart.OrderType section={cartSettingsStore.orderType} />
        <Cart.Time section={cartSettingsStore.orderTime} />
        <Cart.Tender section={cartSettingsStore.tender} />
        <Cart.Tip section={cartSettingsStore.tip} />
      </Form>

      { @renderCartMessages() }

      <ButtonGroup>
        <Button onClick={@onClose}>Close</Button>
        <Button color="primary" onClick={@onSave}>Save & Continue</Button>
      </ButtonGroup>
    </div>

module.exports =
  name: 'checkout'
  Card: Card
  Editor: Editor
