React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
resUtil = require 'utils/resources'
orderStore = require 'stores/order'
cx = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

_1DAY = 24*60*60*1000

{ Button, Col, Row, ButtonDropdown, DropdownItem, DropdownMenu, DropdownToggle } = require 'reactstrap'
{ BaconMixin } = ReactBacon

{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'

heartbeatClass = (time, active) ->
  return "text-default" unless active

  diff = moment().diff(moment(time))
  if diff > 3 * _1DAY
    "text-danger"
  else if diff > 1 * _1DAY
    "text-warning"
  else
    "text-success"

timeOrNever = (time, active = true) ->
  m = moment(time)
  if m.isBefore("2011-09-01")
    <span><Icon name="heart-o" inverse /> never connected</span>
  else
    <span><Icon name="heartbeat" inverse /> {moment(time).fromNow()}</span>

componentForNotification = (notification, order) ->
  comp =
    email: EmailNotification
    fax: FaxNotification
    pos: PosNotification
    rds: RdsNotification
    goodcom: GoodcomNotification
    ibacstel: IBacsTelNotification
    googlecloudprint: CloudPrintNotification
    ivr: IvrNotification
    android: AndroidNotification
    mobikon: MobikonNotification
    phone: PhoneNotification
    homer: HomerNotification
    sharpspring: SharpspringNotification

  defaultNotification = R.defaultTo DefaultNotification
  ComponentNotification = defaultNotification comp[notification.type]

  <ComponentNotification key={notification.id} order={order} notification={notification} />

RestaurantNotifications = createReactClass
  displayName: 'RestaurantNotifications'
  mixins: [ExpandedStateMixin("sections.notifications.visible")]

  render: ->
    notifications = R.map (n) =>
      componentForNotification n, @props.order
    , @props.notifications

    cpURL = "#{CP_SVC}/restaurants/#{@props.restaurant.permalink}/locations#!/restaurant/notifications"
    header = React.createElement("span", {"key": "label"}, "Notifications")
    actions = [
      <a href={cpURL} key="cp-url" target="_blank" className="btn-order-header">
        <Icon name="cog" />
      </a>
    ]

    <ul className="list-group">
      <GroupHeader title="Notifications" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState}>
        {actions}
      </GroupHeader>
      <div className={@expandedToClassName()}>
        {notifications}
      </div>
    </ul>

NotificationsPanel = createReactClass
  displayName: 'NotificationsPanel'
  mixins: [BaconMixin]
  propTypes:
    name: PropTypes.string.isRequired
    heartbeat: PropTypes.string.isRequired
    iconName: PropTypes.string
    links: PropTypes.array.isRequired
    active: PropTypes.bool.isRequired
    notification: PropTypes.object.isRequired

  getInitialState: ->
    executing: false
    executingAction: null
    dropDown: false

  componentDidMount: ->
    @plug orderStore.executingNotificationAction, 'executing'

  toggleDropdown: ->
    @setState dropDown: not (@state.dropDown)

  executeAction: (action, event) ->
    console.log "Notifications", arguments
    orderStore.executeNotificationAction action.url, action.methods[0]

  notificationHeader: ->
    actions = R.filter resUtil.onlyInteractive, R.filter resUtil.notSelf, @props.links
    actionsToButtons = R.map (action) ->
      <DropdownItem key={action.name} key={action}>{action.name}</DropdownItem>

    icon = null
    iconStyle = cx 'text-success': @props.active, 'text-danger': !@props.active
    if @props.iconName
      icon = React.createElement(Icon, {"name": (@props.iconName), "size": "2x", "className": (iconStyle)})

    hbc = heartbeatClass @props.heartbeat, @props.notification.active

    # TODO: Execute action!
    <Row>
      <Col key="name" xs={6}>{icon} <span className={hbc}>{@props.name}</span></Col>
      <Col key="actions" xs={6} className="text-right">
        <ButtonDropdown id="hearbeat-notifications" toggle={@toggleDropdown} >
          <DropdownToggle onClick={@executeAction}>
            {timeOrNever(@props.heartbeat, @props.notification.active)}
          </DropdownToggle>
          <DropdownMenu>
            {actionsToButtons(actions)}
          </DropdownMenu>
        </ButtonDropdown>
      </Col>
    </Row>

  render: ->
    <li key={@props.notification.id} className="list-group-item">
      <div key="header">
        {@notificationHeader()}
      </div>
      <div key="children">
        {@props.children}
      </div>
    </li>

