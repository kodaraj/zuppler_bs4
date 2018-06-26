React = require 'react'
R = require 'ramda'
moment = require 'moment'
timeUtils = require 'utils/time'
userStore = require 'stores/user'
cx = require 'classnames'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{Row, Col, Popover, PopoverBody, PopoverHeader, UncontrolledTooltip, Badge } = require 'reactstrap'
{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'

renderPopoverTitle = (event) ->
  <span>
    <em className="pull-right">{event.state}</em>
    <strong>{event.message}</strong>
  </span>

renderPopover = (event) ->
  <PopoverHeader>{renderPopoverTitle(event)}</PopoverHeader>
  <PopoverBody>
    <pre>{JSON.stringify(event.options, null, 2)}</pre>
    Click anywhere else to close.
  </PopoverBody>


OrderEvents = createReactClass
  displayName: 'OrderEvents'
  mixins: [ExpandedStateMixin("sections.events.visible")]
  propTypes:
    events: PropTypes.array.isRequired
    order: PropTypes.object.isRequired
    restaurant: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired

  render: ->
    return null if @props.events.length == 0

    data = @props.events
    tz = @props.restaurant.timezone.offset
    start = moment(data[data.length-1].created_at).utcOffset(tz)

    <ul className="list-group">
      <GroupHeader title="Events" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState} />
      <span className={@expandedToClassName()}>
        <li className="list-group-item"><span>{data.length} events, newest first</span></li>
        { R.map @renderEvent(start, tz), data }
      </span>
    </ul>

  renderEvent: R.curry (start, tz, e) ->
    stateIndicator = cx "list-group-item", "event-item", "event-#{e.state}"
    optionsClass = cx 'hidden': 0 == R.length R.keys e.options
    eventTime = moment(e.created_at).utcOffset(tz)

    <li className={stateIndicator} key={e.id}>
      <Row>
        <Col xs={5}>
          <span className="event-time-diff">+{timeUtils.timeDiff(start, e.created_at)} </span>
          <span className="event-time" title={eventTime.format('lll')}>{eventTime.format('hh:mm')}</span>
        </Col>
        <Col xs={7} className="event-state">
          <span className="text-muted">{e.state}</span>{ ' ' }
          <Badge className={optionsClass} id="setTooltip"><Icon name="info" /></Badge>
          <Popover  target="setTooltip" placement="left" style={maxWidth: "600px"}>
            {renderPopover(e)}
          </Popover>
        </Col>
      </Row>
      <Row>
        <Col xs={12}>
          <span title={e.message}>{ e.message }</span>
        </Col>
      </Row>
      <Row>
        <Col xs={12} className="event-sender">
          <span>{e.sender}</span>
        </Col>
      </Row>
    </li>

module.exports = OrderEvents
