React = require 'react'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

Autosuggest = require 'react-autosuggest'
Autocomplete = require 'ron-react-autocomplete'
ReactBacon = require 'react-bacon'
restaurantLookup = require 'stores/restaurant-lookup'
driverLookup = require 'stores/driver-lookup'

DateRangePicker = require 'react-bootstrap-daterangepicker'
# require '!style-loader!css-loader!react-bootstrap-daterangepicker/css/daterangepicker.css'
{ Input } = require 'reactstrap'
moment = require 'moment'

defaultDateInterval = ->
  startDate: moment().subtract(30, 'days').toISOString()
  endDate: moment().toISOString()

typeToMarkup = (t) ->
  <option key={t.id} value={t.id}>{t.label}</option>

dateRangeToLabel = (s, e) ->
  if s and e
    startDate = moment s
    endDate = moment e
    formatStart = "MMM DD"
    formatEnd = "DD, YYYY"
    if !startDate.isSame(endDate, 'month')
      formatStart = "MMM DD"
      formatEnd = "MMM DD, YYYY"
    if !startDate.isSame(endDate, 'year')
      formatStart = "MMM DD, YYYY"
      formatEnd = "MMM DD, YYYY"
    if !startDate.isSame(endDate, 'day')
      "#{startDate.format(formatStart)} to #{endDate.format(formatEnd)}"
    else
      startDate.format("on MMM DD, YYYY")

StringValueEditor = createReactClass
  displayName: 'StringValueEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.string.isRequired

  onChange: (event) ->
    @props.onChange event.target.value

  render: ->
    <Input type="text" value={@props.value} onChange={@onChange}  />

EnumValueEditor = createReactClass
  displayName: 'EnumValueEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.string.isRequired
    options: PropTypes.array.isRequired

  onChange: (event) ->
    @props.onChange event.target.value

  componentDidMount: ->
    @props.onChange @props.options[0].id unless @props.value

  render: ->
    optionsMarkup = @props.options.map typeToMarkup

    <Input type="select" value={@props.value} onChange={@onChange}>
      {optionsMarkup}
    </Input>

DateValueEditor = createReactClass
  displayName: 'DateValueEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.object.isRequired

  onChange: (event, picker) ->
    value =
      startDate: picker.startDate.toJSON()
      endDate: picker.endDate.toJSON()
    @props.onChange value

  componentDidMount: ->
    @props.onChange defaultDateInterval() if !@props.value

  render: ->
    value = "click to select"
    ranges =
      'Today': [moment(), moment()],
      'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
      'Last 7 Days': [moment().subtract(6, 'days'), moment()],
      'Last 30 Days': [moment().subtract(29, 'days'), moment()],
      'This Month': [moment().startOf('month'), moment().endOf('month')],
      'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]

    intervalValue = @props.value or defaultDateInterval()
    value = dateRangeToLabel(intervalValue.startDate, intervalValue.endDate)
    startDate = moment(intervalValue.startDate)
    endDate = moment(intervalValue.endDate)

    <span className="inline-next-div">
      <DateRangePicker applyClass="date-range-picker" ref="fieldValue" onApply={@onChange} opens="left" drops="down"
          minDate={moment(Date.parse('2011/9/1'))}
          startDate={startDate}
          endDate={endDate}
          showDropdowns={true} showWeekNumbers={true} ranges={ranges}
          buttonClasses={['btn', 'btn-sm']} applyClass={'btn-primary'}
          cancelClass={'btn-default'}>
        <Input type="text" readOnly value={value} />
      </DateRangePicker>
    </span>

DateTimeValueEditor = createReactClass
  displayName: 'DateValueEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.object.isRequired

  onChange: (event, picker) ->
    value =
      startDate: picker.startDate.toJSON()
      endDate: picker.endDate.toJSON()
    @props.onChange value

  componentDidMount: ->
    @props.onChange defaultDateInterval() if !@props.value

  render: ->
    value = "click to select"
    ranges =
      'Today': [moment(), moment()],
      'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
      'Last 7 Days': [moment().subtract(6, 'days'), moment()],
      'Last 30 Days': [moment().subtract(29, 'days'), moment()],
      'This Month': [moment().startOf('month'), moment().endOf('month')],
      'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]

    intervalValue = @props.value or defaultDateInterval()
    value = dateRangeToLabel(intervalValue.startDate, intervalValue.endDate)
    startDate = moment(intervalValue.startDate)
    endDate = moment(intervalValue.endDate)

    <span className="inline-next-div">
      <DateRangePicker applyClass="date-range-picker" ref="fieldValue" onApply={@onChange}
        opens="left" drops="down" minDate={moment(Date.parse('2011/9/1'))}
        startDate={startDate} endDate={endDate}
        timePicker={true} timePickerIncrement={15} locale={format: 'MM/DD/YYYY h:mm A'}
        showDropdowns={true} showWeekNumbers={true} ranges={ranges}
        buttonClasses={['btn', 'btn-sm']} applyClass={'btn-primary'}
        cancelClass={'btn-default'}>
        <Input type="text" readOnly value={value} />
      </DateRangePicker>
    </span>


