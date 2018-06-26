React = require 'react'
R = require 'ramda'
moment = require 'moment'
timeUtils = require 'utils/time'
userStore = require 'stores/user'
cx = require 'classnames'
{Icon }= require 'react-fa'
hopUtil = require 'utils/hop'
numeral = require 'utils/numeral_setup'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToTable, pairsToList, googleMapsLinkToAddress, Money } = orderUtils


{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'

OrderTotal = createReactClass
  displayName: 'OrderTotals'
  mixins: [ExpandedStateMixin("sections.totals.visible")]
  propTypes:
    order: PropTypes.object.isRequired
    restaurant: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired

  _renderDiscount: ->
    if @props.order.totals.discount
      discounts = R.reduce (sum, cart) ->
        R.reduce (sum, discount) ->
          title = <span key="title" className="badge">{discount.badge} {discount.title}</span>
          code = if discount.code then <span key="code" className="badge"><Icon name="qrcode"  title="Discount code used"/> {discount.code}</span> else null
          firstTime = if discount.first_time then <Icon key="ftu-flag" name="flag-o" title="First time user"/> else null
          R.concat sum, [<span key={discount.id}>{title} {code} {firstTime}</span>]
        , sum, cart.discounts
      , [], @props.order.carts
      <span>
        <Icon name="money"/> <Money amount={@props.order.totals.discount} locale={@props.locale} alwaysShow={true}/>
        <br/>
        {discounts}
      </span>
    else
      "- none applied -"

  _tip: (pairs, order, locale) ->
    if order.tip.value > 0
      switch order.tip.id
        when 'AMOUNT'
          pairs = R.concat pairs, touple 'Tip', <span><span className="badge">Amount</span> <Money amount={order.tip.value} locale={locale} /></span>
        when 'PERCENT'
          pairs = R.concat pairs, touple 'Tip', <span><span className="badge">Percent</span> <Money amount={order.tip.value} locale={locale} /></span>
    pairs

  render: ->
    pairs = []
    o = @props.order

    if @props.order.totals.subtotal > 0
      pairs = R.concat pairs, touple 'Subtotal', <Money locale={@props.locale} amount={o.totals.subtotal} />
    if @props.order.totals.discount
      pairs = R.concat pairs, touple 'Discount', @_renderDiscount()
    if @props.order.totals.tax
      pairs = R.concat pairs, touple 'Tax', <Money amount={@props.order.totals.tax} locale={@props.locale} alwaysShow={true}/>
    if @props.order.totals.charges.service
      pairs = R.concat pairs, touple 'Service Fee', <Money amount={@props.order.totals.charges.service} locale={@props.locale} alwaysShow={true}/>
    if @props.order.totals.charges.delivery > 0
      pairs = R.concat pairs, touple 'Delivery', <Money locale={@props.locale} amount={o.totals.charges.delivery} />
    pairs = @_tip(pairs, o, @props.locale)

    pairs = R.concat pairs, touple 'Total',
      <Money locale={@props.locale} amount={o.totals.total} />

    tableStyle = cx @expandedToClassName(), 'table', 'table-striped'

    mapIndexed = R.addIndex(R.map)
    tags = mapIndexed (pair, index) ->
      key = "totals_#{index}"
      <tr key={key}>
        <td key="label" className="text-info">{pair[0]}</td>
        <td key="value" className="text-info text-right">{pair[1]}</td>
      </tr>
    , pairs

    <ul className="list-group">
      <GroupHeader title="Totals" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState}>
      </GroupHeader>
      <table className={tableStyle}>
        <tbody>
          {tags}
        </tbody>
      </table>
    </ul>

module.exports = OrderTotal
