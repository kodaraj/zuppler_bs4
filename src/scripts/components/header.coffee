React = require 'react'
ReactDOM = require 'react-dom'
ReactBacon = require 'react-bacon'
{ Icon } = require 'react-fa'
List = require 'models/list'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

UserSettingsModal = require 'components/settings'
SoundService = require 'components/sound'

QuickSearch = require 'views/orders/quick_search'
Sidebar = require 'views/sidebar'

userStore = require 'stores/user'
listStore = require 'stores/lists'
uiStore = require 'stores/ui'

{ withRouter, Redirect } = require 'react-router-dom'
{ Button, NavbarBrand, Navbar, Nav, Collapse, Dropdown, UncontrolledDropdown,
         DropdownToggle, DropdownMenu, DropdownItem, NavItem , NavbarToggler } = require 'reactstrap'

logoutURL = ->
  accountsLogout = "https://accounts.zuppler.com/accounts/sign_out?return_url=" +
    encodeURIComponent(window.location.href)
  "https://users.zuppler.com/signout?redirect_to=" + encodeURIComponent(accountsLogout)

PageHeader = createReactClass
  displayName: 'PageHeader'
  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    loggedIn: false
    isOpen: false

  componentDidMount: ->
    @plug userStore.loggedIn, 'loggedIn'

  onHandleSettings: ->
    @props.history.push "/settings"

  onHandleProfile: ->
    window.open "https://users.zuppler.com"

  onHandleLogout: ->
    userStore.logout()
    window.location.href = logoutURL()

  onToggleSidebar: ->
    uiStore.toggleSidebar()

  toggle: ->
    @setState isOpen: not (@state.isOpen)

  render: ->
    <Navbar expand = "lg">
      <NavbarBrand className="mr-auto">
        <Button onClick={@onToggleSidebar} className="hidden-xs sidebar-toggle"><Icon name="bars" /></Button>
        <span>Zuppler - Customer Service <sup>&beta;</sup></span>
      </NavbarBrand>
      <NavbarToggler onClick={@toggle} />
      <Collapse isOpen={@state.isOpen} navbar>
        <QuickSearch />
        { @renderUserMenu() }
      </Collapse>
    </Navbar>

  renderUserMenu: ->
    if @state.loggedIn
      <Nav className="hidden-sm hidden-xs" key={0} navbar>
        <UncontrolledDropdown nav inNavbar key={1}>
          <DropdownToggle nav caret id="user-location">
            {userStore.name() || 'Zuppler'}
          </DropdownToggle>
          <DropdownMenu>
          <DropdownItem key="settings" onClick={@onHandleSettings}>Settings</DropdownItem>
          <DropdownItem divider />
          <DropdownItem key="profile" onClick={@onHandleProfile}>My Profile</DropdownItem>
          <DropdownItem key="logout" onClick={@onHandleLogout}>Logout</DropdownItem>
          </DropdownMenu>
        </UncontrolledDropdown>
      </Nav>

module.exports = withRouter(PageHeader)
