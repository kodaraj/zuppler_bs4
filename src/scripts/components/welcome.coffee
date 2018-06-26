R = require 'ramda'
React = require 'react'
{ withRouter } = require 'react-router-dom'
userStore = require 'stores/user'
createReactClass = require 'create-react-class'

{ Button, Row, Col, Container, Alert, Jumbotron } = require 'reactstrap'

Welcome = createReactClass
  displayName: 'Welcome'

  getInitialState: ->
    loggedIn: null

  componentDidMount: ->
    userStore
      .loggedIn
      .firstToPromise()
      .then (loggedIn) =>
        @setState loggedIn: loggedIn

    userStore
      .loggedIn
      .filter (loggedIn) -> !!loggedIn
      .firstToPromise()
      .then @onSuccessLogin

  onLogin: ->
    userStore.login()

  onSuccessLogin: ->
    returnTo = R.path ['location', 'state', 'nextPathname']

    if returnTo(@props)
      @props.history.push(returnTo(@props))

    @setState loggedIn: true

  render: ->
    <Col xs ="12">
      <Jumbotron>
        <h1>Zuppler Customer Service App!</h1>
        { @renderContent() }
      </Jumbotron>
    </Col>

  renderContent: ->
    switch @state.loggedIn
      when null then @renderLoading()
      when false then @renderNeedLogin()
      when true then @renderWelcome()

  renderLoading: ->
    <p>Please wait while loading your information</p>

  renderNeedLogin: ->
    <div>
      <p>You need to login.</p>
      <Button color="primary" onClick={@onLogin}>Login</Button>
      <p className="text-info">In order for the login to work please disable popup blocker.</p>
    </div>

  renderWelcome: ->
    <p>Welcome to the Zuppler Customer Service! Please select a list from the sidebar in order to continue.</p>

module.exports = withRouter(Welcome)
