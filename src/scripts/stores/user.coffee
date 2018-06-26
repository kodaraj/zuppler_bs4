Bacon = require 'baconjs'
React     = require 'react'
R = require 'ramda'
hello = require 'hellojs'
client = require 'api/auth'
Dispatcher = require 'utils/dispatcher'
userApi = require 'api/users'
authConfig = require 'api/auth'
uuid = require 'uuid'
tzdetect = require('utils/tzdetect')
{ wrapRequest } = require 'utils/request'
{ Redirect } = require 'react-router-dom'

# TODO: Push to toaster
toastr = require('components/toastr-config')

id = null
name = null
email = null
token = null
roles = []
acls = {}

# once logged in push true on this prop
loggedIn = new Bacon.Bus

savedLists = localStorage.getItem('lists')
if savedLists and JSON.parse(savedLists).length > 0
  lists = Bacon.once JSON.parse savedLists
else
  lists = Bacon.once []

hello.on 'auth.login', (auth) ->
  hello(auth.network).api('/me').then (r) ->
    id = r.info.id
    name = r.info.name
    email = r.info.email
    roles = r.info.roles
    acls = r.info.acls
    loggedIn.push true

hello.on 'auth.logout', (auth) ->
  name = email = null
  loggedIn.push false

showError = (er) ->
  alert "Failed to login into your account\n#{er.error.message}"

login_success = ->
  token = client.getAuthResponse().access_token

login_with_accounts = ->
  client.login().then login_success, showError

hasRole = (role) -> R.contains(role, roles)
hasAnyRole = (roles...) -> R.any hasRole, roles

online = (session) ->
  currentTime = (new Date()).getTime() / 1000
  session && session.access_token && session.expires > currentTime

#  possible to have a valid session already?
hasSession = online client.getAuthResponse()
if hasSession
  loggedInProp = loggedIn.toProperty()
else
  loggedInProp = loggedIn.toProperty(false)

# TODO: Implement user settings
d = new Dispatcher("user")
userPreferences = {}
timezone = null

getLocalStorageItem = (key) ->
  localStorage.getItem(key)

localUserPreferences = (key) ->
  Bacon.once(key).map(getLocalStorageItem)

loadUserPreferencesCall = (key) ->
  Bacon
    .fromPromise(wrapRequest(client.api("settings", 'get', { project: 'customer-service', key: key })))

remoteUserPreferences = (key) ->
  Bacon
    .retry
      source: -> loadUserPreferencesCall(key)
      retries: 5
      isRetryable: (error) -> error.status.code != 404
      delay: ({retriesDone}) -> retriesDone * 100
    .map(R.prop('settings'))

saveRemote = R.curry (key, value) ->
  Bacon.fromPromise wrapRequest client.api "settings", 'put',
    project: 'customer-service'
    key: key
    settings: JSON.stringify(value)

saveSettingsFor = (key) ->
  d
    .stream(key)
    .skipDuplicates(R.quals)
    .throttle(500)
    .flatMap(saveRemote(key))

loadSettings = R.curry (key, defaultValue) ->
  loggedInProp
    .filter (b) -> !!b
    .flatMap -> remoteUserPreferences(key)
    .flatMapError (error) ->
      # console.log "ERROR", error, arguments
      # toastr.error "There was an error trying while loading settings. Please contact support!<br/><br/>#{error.status.code} - #{error.status.message}", "Settings#Users", {timeOut: 0}
      new Bacon.Next(defaultValue)
    .map JSON.parse
    .toEventStream()

userSettings = Bacon.update { timezone: tzdetect.guess(), settings: {}, tabs: [] },
  [loadSettings('user_settings', '{}')], ({tabs, timezone}, settings) -> {tabs, timezone, settings}
  [loadSettings('tabs', '[]')], ({timezone, settings}, tabs) -> {tabs, timezone, settings}
  [loadSettings('timezone', 'null')], ({settings, tabs}, timezone) -> {tabs, timezone, settings}

userSettings
  .map(R.prop('settings'))
  .onValue (settings) ->
    userPreferences = settings || {}

userSettings
  .map R.prop('timezone')
  .onValue (tz) ->
    timezone = tz

# Saving app state
saveAppState = Bacon
  .once ['user_settings', 'tabs', 'timezone']
  .map R.map saveSettingsFor
  .flatMap Bacon.mergeAll

saveAppState
  .onValue (data) ->
    # toastr.error "There was an error trying to save settings. Please contact support!", "Settings"

saveAppState
  .onError (data) ->
    toastr.error "There was an error trying to save settings. Please contact support!", "Settings"

userSetting = (name) ->
  if userPreferences[name] != undefined
    userPreferences[name]
  else
    setUserSetting name, true

setUserSetting = (name, value) ->
  userPreferences[name] = value
  d.stream('user_settings').push userPreferences
  value

# END USER SETTINGS

module.exports =
  id: -> id
  name: -> name
  email: -> email
  roles: -> roles
  acls: -> acls
  login: login_with_accounts
  loggedIn: loggedInProp
  hasRole: hasRole
  hasAnyRole: hasAnyRole
  lists: lists

  settingFor: userSetting
  setSettingFor: setUserSetting
  settings: -> userPreferences
  saveSettings: (prefs) ->
    userPreferences = prefs
    d.stream('user_settings').push prefs
  resetSettings: ->
    d.stream('tabs').push []
    d.stream('user_settings').push {}

  timezone: -> timezone
  saveTimezone: (tz) ->
    timezone = tz
    d.stream('timezone').push tz

  tabs: userSettings
    .map(R.prop('tabs'))
    .map R.defaultTo([])
  saveTabs: (tabs) ->
    d.stream('tabs').push tabs

  logout: -> client.logout()
