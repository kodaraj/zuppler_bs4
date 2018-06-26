ReactBacon = require 'react-bacon'
React     = require 'react'
R         = require 'ramda'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
uiStore = require 'stores/ui'
{ Grid, Col, Row , Nav, NavItem, Label} = require 'reactstrap'
listStore = require 'stores/lists'
{ BaconMixin } = ReactBacon
SoundService = require 'components/sound'

TabSelector = createReactClass
  displayName: 'TabSelector'

  propTypes:
    tabs: PropTypes.array.isRequired
    current: PropTypes.object

  mixins: [BaconMixin]

  onChangeTab: (tabId) ->
    @props.onChangeTab R.find R.propEq('id', tabId), @props.tabs

  render: ->
    activeKey = R.path(['current', 'id'], @props)

    <Nav color='tabs' stacked={false} className="hidden-xs hidden-sm" key={activeKey}>
      <NavLink onClick = {@onChangeTab}>
        {R.map @renderTab(@props.current), @props.tabs}
      </NavLink>
    </Nav>

  renderTab: R.curry (current, tab) ->
    <NavItem key={tab.id}>
      <TabButton tab={tab} />
    </NavItem>

TabButton = createReactClass
  displayName: 'TabButton'

  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    loading: false
    activity: false
    changes: null
    meta: null

  componentDidMount: ->
    @plug @props.tab.loading, 'loading' if @props.tab.loading
    @plug @props.tab.activity, 'activity' if @props.tab.activity
    @plug @props.tab.meta, 'meta' if @props.tab.meta

  propTypes:
    tab: PropTypes.object.isRequired

  render: ->
    <span>
      {@props.tab.name} {@renderInfo()}
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

Tabular = createReactClass
  displayName: 'TabularLayout'
  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    tabs: []
    current: null

  componentDidMount: ->
    @plug uiStore.active, 'tabs'
    @plug uiStore.current, 'current'

  onChangeTab: (tab) ->
    uiStore.setCurrentTab tab

  render: ->
    <Grid fluid={true}>
      <Row>
        <Col sm={12}>
          <TabSelector tabs={@state.tabs} current={@state.current}
                       onChangeTab={@onChangeTab} />
        </Col>
      </Row>
      { @props.children }
    </Grid>

module.exports = Tabular
