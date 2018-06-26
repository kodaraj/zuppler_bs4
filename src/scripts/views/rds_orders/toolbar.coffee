React = require 'react'
ReactBacon = require 'react-bacon'
{ withRouter } = require 'react-router-dom'
R = require 'ramda'
createReactClass = require 'create-react-class'
import { Sparklines } from 'react-sparklines'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
cx = require 'classnames'
resUtil = require 'utils/resources'
listStore = require 'stores/rds-lists'
userStore = require 'stores/user'
uiStore = require 'stores/ui'
NavigationMixin = require 'components/lib/navigation'
{ Button, ButtonGroup, ButtonDropdown, DropdownToggle, DropdownItem, DropdownMenu, ButtonToolbar } = require 'reactstrap'
{ BaconMixin } = ReactBacon

QuickSearch = require './quick_search'

Immutable = require 'immutable'

Toolbar = createReactClass
  displayName: 'ListToolbar'
  mixins: [BaconMixin, NavigationMixin]

  propTypes:
    list: PropTypes.object.isRequired

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

  onChangeSort: (key) ->
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

  onQuickSearch: ->
    value = window.prompt "What are you looking for?"
    if value and value.length > 0
      list = listStore.addListFromQuickSearch value
      @props.history.push "/rds/#{list.id}"

  onEditList: ->
    @props.history.push "/rds/#{@props.list.id}/edit"

  onNewList: ->
    @props.history.push "/rds/new"

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
          <DropdownItem onClick = {() => @onChangeSort('time')}>Order Time</DropdownItem>
          <DropdownItem onClick = {() => @onChangeSort('placed')}>Placed</DropdownItem>
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

  _renderCreateListsActions: ->
    <ButtonGroup className="hidden-md hidden-lg">
      <Button onClick={@onQuickSearch}><Icon name="search" /></Button>
      <Button onClick={@onNewList}><Icon name="search-plus" /><span className="hidden-xs hidden-sm"> Create List</span></Button>
    </ButtonGroup>

  _renderQuickSearch: ->
    <ButtonGroup className="pull-right hidden-xs hidden-sm">
      <QuickSearch>
        <Button color="primary" onClick={@onNewList}><Icon name="search-plus" /><span className="hidden-xs hidden-sm"> Create List</span></Button>
      </QuickSearch>
    </ButtonGroup>

  render: ->
    list = @props.list

    if list
      <ButtonToolbar>
        { @renderListSorting(list) }
        { @renderListRefresh(list) }
        { @renderListActions(list) }
        { @renderListAdditionalActions(list) }
      </ButtonToolbar>
    else
      null


module.exports = withRouter(Toolbar)
