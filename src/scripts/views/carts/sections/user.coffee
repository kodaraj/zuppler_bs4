R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

{ findResourceLink } = require 'zuppler-js/lib/utils/resources'

validate = require "validate.js"
RS = require 'reactstrap'
import {Grid, Col, Row, Form, FormGroup, Label, Input, FormFeedback, TabPane, TabContent, CardBody, CardHeader, Nav, NavItem, NavLink, Button} from 'reactstrap'

userStore = require 'zuppler-js/lib/stores/user'
portalStore = require 'zuppler-js/lib/stores/portal'
uiStore = require 'stores/ui'

cartsStore = require 'stores/carts'

Autocomplete = require 'ron-react-autocomplete'

usersLookup = require 'stores/users-lookup'

Card = createReactClass
  displayName: 'UserCard'

  mixins: [ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin')]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    user: null
    userUrl: null

  componentDidMount: ->
    @plug @props.cart.user, 'userUrl'
    @plug userStore.user, 'user'

    channelUrl =  @props.cart.channel
      .filter R.compose R.not, R.isNil
      .skipDuplicates()
      .map findResourceLink "self", "get"
      .filter R.compose R.not, R.isNil

    @observeStream channelUrl, @setIntegrationChannel

  setIntegrationChannel: (channelUrl) ->
    portalStore.initChannelFromURL channelUrl

  render: ->
    return null if !@state.user
    className = cx "panel-success": !!@state.user.profile.name, 'panel-danger': !@state.user.profile.name
    onClick = R.partial @props.onChangeSection, ['user']
    <RS.Card key={@props.cart.id} onClick={onClick} className={className}>
      <CardHeader>{@renderHeader()}</CardHeader>
      <CardBody>
        <div key="name">
          <strong>{ R.defaultTo("Unknown User", @state.user.profile.name) }</strong>
        </div>
        <div key="details">
          <small>{ @state.user.profile.email } <br/> { @state.user.profile.phone }</small>
        </div>
      </CardBody>
    </RS.Card>

  renderHeader: ->
    if @state.user.logged_in
      <div>User</div>
    else
      <div>Customer</div>

Editor = createReactClass
  displayName: 'UserEditor'

  mixins: [ ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin') ]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    su: null
    errors: null
    assignUser: false

  componentDidMount: ->
    @plug userStore.user, 'su'
    @plug cartsStore.loggedInLoading, 'loading'
    @plug usersLookup.loading, 'loading'
    @observeStream cartsStore.loggedInUser, @onAssignSuccess, @onAssignFailure

  validationSchema: ->
    name:
      presence: true
      length:
        minimum: 3
    email:
      presence: true
      email: true
    phone:
      presence: true
      length:
        minimum: 10

  getUserValidationState: (field) ->
    profile = @state.su.profile
    errors = validate profile, @validationSchema()
    if errors and errors[field] and errors[field].length > 0 then 'error' else 'success'

  handleChange: (path, e) ->
    @setState su: R.assocPath path, e.target.value, @state.su

  onSaveUser: ->
    profile = @state.su.profile
    errors = validate profile, @validationSchema()
    @setState errors: errors
    if !errors
      @props.cart.name = profile.name
      userStore.updateProfile profile
      uiStore.saveTabs()
      @props.onClose('prereq')

  assignUser: (user) ->
    cartsStore.loginOnBehalf(@state.su, user)

  onAssignSuccess: ->
    userStore.reload()

  onAssignFailure: ->
    alert("Failed to login user on your behalf")

  render: ->
    return <div>"Loading..."</div> if !@state.su
    <Nav tabs>
      <NavItem>
        <NavLink>Existing User</NavLink>
      </NavItem>
      <NavItem>
        <NavLink>Guest</NavLink>
      </NavItem>
    </Nav>
    <TabContent activeTab = "1">
      <TabPane tabId = "1">
        { @renderUserForm() }
      </TabPane>
      <TabPane tabId = "2" disabled={@state.su.logged_in}>
        { @renderGuestForm() }
      </TabPane>
    </TabContent>

  renderUserForm: ->
    <Form horizontal>
      <FormGroup controlId="search">
        <Label>Search User: {<Icon name="spinner" spin={true} /> if @state.loading}</Label>
        <UserLookup onChange={@assignUser}/>
        <HelpBlock>Find an existing user by name, email or phone</HelpBlock>
      </FormGroup>

      <FormGroup controlId="shoppingUserName" validationState={@getUserValidationState('name')} >
        <Label>Name:</Label>
        <Input type="text" readOnly value={this.state.su.profile.name || ''} placeholder="enter customer name...."
          onChange={R.partial @handleChange, [['profile', 'name']]} />
        <FormFeedback />
      </FormGroup>

      <FormGroup controlId="shoppingUserEmail" validationState={@getUserValidationState('email')} >
        <Label>Email:</Label>
        <Input type="email" value={this.state.su.profile.email || ''} placeholder="enter customer email...."
          onChange={R.partial @handleChange, [['profile', 'email']]} />
        <FormFeedback />
      </FormGroup>

      <FormGroup controlId="shoppingUserPhone" validationState={@getUserValidationState('phone')} >
        <Label>Phone:</Label>
        <Input type="phone" value={this.state.su.profile.phone || ''} placeholder="enter customer phone#...."
          onChange={R.partial @handleChange, [['profile', 'phone']]} />
        <FormFeedback />
      </FormGroup>

      { @renderValidationErrors(@state.errors) }

      <Button onClick={@props.onClose}>Close</Button>{ ' ' }
      <Button onClick={@onSaveUser} color="primary">Continue</Button>
    </Form>

  renderGuestForm: ->
    <Form horizontal>
      <FormGroup controlId="shoppingUserName" validationState={@getUserValidationState('name')} >
        <Label>Name:</Label>
        <Input type="text" value={this.state.su.profile.name || ''} placeholder="enter customer name...."
          onChange={R.partial @handleChange, [['profile', 'name']]} />
        <FormFeedback />
      </FormGroup>

      <FormGroup controlId="shoppingUserEmail" validationState={@getUserValidationState('email')} >
        <Label>Email:</Label>
        <Input type="email" value={this.state.su.profile.email || ''} placeholder="enter customer email...."
          onChange={R.partial @handleChange, [['profile', 'email']]} />
        <FormFeedback />
      </FormGroup>

      <FormGroup controlId="shoppingUserPhone" validationState={@getUserValidationState('phone')} >
        <Label>Phone:</Label>
        <Input type="phone" value={this.state.su.profile.phone || ''} placeholder="enter customer phone#...."
          onChange={R.partial @handleChange, [['profile', 'phone']]} />
        <FormFeedback />
      </FormGroup>

      { @renderValidationErrors(@state.errors) }

      <Button onClick={@props.onClose}>Close</Button>{ ' ' }
      <Button onClick={@onSaveUser} color="primary">Save &amp; Continue</Button>
    </Form>

  renderValidationErrors: (errors) ->
    return null if !errors
    renderValidationFieldErrors = (error) ->
      <li>{ error }</li>
    <ul className="danger">
      { R.map renderValidationFieldErrors, R.flatten R.values errors }
    </ul>

Autosuggest = require 'react-autosuggest'
UserLookup = createReactClass
  displayName: 'UserLookup'
  mixins: [ReactBacon.BaconMixin]

  props:
    onChange: PropTypes.func.isRequired

  getInitialState: ->
    users: []
    value: ''

  onChange: (event, { suggestion, suggestionValue, sectionIndex, method }) ->
    @props.onChange suggestion

  search: ({value}) ->
    @setState value: value
    @searchUpdater or= usersLookup.results.onValue (results) =>
      if results
        @setState users: results

    if value.length > 2
      usersLookup.search value

  componentWillUnmount: ->
    @searchUpdater?()

  renderUser: (u) ->
    <div>
      <img src={"http://www.gravatar.com/avatar/#{u.gravatar_id}?s=32" }className="pull-left" />
      <div key="name"><strong>{u.name}</strong></div>
      <div key="address" className="text-muted">{u.email}/{u.phone}</div>
    </div>

  render: ->
    name = if @props.value then @props.value.name else null

    inputProps =
      placeholder: "Enter user name, email or phone...."
      value: @state.value
      onChange: (event, {newValue}) => @setState value: newValue

    <div>
      <Autosuggest suggestions={@state.users} onSuggestionsUpdateRequested={@search}
        getSuggestionValue={R.prop('name')} renderSuggestion={@renderUser}
        onSuggestionSelected={@onChange}
        inputProps={inputProps}/>
    </div>

module.exports =
  name: 'user'
  Card: Card
  Editor: Editor
