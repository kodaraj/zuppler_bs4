React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
hopUtil = require 'utils/hop'
numeral = require 'utils/numeral_setup'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

userStore = require 'stores/user'
{ Row, Col, Table } = require 'reactstrap'
{ BaconMixin } = ReactBacon

orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, googleMapsLinkToAddress } = orderUtils
{ Money, UserIs, UserWants } = orderUtils

moneyStyle = {textAlign: "right"}

toMoney = (cents, locale) ->
  <Money locale={locale} amount={cents} />


feedbackStore = require 'stores/feedback'

atLeast = (min, qty) -> min <= qty

Item = createReactClass
  displayName: 'CartItem'
  propTypes:
    item: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired
    rating: PropTypes.object
    subject: PropTypes.object

  renderModifiers: ->
    locale = @props.locale
    itemQuantity = @props.item.quantity
    @props.item.groups.map (group) ->
      <ModifierGroup key={group.name} group={group} locale={locale} itemQuantity={itemQuantity}/>

  renderComments: ->
    if @props.item.comments
      <tr key="comments">
        <td colSpan={3}>
          <em className="text text-info">{@props.item.comments}</em>
        </td>
      </tr>
    else
      null

  render: ->
    minOne = R.partial atLeast, [2, @props.item.quantity]
    if @props.rating
      ratingIcon = [
        <Icon name="thumbs-down" />
        <Icon name="thumbs-up" />
      ][@props.rating.score - 1]
    else
      ratingIcon = <Icon name="shopping-cart" />

    <tbody key={@props.item.id}>
      <tr key="item">
        <td>
          <UserWants name="items.menu.name" or="items.menu.category">
            <div className="dim-light">
              <UserWants name="items.menu.name">{@props.item.menu}<UserWants name="items.menu.category"> / </UserWants></UserWants>
              <UserWants name="items.menu.category">{@props.item.category}</UserWants>
            </div>
          </UserWants>
          <div>
            <strong>
              <span>{ ratingIcon } </span>
              <UserWants name="items.min.quantity" condition={minOne}>{@props.item.quantity} x </UserWants>
              <UserWants name="items.alias" default={@props.item.name}>{@props.item.alias || @props.item.name}</UserWants>
            </strong>
          </div>
        </td>
        <td style={moneyStyle}><Money locale={@props.locale} amount={@props.item.price}/></td>
        <td style={ moneyStyle }><Money locale={@props.locale} amount={@props.item.total}/></td>
      </tr>
      {@renderComments()}
      {@renderModifiers()}
    </tbody>

ModifierGroup = createReactClass
  displayName: 'ModifierGroup'
  propTypes:
    group: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired
    itemQuantity: PropTypes.number.isRequired

  render: ->
    modifiers = null
    if @props.group.modifiers.length > 0
      locale = @props.locale
      groupName = @props.group.name
      itemQuantity = @props.itemQuantity
      modifiers = @props.group.modifiers.map (modifier) ->
        <Modifier key={modifier.id} modifier={modifier} locale={locale} groupName={groupName} itemQuantity={itemQuantity}/>
      <tr>
        <td colSpan="2">
          {modifiers}
        </td>
      </tr>
    else
      null

Modifier = createReactClass
  displayName: 'Modifier'
  propTypes:
    modifier: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired
    groupName: PropTypes.string.isRequired
    itemQuantity: PropTypes.number.isRequired

  render: ->
    minOne = R.partial atLeast, [2, @props.modifier.quantity / @props.itemQuantity]
    <Table style={width: "100%"}>
      <tbody>
        <tr>
          <td key="name" className="indent-modifier">
            <UserWants name="modifiers.group.name">
              <Row key="group">
                <Col className="dim-light">
                  {@props.groupName}
                </Col>
              </Row>
            </UserWants>
            <Row key="name">
              <Col>
                <UserWants key="qty" name="modifiers.min.quantity" condition={minOne}>{@props.modifier.quantity / @props.itemQuantity} x </UserWants>
                <UserWants key="name" name="items.alias" default={@props.modifier.name}>{@props.modifier.alias || @props.modifier.name}</UserWants>
              </Col>
            </Row>
          </td>
          <td key="price" style={ moneyStyle }><Money key="money" locale={@props.locale} amount={@props.modifier.price} quantity={@props.modifier.quantity / @props.itemQuantity}/></td>
          <td key="total" style={ moneyStyle }></td>
        </tr>
      </tbody>
    </Table>


