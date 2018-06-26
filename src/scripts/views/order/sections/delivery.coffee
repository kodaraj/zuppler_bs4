React      = require 'react'
ReactBacon = require 'react-bacon'
R          = require 'ramda'
moment     = require 'moment'
{Icon       }= require 'react-fa'
hopUtil    = require 'utils/hop'
cx         = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


{ BaconMixin }           = ReactBacon

{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'
orderUtils = require '../components/utils'
{ touple, pairsToList, pairsToListItems, formatTimeWithOffset } = orderUtils

DeliveryInfo = createReactClass
  displayName: 'DeliveryInfo'
  mixins: [ExpandedStateMixin("sections.delivery.visible"), ReactBacon.BaconMixin]
  propTypes:
    order: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired
    restaurant: PropTypes.object.isRequired

  getInitialState: ->

  componentDidMount: ->

  _pickup_time: (pairs, order) ->
    return pairs unless order.start_time
    formatTime = R.partial(formatTimeWithOffset, [@props.restaurant.timezone.offset])
    R.concat pairs, touple 'Pickup time', formatTime(order.start_time)

  _delivery_time: (pairs, order) ->
    return pairs unless order.delivery_time
    formatTime = R.partial(formatTimeWithOffset, [@props.restaurant.timezone.offset])
    R.concat pairs, touple 'Delivery time', formatTime(order.delivery_time)

  _driver: (pairs, order) ->
    R.concat pairs, touple 'Driver', React.createElement("span", null, React.createElement(Icon, {"name": "car"}), " ", (order.driverName))

  render: ->
    o = @props.order
    pairs = [
      ['Status', React.createElement("span", null, (o.state))]
    ]

    pairs = @_pickup_time(pairs, o)
    pairs = @_delivery_time(pairs, o)
    pairs = @_driver(pairs, o)

    # pairsToList "order_info", pairs, header: <span key="label">Order Info</span>

    <ul className="list-group">
      <GroupHeader title="Delivery Info" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState}>
      </GroupHeader>
      <span className={@expandedToClassName()}>
        {pairsToListItems("order_info", pairs, key: @props.restaurant.permalink)}
      </span>
    </ul>

module.exports = DeliveryInfo
