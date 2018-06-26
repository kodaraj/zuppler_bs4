React = require 'react'
R = require 'ramda'
account = require 'accounting'
ReactBacon = require 'react-bacon'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


restaurant = require 'zuppler-js/lib/stores/restaurant'

formatMoney = (value, locale) ->
  switch locale
    when 'en' then account.formatMoney(value)
    when 'en-CA' then account.formatMoney(value)
    when 'en-IE', 'nl' then account.formatMoney(value, "€", 2, ".", ",")
    when 'en-GB' then account.formatMoney(value, "£", 2, ".", ",")
    when 'en-MT' then account.formatMoney(value, "€", 2, ".", ",")
    else account.formatMoney(value)

Money = createReactClass
  displayName: "Money"
  mixins: [ ReactBacon.BaconMixin ]

  props:
    value: PropTypes.number
    nullLabel: PropTypes.string
    className: PropTypes.string
    style: PropTypes.object
    multiplePrices: PropTypes.bool

  getDefaultProps: ->
    nullLabel: ""
    className: null
    style: null

  getInitialState: ->
    locale: null

  componentDidMount: ->
    @plug restaurant.locale, 'locale'

  render: ->
    return <span></span> if !@state.locale

    if @props.value
      <span className={@props.className} style={@props.style}>
        { formatMoney(@props.value, @state.locale) }{@renderBasePriceIndicator()}
      </span>
    else
      <span></span>

  renderBasePriceIndicator: ->
    "+" if @props.multiplePrices

module.exports = Money
