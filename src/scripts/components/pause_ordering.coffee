React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment-timezone'
createReactClass = require 'create-react-class'

{ Icon } = require 'react-fa'

userStore = require 'stores/user'
NavigationMixin = require 'components/lib/navigation'

restaurantSettings = require 'stores/restaurant-settings'

tzdetect = require 'utils/tzdetect'
import {Card, ButtonDropdown, DropdownToggle, DropdownMenu, DropdownItem, Button} from 'reactstrap'

RestaurantPauser = createReactClass
  displayName: 'RestaurantPauser'

  mixins: [NavigationMixin, ReactBacon.BaconMixin]

  getInitialState: ->
    settings: R.clone userStore.settings()
    timezone: userStore.timezone()
    restaurants: null
    loadingSettings: false

  componentDidMount: ->
    @plug restaurantSettings.loadSettings(), 'restaurants'
    @plug restaurantSettings.loading, 'loadingSettings'

  render: ->
    if @state.restaurants
      @renderPauseRestaurants @state.restaurants
    else
      <div>Loading restaurant additional info...</div>

  renderPauseRestaurants: (restaurants) ->
    <div>
      <h5>Pause/Resume</h5>
      <div>{ R.map @renderPauseResumeRestaurant, restaurants }</div>
    </div>

  renderPauseResumeRestaurant: (restaurant) ->
    <Card>
      <CardHeader>@renderHeader(restaurant)}
      </CardHeader>
        <CardBlock>
          { if restaurant.pause_online_ordering then @renderResumeButton(restaurant) else @renderPauseButton(restaurant) }
        </CardBlock>
    </Card>

  renderHeader: (restaurant) ->
    label = if restaurant.pause_online_ordering then "Paused" else "Taking orders"
    iconName = if restaurant.pause_online_ordering then "pause-circle-o" else "play-circle-o"
    <span><Icon name={iconName} /> { restaurant.name }: { label }</span>

  renderResumeButton: (restaurant) ->
    <Button size="xsmall" color="success" disabled={@state.loadingSettings} onClick={R.partial @onResumeOrdering, [restaurant]}>Resume Online Ordering</Button>

  renderPauseButton: (restaurant) ->
    <ButtonDropdown disabled={@state.loadingSettings} toggle={R.partial @onPauseOrdering, [restaurant]}>
      <DropdownToggle caret size="xsmall" color = "danger">
        Pause ordering...
      </DropdownToggle>
      <DropdownMenu>
        <DropdownItem key="2_hours">for 2 hours</DropdownItem>
        <DropdownItem key="12_hours">for 12 hours</DropdownItem>
        <DropdownItem divider />
        <DropdownItem key="tomorrow_morning">until tomorrow morning</DropdownItem>
        <DropdownItem key="next_week">until next week</DropdownItem>
        <DropdownItem divider />
        <DropdownItem key="forever">until manually resumed</DropdownItem>
      </DropdownMenu>
    </ButtonDropdown>

  onResumeOrdering: (restaurant, event) ->
    return if @state.loadingSettings
    restaurantSettings
      .resumeOrdering(restaurant)
      .firstToPromise()
      .then @onSuccess, @onFailure

  onPauseOrdering: (restaurant, key, event) ->
    return if @state.loadingSettings
    duration = switch key
      when '2_hours' then 2
      when '6_hours' then 6
      when '12_hours' then 12
      when 'tomorrow_morning' then @moment(restaurant).add('days', 1).hours(6).minutes(0).diff(@moment(restaurant)) / (3600 * 1000)
      when 'next_week' then @moment(restaurant).add('weeks', 1).startOf('week').hour(6).minute(0).diff(@moment(restaurant)) / (3600 * 1000)
      when 'forever' then -1

    restaurantSettings
      .pauseOrdering(restaurant, duration)
      .firstToPromise()
      .then @onSuccess, @onFailure

  onSuccess: (data) -> console.log("success", data)
  onFailure: -> console.warn("failure")

  moment: (restaurant) ->
    moment().zone restaurant.time_zone.utc_offset

module.exports = RestaurantPauser
