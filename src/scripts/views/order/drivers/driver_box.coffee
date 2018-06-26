R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


{ Money }= require '../components/utils'
orderUtils = require '../components/utils'
{ formatTimeWithOffset, currency } = orderUtils

DriverBox = createReactClass
  displayName: 'DriverBox'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    driver: PropTypes.object.isRequired
    onSelect: PropTypes.func.isRequired
    locale: PropTypes.string.isRequired

  render: ->
    d = @props.driver
    <tr onClick={R.partial @props.onSelect , [d]}>
      <td><Icon name='car'/> { d.name }</td>
      <td className="text-right">{ d.delivery_info.total_orders_count }</td>
      <td className="text-right">
        <Money amount={ d.delivery_info.total_tips_today } locale={@props.locale}/>
      </td>
      <td className="text-right">{ d.delivery_info.active_orders_count }</td>
      <td className="text-right">{ d.distance }</td>
      <td>
        {
          if d.delivery_info.available_at && d.delivery_info.available_at > new Date()
            <Label color="info">{ formatTimeWithOffset(0, d.delivery_info.available_at) }</Label>
          else
            <Label color="success">Now</Label>
        }
      </td>
    </tr>

module.exports = DriverBox
