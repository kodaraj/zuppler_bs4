React = require 'react'
import {withRouter} from 'react-router-dom'
userStore = require 'stores/user'
createReactClass = require 'create-react-class'
ReactBacon = require 'react-bacon'
{ BaconMixin } = ReactBacon
import {Route, Redirect} from 'react-router-dom'

PrivateRoute = createReactClass
  displayName: 'PrivateRoute'
  mixins: [BaconMixin]

  getInitialState: ->
    loggedIn: false

  componentWillReceiveProps: ->


  componentDidMount: ->
    @plug userStore.loggedIn, 'loggedIn'

  render: ->
    Comp = @props.component
    <Route path = {@props.path} render={(props) =>
      if @state.loggedIn
        <Comp {...@props} />
      else
        <Redirect to={{ pathname: "/hello", state: { nextPathname: props.location.pathname } }} />
      } />

module.exports = PrivateRoute
