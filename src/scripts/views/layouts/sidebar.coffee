ReactBacon = require 'react-bacon'
React     = require 'react'
R         = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
Sidebar = require 'views/sidebar'
userStore = require 'stores/user'
orderStore = require 'stores/order'
listStore = require 'stores/lists'
ordersStore = require 'stores/orders'
cartsStore = require 'stores/carts'
versionStore = require 'stores/version'

uiStore = require 'stores/ui'

{ Route, Switch } = require 'react-router-dom'
{ Col, Row, Button } = require 'reactstrap'

typeName = (type) ->
  switch type
    when 'lists' then "Lists"
    when 'rdsLists' then "RDS Lists"
    when 'carts' then "Pending Orders"

SidebarLayout = createReactClass
  mixins: [ ReactBacon.BaconMixin ]

  getInitialState: ->
    current: null
    sidebar: true
    tabs: []

  componentDidMount: ->
    @plug uiStore.current, 'current'
    @plug uiStore.sidebar, 'sidebar'
    @plug uiStore.active, 'tabs'

  onStart: ->
    uiStore.switchToFirst()

  render: ->
    if @state.sidebar
      @renderExpanded()
    else
      @renderCollapsed()

  renderExpanded: ->
    <div className="container-fluid layout-sidebar">
      <Row className="main-content">
        <Col lg={2} md={3} className="hidden-xs hidden-sm sidebar">
          <Sidebar expanded={true}/>
        </Col>
        <Col lg={10} md={9} xs={12} sm={12}>
          { @renderContent() }
        </Col>
      </Row>
    </div>

  renderCollapsed: ->
    <div className="container-fluid layout-full">
      <div className="hidden-xs hidden-sm sidebar">
        <Sidebar expanded={false} />
      </div>
      <Row className="main-content">
        { @renderContent() }
      </Row>
    </div>

  renderContent: ->
    <Col sm={12}>
      { @renderCurrentTabInfo() }
      { @props.children }
    </Col>

  renderCurrentTabInfo: ->
    if @state.current and typeName(@state.current.type)
      <ol className="breadcrumb" key={@state.current.type}>
        <li><a href="#/#{@state.current.type}">{ typeName(@state.current.type) }</a></li>
        <li className="active"><a href="#/#{@state.current.type}/#{@state.current.id}">{ @state.current.name }</a></li>
      </ol>

{ withRouter } = require 'react-router-dom'
module.exports = withRouter(SidebarLayout)
