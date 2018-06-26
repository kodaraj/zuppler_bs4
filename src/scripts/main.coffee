React = require 'react'
{ HashRouter , Route , Switch } = require 'react-router-dom'
{ render } = require 'react-dom'
R = require 'ramda'
Bacon = require 'baconjs'
$ = require 'jquery'
versionStore = require 'stores/version'
Application = require 'components/app'
Order = require 'models/order'
toastr = require "components/toastr-config"

import '../styles/main.scss'
versionStore.onValue (version) ->
  toastr.info "There is a new version available. Click to update!",
   "Customer Service",
   timeOut: 0, onclick: -> window.location.reload()

routes = ->
  <HashRouter>
    <Application />
  </HashRouter>

render(
  routes(),
  document.getElementById('react-container')
)
