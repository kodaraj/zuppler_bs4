React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
hopUtil = require 'utils/hop'
numeral = require 'utils/numeral_setup'
createReactClass = require 'create-react-class'

{ BaconMixin } = ReactBacon

orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToListItems, googleMapsLinkToAddress } = orderUtils


{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'

RestaurantInfo = createReactClass
  displayName: 'RestaurantInfo'
  mixins: [ExpandedStateMixin("sections.restaurant.visible")]

  hop: ->
    @hours_of_operation or= new hopUtil.HoursOfOperation @props.restaurant.hours_of_operation.machine,
      @props.restaurant.timezone.offset

  contact: ->
    id = @props.order.service.id.toLowerCase()
    serviceConfig = @props.restaurant.configuration[id]
    if serviceConfig
      serviceConfig.contact || {}

  _now: ->
    moment().utcOffset @props.restaurant.timezone.offset

  _openInfo: ->
    hop = @hop()
    isOpen = hop.status()
    if isOpen
      date = hop.closingTime()
    else
      date = hop.openingTime()

    if isOpen
      <span><span className="label label-info">OPEN!</span> Closes {date.fromNow()}</span>
    else
      <span>
        <span className="label label-danger">CLOSED!</span> Opens {date.fromNow()} ({date.utcOffset(@props.restaurant.timezone.offset).format('lll')})
      </span>

  _openHours: ->
    hop = @hop()
    oh = hop.openingHours()
    if oh
      "#{oh.start.format('hh:mm a')} - #{oh.end.format('hh:mm a')}"
    else
      "- closed -"

  _localTime: ->
    restaurantNow = moment().utcOffset(@props.restaurant.timezone.offset).format('lll')
    "#{restaurantNow} [#{@props.restaurant.timezone.name}]"

  render: ->
    contact = @contact()
    cpURL = "#{CP_SVC}/restaurants/#{@props.restaurant.permalink}"

    pairs = [
      ["Name", @props.order.restaurant.name]
    ]

    pairs = R.concat pairs, touple "#{@props.order.service.label} Contact", contact.name if contact.name

    if !@state.hidden
      pairs = R.concat pairs, touple 'Phone', <a href="tel:#{contact.phone}">{contact.phone}</a> if contact.phone
      pairs = R.concat pairs, touple "Email", <a href="mailto:#{contact.email}">{contact.email}</a> if contact.email
      pairs = R.concat pairs, touple 'Fax', contact.fax if contact.fax

      if @props.restaurant.configuration.ordering_paused
        pairs = R.concat pairs, touple 'Ordering Paused', <span className="label label-danger">{booleanOf @props.restaurant.configuration.ordering_paused}</span>
      else
        pairs = R.concat pairs, touple 'Ordering Paused', <span className="label label-info">{booleanOf @props.restaurant.configuration.ordering_paused}</span>

      pairs = R.concat pairs, touple 'Restaurant Time', <span key={@props.restaurant.permalink}>{@_localTime()}</span>
      pairs = R.concat pairs, touple 'Open Hours', <span key={@props.restaurant.permalink}>{@_openHours()}</span>
      pairs = R.concat pairs, touple 'State', <span key={@props.restaurant.permalink}>{@_openInfo()}</span>

      if @props.channel
        pairs = R.concat pairs, touple 'Channel Name', <span><a href={@props.channel.url} target="_blank">{@props.order.channel.name}</a> ({@props.order.channel.permalink})</span>
        pairs = R.concat pairs, touple 'Integration', @props.order.channel.integration
        pairs = R.concat pairs, touple 'Channel Contact', @props.channel.contact.name if @props.channel.contact.name
        pairs = R.concat pairs, touple 'Channel Email', <a href="email:#{@props.channel.contact.email}">{@props.channel.contact.email}</a> if @props.channel.contact.email
        pairs = R.concat pairs, touple 'Channel Phone', <a href="tel:#{@props.channel.contact.phone}">{@props.channel.contact.phone}</a>  if @props.channel.contact.phone

    <ul className="list-group">
      <GroupHeader title="Restaurant" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState}>
        <a href={cpURL} key="cp-url" target="_blank" className="btn-order-header"><Icon name="cogs" /></a>
      </GroupHeader>
      <span className={@expandedToClassName()}>
        {pairsToListItems("restaurant_info", pairs, key: @props.restaurant.permalink)}
      </span>
    </ul>

module.exports = RestaurantInfo