RelativeDateEditor = createReactClass
  displayName: 'RelativeDateEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.object.isRequired
    options: PropTypes.array.isRequired

  componentDidMount: ->
    @props.onChange @getValue() unless @props.value

  getValue: ->
    R.defaultTo(count: 1, unit: @props.options[0].id)(@props.value)

  onChangeCount: (event) ->
    one = R.compose R.max(1), R.min(90), R.defaultTo(1)
    @props.onChange R.assoc 'count', one(parseInt(event.target.value)), @getValue()

  onChangeUnit: (event) ->
    @props.onChange R.assoc 'unit', event.target.value, @getValue()

  render: ->
    optionsMarkup = @props.options.map typeToMarkup
    value = @getValue()
    <span>
      <Input type="number" value={value.count} style={width: "100px"} onChange={@onChangeCount} />
      <Input type="select" value={value.unit} onChange={@onChangeUnit}>
        {optionsMarkup}
      </Input>
    </span>

RestaurantLookup = createReactClass
  displayName: 'StringValueEditor'
  mixins: [ReactBacon.BaconMixin, require("zuppler-js/lib/utils/bacon-observe-mixin")]
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.string.isRequired

  getInitialState: ->
    restaurants: []
    value: null

  componentDidMount: ->
    @observeStream restaurantLookup.results, @saveSearchResults

  saveSearchResults: (results) ->
    @setState restaurants: results

  onChange: (event, {suggestion, suggestionValue, sectionIndex, method})->
    toValue = R.pick ['id', 'name']
    @props.onChange toValue suggestion

  onClear: ->
    @setState restaurants: []

  search: ({value}) ->
    @setState value: value

    if value.length > 2
      restaurantLookup.search value

  renderRestaurant: (r) ->
    <div>
      <div key="name"><strong>{r.name}</strong></div>
      <div key="address" className="text-muted">{r.street}, {r.city}, {r.country}</div>
    </div>

  render: ->
    name = if @props.value then @props.value.name else null
    inputProps =
      placeholder: "enter name or permalink...."
      value: @state.value || name || ''
      onChange: (event, {newValue}) => @setState value: newValue

    <Autosuggest suggestions={@state.restaurants} onSuggestionsFetchRequested={@search}
      getSuggestionValue={R.prop('name')} renderSuggestion={@renderRestaurant}
      onSuggestionSelected={@onChange} onSuggestionsClearRequested={@onClear}
      inputProps={inputProps}/>


DriverLookup = createReactClass
  displayName: 'StringValueEditor'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.string.isRequired

  onChange: (value)->
    toValue = R.pick ['id', 'name']
    @props.onChange toValue value
    @searchUpdater?()
    @searchUpdater = null

  search: (options, input, callback) ->
    # Working hack as the callback is a method in the autocomplete component
    # #FIXME: Rewrite the component to take a stream of data?
    @searchUpdater or= driverLookup.results.onValue (results) ->
      callback null, results

    if input.length > 2
      driverLookup.search input

  componentWillUnmount: ->
    @searchUpdater?()

  renderDriver: (r) ->
    <div>
      <div key="name"><strong>{r.name}</strong></div>
    </div>

  render: ->
    name = if @props.value then @props.value.name else null

    # Replace this to autosuggest
    <Autocomplete searchTerm={name} onChange={@onChange} search={@search} resultIdentifier="id" label={@renderDriver}/>

deliveryServicesLookup = require 'stores/delivery-services-lookup'

DeliveryServiceLookup = createReactClass
  displayName: 'StringValueEditor'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    onChange: PropTypes.func.isRequired
    value: PropTypes.string.isRequired

  onChange: (value)->
    toValue = R.pick ['id', 'name']
    @props.onChange toValue value
    @searchUpdater?()
    @searchUpdater = null

  search: (options, input, callback) ->
    # Working hack as the callback is a method in the autocomplete component
    # #FIXME: Rewrite the component to take a stream of data?
    @searchUpdater or= deliveryServicesLookup.results.onValue (results) ->
      callback null, results

    if input.length > 2
      deliveryServicesLookup.search input

  componentWillUnmount: ->
    @searchUpdater?()

  renderDeliveryService: (r) ->
    <div>
      <div key="name"><strong>{r.name}</strong></div>
    </div>

  render: ->
    name = if @props.value then @props.value.name else null

    # TODO Replace this with autosuggest
    <Autocomplete searchTerm={name} onChange={@onChange} search={@search} resultIdentifier="id" label={@renderDeliveryService}/>

module.exports =
  StringValueEditor: StringValueEditor
  EnumValueEditor: EnumValueEditor
  RelativeDateEditor: RelativeDateEditor
  DateValueEditor: DateValueEditor
  DateTimeValueEditor: DateTimeValueEditor
  RestaurantLookup: RestaurantLookup
  DeliveryServiceLookup: DeliveryServiceLookup
  DriverLookup: DriverLookup
  defaultDateInterval: defaultDateInterval
