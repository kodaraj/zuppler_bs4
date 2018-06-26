React = require 'react'
{ Icon }= require 'react-fa'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ Button, CardBody, CardFooter, CardHeader, CardGroup, Table, Card, Collapse, Container } = require 'reactstrap'
ReactBacon = require 'react-bacon'
List = require 'models/list'
Condition = require 'models/condition'
NavigationMixin = require 'components/lib/navigation'

resUtil = require 'utils/resources'
cx = require 'classnames'

takeoutStore = require 'stores/takeout'
listStore = require 'stores/lists'

takeoutOptions = require 'stores/takeout_options'

sortable = require('react-sortable-mixin')
moment = require('moment')

toastr = require('components/toastr-config')

{ BaconMixin } = ReactBacon

formatCents = (cents) -> (cents / 100.0).toFixed(2)
formatMoney = (money) -> parseFloat(money).toFixed(2)

TakeoutList = createReactClass
  displayName: 'TakeoutList'
  mixins: [ ReactBacon.BaconMixin ]
  propTypes:
    takeouts: PropTypes.array.isRequired
    onUpdateOptions: PropTypes.func
    totals: PropTypes.bool.isRequired

  getInitialState: ->
    loading: false
    collapseIndex: "0"

  componentDidMount: ->
    @plug takeoutStore.reloading, 'loading'

  onReloadTakeouts: ->
    toastr.info('Reloading data...')
    takeoutStore.reload()

  toggleCollapse: (event, index) ->
    if @state.collapseIndex == index
      @setState collapseIndex: "0"
    else
      @setState collapseIndex: index

  render: ->
    if @props.totals
      @renderWithTotals()
    else
      @renderAsTable()

  renderWithTotals: ->
    <div>
      <Container>
        { R.map @renderTakeoutPanel, @props.takeouts }
      </Container>
      { @renderReloadButton() }
    </div>

  renderTakeoutPanel: (takeout) ->
    if takeout
      defaultActiveKey = R.path(['id'])
    else
      defaultActiveKey = R.always "0"

    <Card style={{ marginBottom: '1rem' }} key={ JSON.stringify takeout.id}>
      <CardHeader onClick = {(e) => @toggleCollapse(e, defaultActiveKey(takeout))}>
          {@renderTakeoutPanelHeader(takeout)}
      </CardHeader>
      <Collapse isOpen = {@state.collapseIndex == defaultActiveKey(takeout)}>
        <CardBody>
          <Table striped bordered size="sm">
            <thead>
              <tr>
                <th key="1">Total Type</th>
                <th key="2">Orders</th>
                <th key="3">Total</th>
                <th key="4">Tax</th>
                <th key="5">Discount</th>
                <th key="6">Delivery</th>
                <th key="7">Service</th>
                <th key="8">Tip</th>
              </tr>
            </thead>
            <tbody>
              { R.map @renderTotalRow, R.toPairs takeout.totals }
            </tbody>
            { @renderErrors(takeout) }
          </Table>
          </CardBody>
          <CardFooter>
            {@renderActions(takeout)}
          </CardFooter>
      </Collapse>
    </Card>

  renderTotalRow: ([totalType, totals]) ->
    <tr key={totalType}>
      <td key="1"><strong>{totalType}</strong></td>
      <td key="2">{totals.count}</td>
      <td key="3">{formatMoney totals.total}</td>
      <td key="4">{formatMoney totals.tax}</td>
      <td key="5">{formatMoney totals.discount}</td>
      <td key="6">{formatMoney totals.delivery}</td>
      <td key="7">{formatMoney totals.service}</td>
      <td key="8">{formatMoney totals.tip}</td>
    </tr>

  renderErrors: (takeout) ->
    if takeout.ready and takeout.job_errors and takeout.job_errors.length
      <tfoot className='text-danger'>
        <tr>
          <td colSpan={8}>Problems:</td>
        </tr>
        { R.map @renderErrorRow, takeout.job_errors }
      </tfoot>

  renderErrorRow: (error) ->
    <tr key = {error}>
      <td colSpan={8}>{error}</td>
    </tr>

  renderTakeoutPanelHeader: (takeout) ->
    <span>{moment(takeout.created).format("lll")} - {takeout.name}</span>

  renderAsTable: ->
    reloadLabel = if @state.loading then <span><Icon name="spinner" spin/> Loading...</span> else "Reload"
    <div>
      <Table striped bordered size="sm">
        <thead>
          <tr>
            <th key="c">Created</th>
            <th key="n">Name</th>
            <th key="a">Actions</th>
          </tr>
        </thead>
        <tbody>
          { @props.takeouts.map @renderTakeoutRow }
        </tbody>
      </Table>
      { @renderReloadButton() }
    </div>

  renderTakeoutRow: (takeout) ->
    return null unless takeout.name
    # JSON.stringify fixes an issue when the id is not a string... mongo $oid
    <tr key={JSON.stringify takeout.id}>
      <td key="t">{moment(takeout.created).format("lll")}</td>
      <td key="n">{takeout.name}</td>
      <td key="a">{@renderActions(takeout)}</td>
    </tr>

  renderActions: (takeout) ->
    ActionType = @props.actions
    actions = <ActionType takeout={takeout} onUpdateOptions={@props.onUpdateOptions} />

  renderReloadButton: ->
    reloadLabel = if @state.loading then <span><Icon name="spinner" spin/> Loading...</span> else "Reload"
    <Button key="reload" disabled={@state.loading} onClick={@onReloadTakeouts}>{reloadLabel}</Button>


module.exports = TakeoutList
