React = require 'react'
{ withRouter } = require 'react-router-dom'
ReactBacon = require 'react-bacon'
R = require 'ramda'
{Icon }= require 'react-fa'
cx = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

resUtil = require 'utils/resources'
OrderUtils = require './components/utils'
AssignDriverPopup = require './drivers/assign_driver_popup'
CancelDelivery = require './drivers/cancel_delivery'

optimisticStore = require 'models/list-optimistic'

{ UserIs, UserIsNot, orderActionLabel } = OrderUtils
{ orderActionLabel } = OrderUtils

{ Button, Modal, ModalFooter, ModalHeader, ModalBody, ModalTitle, Form, Label, Input, ButtonGroup, ButtonToolbar, ButtonDropdown, DropdownItem, DropdownMenu, DropdownToggle } = require 'reactstrap'
userStore = require 'stores/user'

ConfirmModalForm = createReactClass
  displayName: 'ConfirmModalForm'
  propTypes:
    order: PropTypes.object.isRequired
    onSubmit: PropTypes.func.isRequired
    onCancel: PropTypes.func.isRequired

  getInitialState: ->
    customDelay: null

  setDelay: (delay) ->
    @props.onSubmit duration: delay

  onSetCustomDelay: ->
    delay = parseInt @state.customDelay
    if !isNaN(delay) and delay >= 0 and delay <= 120
      @props.onSubmit duration: delay

  onUpdateCustomDelay: ->
    @setState customDelay: @refs.customDelay.getValue()

  onClose: ->
    @props.onCancel()

  render: ->
    bsStyleForCustomDelay = (delay) ->
      if R.isEmpty(delay) or !delay
        'secondary'
      else if isNaN parseInt delay
        'error'
      else if parseInt(delay) < 0 or parseInt(delay) > 90
        'error'
      else
        'success'

    buttons = R.map (delay) =>
      <Button key={delay} color="success" onClick={R.partial @setDelay, [delay]}>{delay}</Button>
    , [15, 20, 25, 30, 45, 60, 75, 90]

    <Modal isOpen onClosed={@onClose}>
      <ModalHeader>
        [{@props.order.restaurant.name}] Confirm Order for {@props.order.customer.name}
      </ModalHeader>
      <ModalBody>
        <Form inline>
          <FormControls.Static className="col-xs-10 col-xs-offset-2" value="ASAP orders need to have duration information. Please pick a predefined duration or enter one below." />
          <Label className ='col-xs-2'>Pick duration</Label>
          <Input help='Click a button to pick the order duration and confirm'
            wrapperClassName='wrapper' wrapperClassName='col-xs-10' >
            <ButtonGroup>{buttons}</ButtonGroup>
          </Input>
          <Label>
            Custom duration
          </Label>
          <Input type="text" ref="customDelay" value={@state.customDelay}
            onChange={@onUpdateCustomDelay} help="Enter duration value in minutes (max 90)"
            placeholder="enter minutes" color={bsStyleForCustomDelay(@state.customDelay)}
            labelClassName='col-xs-2' wrapperClassName='col-xs-10' />
        </Form>
      </ModalBody>
      <ModalFooter>
        <Button color={bsStyleForCustomDelay(@state.customDelay)} className={cx('hidden': bsStyleForCustomDelay(@state.customDelay) != "success")} onClick={@onSetCustomDelay}>Save Duration & Confirm</Button>
        <Button color="danger" onClick={@onClose}>Close</Button>
      </ModalFooter>
    </Modal>


iconForAction = (action) ->
  switch action.name
    when 'confirm' then React.createElement(Icon, {"name": "check"})
    when 'cancel' then React.createElement(Icon, {"name": "trash-o"})
    when 'miss' then React.createElement(Icon, {"name": "refresh"})

labelForAction = (action) ->
  switch action.name
    when 'confirm' then 'Confirm'
    when 'cancel' then 'Cancel'
    when 'touch' then 'Touch'
    when 'execute' then 'Execute'
    else action.name

buttonStyleForAction = (action) ->
  switch action.name
    when 'confirm' then 'primary'
    when 'cancel' then 'danger'
    else 'secondary'