Cart = createReactClass
  displayName: 'Cart'
  mixins: [ ReactBacon.BaconMixin ]

  propTypes:
    cart: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired

  getInitialState: ->
    feedbackSession: null
    subjects: []
    ratings: []

  componentDidMount: ->
    @plug feedbackStore.session, 'feedbackSession'
    @plug feedbackStore.subjects, 'subjects'
    @plug feedbackStore.ratings, 'ratings'

  cartHeader: ->
    if @props.cart.member.name
      <span className="label label-info">{@props.cart.member.name}</span>
    else
      null

  cartItemsHeader: ->
    null

  renderCartCaption: ->
    adjustments =
      update: (a) ->
        <li key={a.id}>[v{a.version + 1}]: Updated item quantity for <span className="label label-info">{a.description}</span> from {a.parameters.old_quantity} to {a.parameters.quantity}</li>
      remove: (a) ->
        <li key={a.id}>[v{a.version + 1}]: Removed item <span className="label label-info">{a.description}</span></li>
      add: (a) ->
        <li key={a.id}>[v{a.version + 1}]: Added {a.parameters.quantity} x <span className="label label-info">{a.description}</span></li>

    adjustmentToFunc = (adjustment) ->
      adjustments[adjustment.action.toLowerCase()](adjustment)

    if @props.cart.member.name or @props.cart.adjustments.length > 0
      title = if @props.cart.member.name then <li key="title"><span className="label label-default">Order for {@props.cart.member.name}</span></li> else null
      adjustmentsTitle = if @props.cart.version > 0 then <li key="version">Current Version: <span className="label label-info">{@props.cart.version + 1}</span></li>
      adjustments = R.reduce R.flip(R.append), [], R.map(adjustmentToFunc, @props.cart.adjustments)
      <tr>
        <td colSpan={3}>
          <ul>
            {title}
            {adjustments}
          </ul>
        </td>
      </tr>
    else
      null

  renderCartTotals: (cart, locale)->
    totalsInfo = [
      ["Subtotal", ["subtotal"]]
      ["Discount", ["discount"]]
      ["Delivery", ["charges", "delivery"]]
      ["Service", ["charges", "service"]]
      ["Tax", ["tax"]]
      ["Tip", ["tip"]]
      ["Total", ["total"]]
    ]

    totalFor = R.curry (locale, totals, [label, path]) ->
      <span className="badge badge-info">{label}: {toMoney(R.path(path, totals), locale)}</span>

    noZero = R.curry (totals, [_, path]) ->
      R.path(path, totals) > 0

    if cart.totals
      <tr>
        <td colSpan={3} style={align: "right"}>
          { R.map totalFor(locale, cart.totals), R.filter noZero(cart.totals), totalsInfo } { @renderCartTender(cart) }
        </td>
      </tr>
    else
      []

  renderCartTender: (cart) ->
    if cart.tender
      paidLabel = if cart.tender.value.paid then "Paid" else "To Pay"
      info = switch cart.tender.id
        when 'CARD'
          ending = if cart.tender.value.last_4_digits then " ending #{cart.tender.value.last_4_digits}" else ""
          "#{paidLabel} #{cart.tender.value.type} Card#{ending}"
        when 'BUCKID', 'ACCOUNT'
          "#{paidLabel} #{cart.tender.value.account}"
        else
          cart.tender.label
      <span className="label label-info">{info}</span>

  lookupSubject: (name) ->
    R.find(R.whereEq({name: name, type: 'item'}), @state.subjects)

  lookupRating: (subject) ->
    if subject then R.find(R.propEq('subject_id', subject.id), @state.ratings) else null

  render: ->
    locale = @props.locale
    items = @props.cart.items.map (item) =>
      subject = @lookupSubject item.item_name
      rating = @lookupRating subject
      <Item key={item.id} item={item} locale={locale} rating={rating} subject={subject} />

    <Table striped size="sm" hover>
      {@cartItemsHeader()}
      {@renderCartCaption()}
      {items}
      {@renderCartTotals(@props.cart, @props.locale)}
    </Table>

{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'

OrderItems = createReactClass
  displayName: 'OrderItems'
  mixins: [ExpandedStateMixin("sections.items.visible")]
  propTypes:
    order: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired

  render: ->
    locale = @props.locale
    carts = @props.order.carts.map (cart) ->
      <li key={cart.uuid} className="list-group-item">
        <Cart key={cart.uuid} cart={cart} locale={locale}/>
      </li>

    <ul className="list-group">
      <GroupHeader title="Items" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState} />
      <span className={@expandedToClassName()}>
        {carts}
      </span>
    </ul>

module.exports = OrderItems
