React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment-timezone'
{ UserIs } = require 'views/order/components/utils'
PropTypes = require 'prop-types'
userStore = require 'stores/user'
NavigationMixin = require 'components/lib/navigation'
createReactClass = require 'create-react-class'
{ Modal, Button, ModalHeader, ModalBody, ModalFooter, Nav, NavItem, TabContent, TabPane, NavLink, Form, FormGroup, Label, Input, FormText, CustomInput, Label } = require 'reactstrap'
tzdetect = require 'utils/tzdetect'
PauseOrdering = require './pause_ordering'
cx = require 'classnames'

translate = (key) ->
  translations =
    'items.min.quantity':         "Always show quantity in front of the item. If off it hides 1 x"
    'items.menu.name':            "Show menu name with the item name"
    'items.menu.category':        "Show category name with the item name"
    'items.alias':                "Use item aliases whenever they are available"
    'modifiers.min.quantity':     "Always show quantity in front of modifier options. If off it hides 1 x"
    'modifiers.group.name':       "Always show the modifier name of the modifier options"
    'hide-orders-sparkline':      "Hide # of orders chart for live lists in toolbar"
    'go-back-after-confirm':      "Return to orders list after confirming/canceling an order"
    'show-order-events':          "Show order events"
    'dont-pin-orders-from-links': "Do not pin orders from links"
    'order-print-html':           "Print orders on a normal printer (uncheck for receipts)"
  translations[key] || key

filterOrderKeys             = R.pick ['items.min.quantity', 'items.menu.name', 'items.menu.category', 'items.alias', 'modifiers.min.quantity', 'modifiers.group.name']
filterOptionsKeys           = R.pick ['hide-orders-sparkline', 'go-back-after-confirm', 'dont-pin-orders-from-links', 'order-print-html' ]
filterRestaurantOptionsKeys = R.pick ['order-print-html']
filterAmbassadorOptionsKeys = R.pick ['show-order-events']
filterConfigOptionsKeys     = R.pick ['show-order-events']
filterRestaurantAdminOptionsKeys = R.pick ['show-order-events']

UserSettingsModal = createReactClass
  displayName: 'UserSettingsModal'

  mixins: [NavigationMixin, ReactBacon.BaconMixin]

  getInitialState: ->
    settings: R.clone userStore.settings()
    timezone: userStore.timezone()
    activeTab: "1"

  onChecboxChange: (obj, key, event) ->
    @setState settings: R.merge @state.settings, R.assoc key, event.target.checked, {}

  onChangeTimeZone: (event) ->
    @setState timezone: event.target.value

  toggle: (tab)->
    @setState activeTab: tab

  onSave: ->
    userStore.saveSettings @state.settings
    userStore.saveTimezone @state.timezone
    @props.history.goBack()

  onReset: ->
    if confirm "Are you sure you want to reset all lists and options to defaults?"
      userStore.resetSettings()
      setTimeout ->
        alert "The app will now reload with default settings"
        window.location.href = "/"
      , 1000

  render: ->
    settingsToCheckboxes = R.mapObjIndexed (value, key, obj) =>
      onChecboxChange = @onChecboxChange.bind @, obj, key
      <CustomInput id={key} key = {key} type="checkbox" defaultChecked={value} onClick={onChecboxChange} label = { translate(key) }/>

    orderCheckboxes      = R.values settingsToCheckboxes filterOrderKeys @state.settings
    optionsCheckboxes    = R.values settingsToCheckboxes filterOptionsKeys @state.settings
    configCheckboxes     = R.values settingsToCheckboxes filterConfigOptionsKeys @state.settings
    ambassadorCheckboxes = R.values settingsToCheckboxes filterAmbassadorOptionsKeys @state.settings
    restaurantCheckboxes = R.values settingsToCheckboxes filterRestaurantOptionsKeys @state.settings
    restaurantAdminCheckboxes = R.values settingsToCheckboxes filterRestaurantAdminOptionsKeys @state.settings

    timezoneOption = (name) ->
      <option key={name} value={name}>{name}</option>

    countries = tzdetect.groups.map (tz) ->
      if tz.zones.length == 1
        <option key={tz.name} value={tz.zones[0]}>{ tz.name }</option>
      else
       <optgroup key={tz.name} label={tz.name}>
          { R.map timezoneOption, tz.zones }
        </optgroup>


    <Modal isOpen={true} onExit={@props.history.goBack}>
      <ModalHeader>
        Settings
      </ModalHeader>
      <ModalBody>
        <Nav tabs>
          <NavItem>
            <NavLink key="order" className={cx({ active: @state.activeTab == '1' })} onClick={() => @toggle('1')}>Order Display</NavLink>
          </NavItem>
          <NavItem>
            <NavLink key="options" className={cx({ active: @state.activeTab == '2' })} onClick={() => @toggle('2')}>Options</NavLink>
          </NavItem>
          <NavItem>
            <NavLink key="timezone" className={cx({ active: @state.activeTab == '3' })} onClick={() => @toggle('3')}>Timezone</NavLink>
          </NavItem>
        </Nav>
        <TabContent activeTab= {@state.activeTab}>
          <TabPane tabId = "1">{orderCheckboxes}</TabPane>
          <TabPane tabId = "2">
            {optionsCheckboxes}
            <UserIs role="restaurant">
              {restaurantCheckboxes}
            </UserIs>
            <UserIs role="config">{configCheckboxes}</UserIs>
            <UserIs role="ambassador">{ambassadorCheckboxes}</UserIs>
            <UserIs role="restaurant_admin">{restaurantAdminCheckboxes}</UserIs>
          </TabPane>
          <TabPane tabId = "3">
            <Form>
              <FormGroup>
                <Label>Timezone:</Label>
                <Input type="select" value={@state.timezone}
                  onChange={@onChangeTimeZone}>
                  { countries }
                </Input>
                <span>
                  Filters will use this timezone to calculate start and end of the day.
                  Current values guessed or saved is { @state.timezone }
                </span>
              </FormGroup>
            </Form>
          </TabPane>
          { @renderOrderingTab() }
        </TabContent>
      </ModalBody>
      <ModalFooter>
        <Button key="reset" color="warning" onClick={@onReset}>Reset content</Button>
        <Button key="close" onClick={@props.history.goBack}>Close</Button>
        <Button key="save" color="primary" onClick={@onSave}>Save</Button>
      </ModalFooter>
    </Modal>


  renderOrderingTab: ->
    if userStore.hasRole('restaurant') or userStore.hasRole('restaurant_admin')
      <Nav tabs>
        <NavItem>
          <NavLink key = "pause" className={cx({ active: @state.activeTab == '4' })} onClick={() => @toggle('4')}>Ordering</NavLink>
        </NavItem>
      </Nav>
      <TabContent activeTab = "4">
        <TabPane tabId = "4">
          <PauseOrdering />
        </TabPane>
      </TabContent>


{ withRouter } = require 'react-router-dom'
module.exports = withRouter(UserSettingsModal)