defaultOrderActions =
  restaurantPhone: "Restaurant notified by phone"
  restaurantEmail: "Restaurant notified by email"
  restaurantNA: "Restaurant not answering"
  refundTicketCreated: "Refund ticket created"
  userNotified: "User notified"
  userNA: "User not answering"
  custom: "[Enter Custom Message]"

messageFromEvent = (eventId) ->
  defaultOrderActions[eventId]

disableCancel = R.curry (hasRestrictedRole, action) ->
  !(hasRestrictedRole and action.name == 'cancel')

OrderToolbar = createReactClass
  displayName: 'OrderToolbar'

  mixins: [ReactBacon.BaconMixin]

  propTypes:
    model: PropTypes.object.isRequired
    rdsOrder: PropTypes.object
    order: PropTypes.object.isRequired
    actions: PropTypes.array.isRequired
    notifications: PropTypes.array.isRequired

  componentDidMount: ->
    @plug @props.model.reloadingOrder, 'reloading'
    @plug @props.model.executingCreateManualEvent, 'executingCreateManualEvent'
    @plug @props.model.executingNotificationAction, 'executingNotificationAction'

  getInitialState: ->
    currentActionForm: null
    reloading: false
    executingCreateManualEvent: false
    executingNotificationAction: false
    notifyDropdown: false
    printDropdown: false
    orderDropdown: false


  onOrderAction: (action) ->
    switch action.name
      when 'confirm'
        if @props.order.time.id == 'ASAP'
          submit = (params) =>
            @props.model.executeAction action, params
            optimisticStore.updateOrderState @props.order, 'confirmed'
            @setState currentActionForm: null
            @props.history.goBack() if userStore.settingFor 'go-back-after-confirm'
          cancel = =>
            @setState currentActionForm: null
          @setState currentActionForm: React.createElement(ConfirmModalForm, {"onSubmit": (submit), "onCancel": (cancel), "order": (@props.order)})
        else
          @props.model.executeAction action
          optimisticStore.updateOrderState @props.order, 'confirmed'
          @props.history.goBack() if userStore.settingFor 'go-back-after-confirm'
      when 'cancel'
        if confirm "Are you sure you want to cancel this order?"
          @props.model.executeAction action
          optimisticStore.updateOrderState @props.order, 'canceled'
          @props.history.goBack() if userStore.settingFor 'go-back-after-confirm'
      else
        @props.model.executeAction action
        @props.history.goBack() if userStore.settingFor 'go-back-after-confirm'

  onReloadOrder: ->
    @props.model.reload()

  executeNotificationAction: (action, event) ->
    @props.model.executeNotificationAction resUtil.findResourceLink(action, 'send', 'put'), 'put'

  createManualEvent: (eventId, event) ->
    switch eventId
      when 'custom'
        message = prompt "Enter your message:"
      else
        message = messageFromEvent eventId
    eventsURI = resUtil.findResourceLink @props.order, "events", "get" # TODO: Switch to POST
    if eventsURI
      @props.model.createManualEvent eventsURI, message

  toggleNotifyDropdown: ->
    @setState notifyDropdown: not (@state.notifyDropdown)

  toggleAddOrderDropdown: ->
    @setState orderDropdown: not (@state.orderDropdown)

  togglePrintDropdown: ->
    @setState printDropdown: not (@state.printDropdown)

  render: ->
    order = @props.order

    <ButtonToolbar className="order-toolbar">
      { @_renderOrderActions(order) }
      <ButtonGroup>
        { @props.children }
      </ButtonGroup>
      { @_renderOrderAdditionalActions(order) }
    </ButtonToolbar>

  _renderOrderActions: (order) ->
    orderActive = cx 'main-actions', 'hidden': !order

    buttons = R.map (action) =>
      label = labelForAction action
      icon = iconForAction action
      bsStyle = buttonStyleForAction action
      if label
        <Button key={action.name} color={bsStyle} onClick={R.partial(@onOrderAction, [action])}>{icon} {label}</Button>
      else
        null
    , R.filter disableCancel(!userStore.hasAnyRole('config', 'restaurant_admin')), @props.actions

    <ButtonGroup className={orderActive}>
      {buttons}
      { @state.currentActionForm }
    </ButtonGroup>

  _renderOrderAdditionalActions: (order) ->
    rdsOrder = @props.rdsOrder
    orderURL = "#{ORDERS_SVC}/channels/#{order.channel.permalink}/restaurants/#{order.restaurant.permalink}/orders/#{order.id}/fax?direct_print=true"
    receiptURL = "#{ORDERS_SVC}/channels/#{order.channel.permalink}/restaurants/#{order.restaurant.permalink}/orders/#{order.id}/print.html?direct_print=true"

    reloadingIndicator = null
    if @state.reloading
      reloadingIndicator = <Icon name="spinner" spin={true} />

    actionLabel = R.partial orderActionLabel, [order]

    executingToBsStyle = (busy) ->
      if busy then 'warning' else 'secondary'

    orderActionsToMenuItem = R.mapObjIndexed (label, key, obj) ->
      <DropdownItem key={key} onClick={(e) => createManualEvent(e)}>{label}</DropdownItem>

    manualActions = R.partial orderActionsToMenuItem, [defaultOrderActions]

    actionsToButtons = R.map (action) ->
      <DropdownItem onClick = {(e) => @executeNotificationAction(action, e)} key={action.id}>{actionLabel(action)}</DropdownItem>

    <ButtonGroup>
      {@renderPrintButtons(orderURL, receiptURL)}
      {@renderDispatcherActions(rdsOrder)}
      <Button key="reload" onClick={@onReloadOrder}>{reloadingIndicator} Reload</Button>
      <UserIs role="restaurant" or="restaurant_staff">
        <Button key="order-action" color={executingToBsStyle(@state.executingNotificationAction)} onClick={() => R.partial @createManualEvent, ['custom', null]}><Icon name="node"/> Add Order Event</Button>
      </UserIs>
      <UserIs role="config" or="restaurant_admin">
        <ButtonDropdown isOpen = {@state.orderDropdown} id="add-order-event" key="order-action"
          color={executingToBsStyle(@state.executingCreateManualEvent)} className="pull-right" toggle = {@toggleAddOrderDropdown}>
          <DropdownToggle>Add Order Event</DropdownToggle>
          <DropdownMenu>
          {R.values manualActions()}
          </DropdownMenu>
        </ButtonDropdown>
        <ButtonDropdown isOpen = {@state.notifyDropdown} id="notify-again" key="notification-actions"
          color={executingToBsStyle(@state.executingNotificationAction)} className="pull-right" toggle={@toggleNotifyDropdown}>
          <DropdownToggle>Notify Again</DropdownToggle>
          <DropdownMenu>
          {actionsToButtons(@props.notifications)}
          </DropdownMenu>
        </ButtonDropdown>
      </UserIs>
    </ButtonGroup>

  renderPrintButtons: (orderURL, receiptURL) ->
    <ButtonDropdown isOpen = {@state.printDropdown} color="secondary" toggle = {@togglePrintDropdown}>
      <DropdownToggle>{@renderPrintButtonHeader()}</DropdownToggle>
      <DropdownMenu>
        <DropdownItem href={orderURL} target="_blank"><Icon name="file-pdf-o" /> Order</DropdownItem>
        <DropdownItem href={receiptURL} target="_blank"><Icon name="file-text-o" /> Receipt</DropdownItem>
      </DropdownMenu>
    </ButtonDropdown>

  renderPrintButtonHeader: ->
    <span><Icon name="print" /> Print...</span>

  renderDispatcherActions: (rdsOrder) ->
    if rdsOrder && rdsOrder.state not in ['delivered', 'error_state', 'auto_confirmed', 'canceled', 'delivery_canceled', 'error']
      <UserIs role="dispatcher">
        <span>
          <AssignDriverPopup order={@props.order} rdsOrder={@props.rdsOrder}/>
          <CancelDelivery order={@props.order} rdsOrder={@props.rdsOrder}/>
        </span>
      </UserIs>
    else
      null

module.exports = withRouter(OrderToolbar)
