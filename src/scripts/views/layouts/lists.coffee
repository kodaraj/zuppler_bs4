React = require 'react'
ReactBacon = require 'react-bacon'
R          = require 'ramda'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ ButtonGroup, ButtonToolbar, Button, ListGroupItem, ListGroup, Label, Nav } = require 'reactstrap'
uiStore = require 'stores/ui'

filterTabs = (stream, type) ->
  stream
    .map R.filter R.propEq('type', type)

renderList = R.curry (title, list, itemRender, addUrl) ->
  <div>
    <p className="text-justify">
      <a href={addUrl} className="pull-right btn btn-danger btn-sm" role="button">
        <Icon name="search-plus" />
      </a>
      <h4>{ title }</h4>
    </p>
    <Nav color="pills" vertical>
      { R.map itemRender, list }
    </Nav>
  </div>

iconForTabType = (type) ->
  switch type
    when 'lists' then 'list'
    when 'rdsLists' then 'list-alt'
    when 'reviews' then 'comments'
    when 'carts' then 'shopping-cart'

ModulesByType = createReactClass
  displayName: 'ModulesByType'

  mixins: [ ReactBacon.BaconMixin ]

  getInitialState: ->
    modules: []

  props:
    moduleType: PropTypes.string.isRequired
    canCreate: PropTypes.bool.isRequired

  componentDidMount: ->
    @plug filterTabs(uiStore.active, @props.moduleType), 'modules'

  render: ->
    <div>
      { @renderToolbar() }
      <ListGroup>
        { R.map @renderList, @state.modules }
      </ListGroup>
    </div>

  renderToolbar: ->
    <ButtonToolbar className="hidden-lg hidden-md">
      <ButtonGroup>
        { @renderCreateButton() }
      </ButtonGroup>
    </ButtonToolbar>

  renderCreateButton: ->
    if @props.canCreate
      createURL = "#/#{@props.moduleType}/new"
      <Button href={createURL} color="danger">
        <Icon name="search-plus" /> Create { @props.moduleType }
      </Button>

  renderList: (tab) ->
    <ListGroupItem key={tab.id} href="#/#{@props.moduleType}/#{tab.id}">
      <ListButton tab={tab} expanded={true} />
    </ListGroupItem>

SoundService = require 'components/sound'

ListButton = createReactClass
  displayName: 'TabButton'

  mixins: [ReactBacon.BaconMixin]

  propTypes:
    tab: PropTypes.object.isRequired
    expanded: PropTypes.bool.isRequired

  getInitialState: ->
    loading: false
    activity: false
    changes: null
    meta: null

  componentDidMount: ->
    @plug @props.tab.loading, 'loading' if @props.tab.loading if @props.tab.loading
    @plug @props.tab.activity, 'activity' if @props.tab.activity if @props.tab.activity
    @plug @props.tab.meta, 'meta' if @props.tab.meta if @props.tab.meta

  render: ->
    <span>
      <Icon name={iconForTabType(@props.tab.type)}/> {@props.tab.name} {@renderInfo()}
      <SoundService soundStream={@props.tab.noise} />
    </span>

  renderInfo: ->
    if @state.loading
      <Icon name="spinner" spin={true} fixedWidth={true} />
    else if @state.meta
      labelStyle = if @state.activity then "danger" else "default"
      <Label color={labelStyle}>
        {@state.meta.total}
      </Label>
    else if @state.activity
      labelStyle = if @state.activity then "danger" else "hidden"
      <Label color={labelStyle}>*</Label>
    else null

Lists = () ->
  <ModulesByType moduleType="lists" canCreate={true} />

Carts = () ->
  <ModulesByType moduleType="carts" canCreate={false} />

module.exports = { ListsIndex: Lists, CartsIndex: Carts }
