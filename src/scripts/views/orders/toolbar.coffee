React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

import {Sparklines} from 'react-sparklines'
{ Icon }= require 'react-fa'

cx = require 'classnames'

resUtil = require 'utils/resources'

listStore = require 'stores/lists'
userStore = require 'stores/user'
uiStore = require 'stores/ui'

NavigationMixin = require 'components/lib/navigation'

{ Button, ButtonGroup, ButtonToolbar, DropdownItem, DropdownMenu, ButtonDropdown, DropdownToggle } = require 'reactstrap'

{ BaconMixin } = ReactBacon

Immutable = require 'immutable'

Toolbar = createReactClass
  displayName: 'ListToolbar'

  propTypes:
    list: PropTypes.object.isRequired
    history: PropTypes.object.isRequired

  mixins: [BaconMixin, NavigationMixin]

  getInitialState: ->
    polling: false
    sortInfo:
      prop: "time"
      asc: false
    useSounds: false
    changes: Immutable.List []
    isOpen: false

  componentWillMount: ->
    if @props.list
      @plug @props.list.isPolling, 'polling'
      @plug @props.list.sortProp, 'sortInfo'
      @plug @props.list.useSounds, 'useSounds'
      @plug @props.list.changes, 'changes'

  humanize: (propName) ->
    propName

  onTogglePolling: ->
    @props.list.setPolling(!@state.polling)
    listStore.updateList @props.list.id, @props.list

  onToggleSound: ->
    @props.list.setUseSounds !@state.useSounds
    listStore.updateList @props.list.id, @props.list

  onToggleSortDir: ->
    @props.list.sortOn @state.sortInfo.prop, !@state.sortInfo.asc
    listStore.updateList @props.list.id, @props.list

  onChangeSort: (event) ->
    if event.target.innerText == "Placed"
      key = 'placed'
    else
      key = 'time'
    @props.list.sortOn key, @state.sortInfo.asc
    listStore.updateList @props.list.id, @props.list

  toggleDropdown: ->
    @setState isOpen: not (@state.isOpen)

  onRemoveList: ->
    if !@props.list.locked
      listStore.removeList @props.list.id
      uiStore.switchToFirst()
    else
      alert "This tab is locked! Please edit the tab settings to unlock it and then try again!"

  onEditList: ->
    @props.history.push "/lists/#{@props.list.id}/edit"

  onNewList: ->
    @props.history.push "/lists/new"

  onDownload: ->
    @props.history.push "/lists/#{@props.list.id}/takeout"

  renderListSorting: (list) ->
    return null if @props.list.locked
    sortInfo = @humanize(@state.sortInfo.prop)
    listActive = cx 'hidden': !list

    sortDirClass = if @state.sortInfo.asc then "sort-amount-asc" else "sort-amount-desc"
    [firstLetter, restField] = [sortInfo.charAt(0).toUpperCase(), sortInfo.slice(1)]
    sortByTitle =
    <span>
      <Icon name="sort" />
      <span className="hidden-xs"> Sort: </span>
      <span className="badge">{firstLetter}<span className="hidden-xs">{restField}</span></span>
    </span>

    <ButtonGroup key='sortBy' className={listActive}>
      <ButtonDropdown isOpen = {@state.isOpen} id="sort" key="sort" toggle={@toggleDropdown}>
        <DropdownToggle>{sortByTitle}</DropdownToggle>
        <DropdownMenu>
          <DropdownItem onClick = {@onChangeSort}>Order Time</DropdownItem>
          <DropdownItem onClick = {@onChangeSort}>Placed</DropdownItem>
        </DropdownMenu>
      </ButtonDropdown>
      <Button onClick={@onToggleSortDir} innerRef = "Sort Direction"><Icon name={sortDirClass} /></Button>
    </ButtonGroup>

  renderListRefresh: (list) ->
    return null if @props.list.locked
    listActive = cx 'hidden': !list

    pollingClass = if @state.polling then 'success' else 'secondary'
    soundClass = if @state.useSounds then 'success' else 'secondary'
    sparkline = cx 'btn', 'hidden': !@state.polling or userStore.settingFor 'hide-orders-sparkline'

    <ButtonGroup className="#{listActive} hidden-xs hidden-sm">
      <Button color={pollingClass} onClick={@onTogglePolling} innerRef= "Auto Refresh"><Icon name="refresh" /></Button>
      <Button color={soundClass} onClick={@onToggleSound} innerRef = "Sound notifications when changes"><Icon name="music" /></Button>
      <div className={sparkline} style={backgroundColor: "#5EAF6A", padding: "0px"} title="chart of # of orders per minute (up to 90 minutes back)">
        <Sparklines width={120} height={31} strokeColor="white" strokeWidth="2px" circleDiameter={3} data={@state.changes.reverse().toArray()} />
      </div>
    </ButtonGroup>

  renderListActions: (list) ->
    listActive = cx 'hidden': !list
    removeButtonClass = cx 'hidden': @props.list.locked
    <ButtonGroup className="#{listActive} hidden-xs hidden-sm">
      <Button onClick={@onEditList} color="success"><Icon name="edit" /> Edit</Button>
      <Button onClick={@onRemoveList} color="danger" className={removeButtonClass}> <Icon fixedWidth name="remove"/> Remove</Button>
    </ButtonGroup>

  renderListAdditionalActions: (list) ->
    listActive = cx 'hidden': !list

    <ButtonGroup className="#{listActive} hidden-xs hidden-sm">
      <Button onClick={@onDownload} color="info"><Icon name="briefcase"></Icon><span className="hidden-xs"> Download Data</span></Button>
    </ButtonGroup>

  render: ->
    list = @props.list
    if list
      <ButtonToolbar>
        {@renderListSorting(list)}
        {@renderListRefresh(list)}
        {@renderListActions(list)}
        {@renderListAdditionalActions(list)}
      </ButtonToolbar>
    else
      <h1>"List is not available"</h1>

{ withRouter } = require 'react-router-dom'
module.exports = withRouter(Toolbar)