DefaultNotification = createReactClass
  displayName: "DefaultNotification"

  render: ->
    n = @props.notification
    onlyData = R.omit ['links', 'hearbeat', 'active']
    <NotificationsPanel notification={n} name={n.name} iconName="question-circle" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      {JSON.stringify(onlyData(n))}
    </NotificationsPanel>


PosNotification = createReactClass
  displayName: "PosNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={n.name} iconName="desktop" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
    </NotificationsPanel>

PhoneNotification = createReactClass
  displayName: "PhoneNotification"

  phoneNumber: ->
    orderType = @props.order.service.id.toLowerCase() + "_phone"
    if @props.notification.settings[orderType] and @props.notification.settings[orderType].trim().length > 0
      @props.notification.settings[orderType]
    else
      @props.notification.settings.phone

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Phone"} iconName="phone" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      {@props.order.service.label} by {@renderTypes()} to #{@phoneNumber()}
    </NotificationsPanel>

  renderTypes: ->
    R.join(" and ",
      R.map(R.nth(0),
        R.filter(R.pipe(R.nth(1), R.equals("true")),
        R.toPairs(R.pick(['sms', 'voice'], @props.notification.settings)))))

EmailNotification = createReactClass
  displayName: "EmailNotification"

  emailAddress: -> # TODO: Check overrides for order.type
    orderType = @props.order.service.id.toLowerCase()
    if @props.notification.settings[orderType] and @props.notification.settings[orderType].trim().length > 0
      @props.notification.settings[orderType]
    else
      @props.notification.settings.default_email

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"E-Mail"} iconName="envelope-o" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      {@props.order.service.label} address: {@emailAddress()}
    </NotificationsPanel>

IvrNotification = createReactClass
  displayName: "IvrNotification"

  address: -> # TODO: Check overrides for order.type
    orderType = "#{@props.order.service.id.toLowerCase()}_phone"
    if @props.notification.settings[orderType] and @props.notification.settings[orderType].trim().length > 0
      @props.notification.settings[orderType]
    else
      @props.notification.settings.phone

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"IVR"} iconName="phone" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      {@props.order.service.label} phone: {@address()}
    </NotificationsPanel>

CloudPrintNotification = createReactClass
  displayName: "CloudPrintNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Google Cloud Printer"} iconName="print" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
    </NotificationsPanel>


GoodcomNotification = createReactClass
  displayName: "GoodcomNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Goodcom"} iconName="sellsy" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
    </NotificationsPanel>


IBacsTelNotification = createReactClass
  displayName: "IBacsTelNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"IBacsTel"} iconName="sellsy" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      PrinterID: {n.settings.default_printer_id}
    </NotificationsPanel>

PosNotification = createReactClass
  displayName: "PosNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"POS"} iconName="desktop" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      Name: {n.settings.name}
    </NotificationsPanel>

RdsNotification = createReactClass
  displayName: "RdsNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"RDS"} iconName="desktop" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      Name: {n.settings.name}
    </NotificationsPanel>

MobikonNotification = createReactClass
  displayName: "RdsNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Mobikon"} iconName="rss" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      Outlet ID: {n.settings.outlet_id}<br/>
    </NotificationsPanel>

FaxNotification = createReactClass
  displayName: "FaxNotification"

  emailAddress: ->
    orderType = @props.order.service.id.toLowerCase()
    if @props.notification.settings[orderType] and @props.notification.settings[orderType].trim().length > 0
      @props.notification.settings[orderType]
    else
      @props.notification.settings.default_fax

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Fax"} iconName="fax" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      {@props.order.service.label} fax number: {@emailAddress()}
    </NotificationsPanel>


AndroidNotification = createReactClass
  displayName: "AndroidNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"OrderZupp"} iconName="android" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      Device/Version: {n.settings.product} {n.settings.model} / {n.settings.app_version} (id: {n.settings.device_id})
    </NotificationsPanel>

HomerNotification = createReactClass
  displayName: "HomerNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Homer"} iconName="rss" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
      Location ID: {n.settings.location_id}<br/>
    </NotificationsPanel>

SharpspringNotification = createReactClass
  displayName: "SharpspringNotification"

  render: ->
    n = @props.notification
    <NotificationsPanel notification={n} name={"Sharpspring"} iconName="sellsy" key={n.id} heartbeat={n.heartbeat} links={n.links} active={n.active}>
    </NotificationsPanel>

module.exports = RestaurantNotifications
