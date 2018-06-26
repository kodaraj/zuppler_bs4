React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{ Icon }= require 'react-fa'
hopUtil = require 'utils/hop'
cx = require 'classnames'
userStore = require 'stores/user'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ Table } = require 'reactstrap'
numeral = require 'numeral'
require 'numeral/locales'


{ BaconMixin } = ReactBacon

toID = (name) ->
  name.toLowerCase().replace /\W/g, '_'

shortID = (longID) ->
  longID.split(/-/)[0]

touple = (a, b) -> [[a, b]]

booleanOf = (b) -> if b then "yes" else "no"
currency = (locale, value) ->
  numeral.locale(locale)
  numeral(value / 100).format("$0,0.00")
percent = (locale, value) ->
  numeral.locale(locale)
  numeral(value / 10000).format("0.00%")
formatTimeWithOffset = (offset, value) ->
  m = moment Date.parse value
  if offset
    m.utcOffset offset
    "#{m.fromNow()} - #{m.format('llll')}"
  else
    "#{m.fromNow()}"

pairsToTable = (section, pairs, options = {}) ->
  mapIndexed = R.addIndex(R.map)
  tags = mapIndexed (pair, index) ->
    key = "#{section}_#{index}"
    <tr key={key}>
      <td key="label" className={options.labelClass}>{pair[0]}</td>
      <td key="value" className={options.valueClass}>{pair[1]}</td>
    </tr>
  , pairs

  headerClass = cx options.headerClass, 'hidden': !options.header

  <Table striped>
    <thead>
      <th colSpan={2} className={headerClass}>{options.header}</th>
    </thead>
    <tbody>
      {tags}
    </tbody>
  </Table>

pairsToList = (section, pairs, options = {}) ->
  tags = pairsToListItems(section, pairs, options)

  headerClass = cx 'list-group-item', 'section-header', options.headerClass, 'hidden': !options.header

  actions = options.actions || []
  actions = R.append React.createElement("a", {"key": "toggle", "className": "btn-order-header", "onClick": (options.onToggleSection)}, React.createElement(Icon, {"name": (if options.visible then "eye" else "eye-slash")})), actions if options.onToggleSection

  <ul className="list-group" key={options.key || "list"}>
    <li className={headerClass}>
      {options.header}
      <span key="actions" className="pull-right">
        {actions}
      </span>
    </li>
    {tags}
  </ul>

pairsToListItems = (section, pairs, options = {}) ->
  mapIndexed = R.addIndex(R.map)
  tags = mapIndexed (pair, index) ->
    key = "#{section}_#{index}_#{options.key}"
    <li className="list-group-item" key={key}>
      <span key="label" style={fontWeight: 'bold'}>{pair[0]}: </span>
      <span key="value">{pair[1]}</span>
    </li>
  , pairs

pairsToListWithHeader = (section, pairs, options = {}) ->
  tags = pairsToListItems(section, pairs, options)
  <ul className="list-group" key={options.key || "list"}>
    {options.header}
    {if options.visible then tags else null}
  </ul>

googleMapsLinkToAddress = (address) ->
  if address
    <a href="http://maps.google.com?q=#{escape(address)}" target="_blank">
      <Icon name="globe" /> {address}
    </a>
  else
    null

Money = createReactClass
  displayName: 'money'
  propTypes:
    amount: PropTypes.number.isRequired
    locale: PropTypes.string.isRequired
    quantity: PropTypes.number
    alwaysShow: PropTypes.bool

  render: ->
    quantity = null
    if @props.quantity and @props.quantity > 1
      quantity = <span>{@props.quantity} x </span>

    if @props.amount > 0 or @props.alwaysShow
      <span>{quantity}{currency(@props.locale, @props.amount)}</span>
    else
      <span></span>

