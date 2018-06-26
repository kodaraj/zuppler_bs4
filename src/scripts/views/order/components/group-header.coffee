React = require 'react'
R = require 'ramda'
{Icon }= require 'react-fa'
cx = require 'classnames'
userStore = require 'stores/user'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

ExpandedStateMixin = (prefName) ->
  getInitialState: ->
    _expanded: userStore.settingFor prefName

  onToggleExpandState: ->
    @setState _expanded: !@state._expanded
    userStore.setSettingFor prefName, !@state._expanded

  isExpanded: ->
    @state._expanded

  expandedToClassName: ->
    cx hidden: !@isExpanded()

GroupHeader = createReactClass
  displayName: 'OrderHeader'

  propTypes:
    title: PropTypes.string.isRequired
    onToggleExpandState: PropTypes.func.isRequired
    expanded: PropTypes.bool.isRequired

  render: ->
    expandedStateToIcon = (expanded) ->
      if expanded then 'compress' else 'expand'

    <li key="header" className="list-group-item section-header">
      <span key="label">{@props.title}</span>
      <span key="actions" className="pull-right">
        {@props.children}
        <a key="collapse" className="btn-order-header" onClick={@props.onToggleExpandState}>
          <Icon name={expandedStateToIcon(@props.expanded)} />
        </a>
      </span>
    </li>

module.exports =
  GroupHeader: GroupHeader
  ExpandedStateMixin: ExpandedStateMixin
