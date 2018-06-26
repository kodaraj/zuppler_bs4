React = require 'react'
{Icon }= require 'react-fa'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

ReactBacon = require 'react-bacon'
List = require 'models/list'
Condition = require 'models/condition'
NavigationMixin = require 'components/lib/navigation'
uiStore = require 'stores/ui'
resUtil = require 'utils/resources'
cx = require 'classnames'

takeoutStore = require 'stores/takeout'
listStore = require 'stores/lists'

takeoutOptions = require 'stores/takeout_options'

sortable = require('react-sortable-mixin')
moment = require('moment')

toastr = require('components/toastr-config')

TakeoutList = require('./jobs')
Sections = require("./sections")

{ Grid, Col, Row, Nav, NavItem, ButtonToolbar, ButtonGroup,
  Button, ButtonDropdown, DropdownItem , Input, Label, TabPane, TabContent,
  NavLink, Form, FormGroup} = require 'reactstrap'

{ BaconMixin } = ReactBacon

Takeout = createReactClass
  displayName: 'Takeout'
  mixins: [BaconMixin]

  getInitialState: ->
    options: takeoutOptions.makeDefaultOptions()
    takeouts: []
    templates: []
    sortMode: false
    list: null
    name: 'New Data Takeout'
    template: false
    activeTab: 'takeout'

  onSectionFieldSelected: (sectionId, fieldId, event) ->
    @setState options: takeoutOptions.toggleSectionField(
      @state.options, sectionId, fieldId, event.target.checked)

  onSectionSelected: (sectionId, event) ->
    @setState options: takeoutOptions.toggleSection(@state.options, sectionId,
      event.target.checked)

  onStartDownload: ->
    @startDownload @state.name, @state.list, @state.options, @state.template
    @setState activeTab: 'jobs'
    takeoutStore.reload()

  startDownload: (name, list, options, template) ->
    takeoutStream = takeoutStore.create name, list,
      takeoutOptions.toRequestOptions(options), template

    @streams = []

    # TODO: Make takeout#show return success: true/errors/takeout than enable this.
    @streams.push takeoutStream.onValue ->
      toastr.info 'Order takeout processing started. You will receive an email
        from customer.support@zuppler.com.', "Download orders from #{list.name}"
    @streams.push takeoutStream.onError (err) ->
      toastr.error "Order takeout failed. #{err.status.code}:
        #{err.status.message}", "Download orders"

    # @onClose()

    toastr.info 'Order takeout processing started. You will receive an email
      from customer.support@zuppler.com.', "Download orders from #{list.name}"

  onToggleSortMode: ->
    @setState sortMode: !@state.sortMode

  onClose: ->
    @props.history.goBack()

  componentDidMount: ->
    listId = @props.match.params.listId
    listStore.lists.firstToPromise().then (lists) =>
      list = lists.find (list) -> list.id == listId
      @setState list: list, name: list.name if list
    @plug takeoutStore.all, "takeouts"
    @plug takeoutStore.templates, "templates"
    takeoutStore.reload()


  onUpdateCheckbox: (prop, event) ->
    @setState R.assoc prop, event.target.checked, {}

  onUpdateTexbox: (prop, event) ->
    @setState R.assoc prop, event.target.value

  onUseTemplateOptions: (template) ->
    @setState name: template.name, options: takeoutOptions.fromRequestOptions(template.options)
    @startDownload template.name, @state.list, takeoutOptions.fromRequestOptions(template.options), false

  componentWillUnmount: ->
    R.ap @streams

  onResorted: (sections) ->
    @setState options: sections

  onChangeTab: (event) ->
    @setState activeTab: event

  render: ->
    if @state.list
      @renderList()
    else
      @renderLoading()

  renderLoading: ->
    <div>Loading data</div>

  renderList: ->
    <div>
      <Row key="content">
        <Col xs={12}>
          <Nav tabs id="downloadData" key={@state.activeTab} color="tabs">
            <NavItem>
              <NavLink className = {cx { active: @state.activeTab == 'takeout' }} onClick={() => @onChangeTab('takeout') }>
                Data Selection
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink className = {cx { active: @state.activeTab == 'templates' }} onClick={() => @onChangeTab('templates') }>
                Templates
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink className = {cx { active: @state.activeTab == 'jobs' }} onClick={() => @onChangeTab('jobs') }>
                Requests
              </NavLink>
            </NavItem>
          </Nav>
          <TabContent activeTab = {@state.activeTab}>
            <TabPane tabId='takeout'>
              <p>This will create a file based on all orders you see on the on <strong>{@state.list.name}</strong> list.</p>
              <p className="text-primary">Please select what information should be included with the output file. Switch to sorting mode to order the columns in the output.</p>
              <Row style={marginBottom: '4px', borderBottom: '1px dashed #999', paddingBottom: '4px'}>
                <Col xs={8}>
                  <Form inline>
                    <FormGroup>
                      <Label>Download Name: </Label>
                      <Input type="text" value={@state.name} onChange={R.partial @onUpdateTexbox, ['name']} />
                      <FormGroup check>
                        <Label check>
                          <Input type="checkbox" defaultChecked={@state.template} onChange={R.partial @onUpdateCheckbox, ['template']} />{' '}Save as template
                        </Label>
                      </FormGroup>
                    </FormGroup>
                  </Form>
                </Col>
                <Col xs={4} className="pull-right">
                  <Button key="sort" onClick={@onToggleSortMode}>Toggle Sort Mode</Button>
                </Col>
              </Row>
              <Sections sections={@state.options}
                sortMode={@state.sortMode}
                onResorted={@onResorted}
                onSectionSelected={R.curry(@onSectionSelected)}
                onSectionFieldSelected={@onSectionFieldSelected} />
              <p className="text-info">Your data will be packed and you will get an email with the results. You can also check the Requests tab to download data.</p>
              <ButtonToolbar>
                <ButtonGroup>
                  <Button key="prepare" onClick={@onStartDownload} color="primary"><Icon name="hourglass-start"/> Start processing</Button>
                </ButtonGroup>
              </ButtonToolbar>
            </TabPane>
            <TabPane tabId='templates'>
              <TakeoutList takeouts={@state.templates} actions={TemplateActions} totals={false}
                onUpdateOptions={@onUseTemplateOptions}/>
            </TabPane>
            <TabPane tabId='jobs'>
              <TakeoutList takeouts={@state.takeouts} actions={TakeoutActions} totals={true} />
            </TabPane>
          </TabContent>
        </Col>
      </Row>
      <Row key="buttons">
        <Col xs={12}>
        </Col>
      </Row>
    </div>

Takeout.getDerivedStateFromProps= (props, state) ->
  uiStore.setCurrentUI("lists", "listId")

TakeoutActions = createReactClass
  displayName: 'TakeoutActions'
  propTypes:
    takeout: PropTypes.object.isRequired

  render: ->
    takeout = @props.takeout
    if takeout.ready && takeout.url
      <a href={takeout.url} target="_blank">
        <Icon name="cloud-download" /> Download
      </a>
    else
      <span><Icon spin name="spinner" /> Processing</span>

TemplateActions = createReactClass
  displayName: 'TakeoutActions'
  propTypes:
    takeout: PropTypes.object.isRequired
    onUpdateOptions: PropTypes.func.isRequired

  render: ->
    takeout = @props.takeout
    <div onClick={R.partial @props.onUpdateOptions, [takeout]}>
      <Icon name="cloud-download" /> Use Template
    </div>

{ withRouter } = require 'react-router-dom'
module.exports = withRouter(Takeout)