UserIs = createReactClass
  displayName: 'UserIs'
  propTypes:
    role: PropTypes.string.isRequired
    or: PropTypes.string
    and: PropTypes.string

  render: ->
    hasRole = userStore.hasRole @props.role
    hasRole or= userStore.hasRole @props.or if @props.or
    hasRole and= userStore.hasRole @props.and if @props.and

    if hasRole
      <span>{@props.children}</span>
    else
      null

UserIsNot = createReactClass
  displayName: 'UserIs'
  propTypes:
    role: PropTypes.string.isRequired
    or: PropTypes.string
    and: PropTypes.string

  render: ->
    hasRole = userStore.hasRole @props.role
    hasRole or= userStore.hasRole @props.or if @props.or
    hasRole and= userStore.hasRole @props.and if @props.and

    unless hasRole
      <span>{@props.children}</span>
    else
      null

UserWants = createReactClass
  displayName: 'UserWants'
  propTypes:
    name: PropTypes.string.isRequired
    condition: PropTypes.func
    default: PropTypes.string
    or: PropTypes.string
    and: PropTypes.string

  render: ->
    setting = userStore.settingFor @props.name
    setting or= userStore.settingFor @props.or if @props.or
    setting and= userStore.settingFor @props.and if @props.and

    if setting or (@props.condition and @props.condition())
      <span>{@props.children}</span>
    else
      if @props.default then <span>{@props.default}</span> else null

serviceSetting = (serviceId, action, defaultProp) ->
  defaultServiceValue = R.defaultTo(action.settings[defaultProp])
  setting = action.settings[serviceId]
  defaultServiceValue if !R.isEmpty(setting) then setting else null

orderActionLabel = (order, action) ->
  alive = moment(action.hearbeat).isAfter("2011-09-01")

  activeClass = cx 'text-success': alive && action.active,
    'text-warning': !alive && action.active
    'text-default': !action.active

  serviceId = order.service.id.toLowerCase()
  onlyData = R.omit ['links', 'heartbeat', 'active']
  switch (action.type || action.name || "N/A").toLowerCase()
    when 'email'
      address = serviceSetting(serviceId, action, 'default_email')
      <span><Icon name="envelope-o" className={activeClass} /> by email to {address}</span>
    when 'fax'
      address = serviceSetting(serviceId, action, 'default_fax')
      <span><Icon name="fax" className={activeClass} /> by fax to {address}</span>
    when 'pos'
      <span><Icon name="desktop" className={activeClass} /> by POS {action.name}</span>
    when 'goodcom'
      <span><Icon name="sellsy" className={activeClass} /> by Goodcom</span>
    when 'ibacstel'
      <span><Icon name="sellsy" className={activeClass} /> by IBacsTel</span>
    when 'rds'
      <span><Icon name="desktop" className={activeClass} /> by RDS {action.name} </span>
    when 'googlecloudprint'
      <span><Icon name="print" className={activeClass} /> by Google Cloud connected printer</span>
    when 'android'
      <span><Icon name="android" className={activeClass} /> by OrderZupp/{action.settings.app_version} on {action.settings.product} {action.settings.model}</span>
    when 'ivr'
      address = serviceSetting("#{serviceId}_phone", action, 'phone')
      <span><Icon name="phone" className={activeClass} /> by IVR Call to {address} </span>
    else
      <span><Icon name="question" className={activeClass} />{ JSON.stringify(onlyData(action)) }</span>


module.exports =
  toID: toID
  shortID: shortID
  touple: touple
  booleanOf: booleanOf
  currency: currency
  percent: percent
  formatTimeWithOffset: formatTimeWithOffset
  pairsToTable: pairsToTable
  pairsToList: pairsToList
  pairsToListItems: pairsToListItems
  pairsToListWithHeader: pairsToListWithHeader
  googleMapsLinkToAddress: googleMapsLinkToAddress
  Money: Money
  UserIs: UserIs
  UserIsNot: UserIsNot
  UserWants: UserWants
  orderActionLabel: orderActionLabel
