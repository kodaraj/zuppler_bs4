Bacon = require 'baconjs'
React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
List = require 'models/list'
RdsList = require 'models/rds-list'
listStore = require 'stores/lists'
rdsListStore = require 'stores/rds-lists'
uiStore = require 'stores/ui'
userStore = require 'stores/user'
NavigationMixin = require 'components/lib/navigation'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
uiStore = require 'stores/ui'
cx = require 'classnames'
Editors = require './editors'
ValueEditors = require './value-editors'
config = require './configuration'
utils = require './utils'
{ FormGroup, Input, Label, Modal, ModalBody, ModalTitle, ModalHeader, ModalFooter, Button , Form } = require 'reactstrap'
{ addId } = require 'utils/resources'
{ withRouter } = require "react-router-dom"


ConditionEditor = createReactClass
  displayName: 'ConditionEditor'

  getInitialState: ->
    @_stateFieldsFromCondition(@props.condition)

  onSelectField: (value) ->
    @props.condition.field = value
    @props.condition.op = config.firstOpId(value)
    @props.condition.value = null
    @setState @_stateFieldsFromCondition(@props.condition)

  onSelectOp: (value) ->
    @props.condition.op = value
    @props.condition.value = null
    @setState @_stateFieldsFromCondition(@props.condition)

  onChangeValue: (value) ->
    @setState value: value
    @props.condition.value = value

  _stateFieldsFromCondition: (condition) ->
    fieldType: config.fieldTypeById(condition.field)
    opType: config.opTypeById(condition.field, condition.op)
    valueType: config.valueTypeById(condition.field, condition.op)
    value: condition.value

  componentDidMount: ->
    unless @state.value
      @onChangeValue config.defaultValue(@props.condition.field, @props.condition.op)

  render: ->
    ValueEditor = @state.valueType.editor
    <Form inline>
      <FormGroup style={paddingBottom: "0.5em"}>
        <Editors.FieldTypeEditor condition={@props.condition} fieldTypes={R.values(config.fieldTypesForRoles(userStore.roles()))} onChange={@onSelectField} />
        <Editors.OpTypeEditor fieldType={@state.fieldType} condition={@props.condition} onChange={@onSelectOp} />
        <ValueEditor value={@state.value} op={@state.op} onChange={@onChangeValue} options={@state.valueType.options}/>
        <span style={paddingLeft: "2ex"}>
          <Button size="small" onClick={@props.onAddCondition}>+</Button>
          <Button size="small" onClick={@props.onRemoveCondition}>-</Button>
        </span>
      </FormGroup>
    </Form>

toBaconTemplate = (value, key, obj) ->
  if value and value.toString().startsWith('Bacon')
    value
  else
    Bacon.once(value)

Editor = createReactClass
  displayName: 'Editor'
  mixins: [ReactBacon.BaconMixin]

  props:
    listId: PropTypes.string.isRequired
    onSave: PropTypes.func.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    list:
      id: null
      version: 1
      soundName: 'notification'
      name: 'New List'
      appliesTo: 'any'
      conditions: [utils.defaultCondition()]
      locked: false
      useSounds: false
      sortProp:
        prop: 'time'
        asc: false

  componentDidMount: ->
    listId = @props.listId

    current = uiStore
      .current
      .filter R.compose R.not, R.isNil
      .filter R.propEq('id', listId)
      .map (list) -> list.toExternalForm()
      .map R.mapObjIndexed toBaconTemplate
      .flatMap Bacon.combineTemplate
      .skipDuplicates()
      .map (o) -> R.merge o, R.assoc('version', R.inc(R.defaultTo(0, R.prop('version', o))), {})
      .map (o) -> R.assoc 'conditions', R.map(addId, o.conditions), o
      .toProperty()

    @plug current, 'list'

  onSave: ->
    if @state.list.name.trim().length > 0
      @props.onSave(@state.list)
    else
      alert("Please enter a name for this list!")

  onChangeAppliesTo: (event) ->
    @setState list: R.merge @state.list, appliesTo: event.target.value

  onChangeName: (event) ->
    @setState list: R.merge @state.list, name: event.target.value

  onChangeLocked: (event) ->
    @setState list: R.merge @state.list, locked: event.target.checked

  onChangeUseSounds: (event) ->
    @setState list: R.merge @state.list, useSounds: event.target.checked

  onChangeListSoundName: (event) ->
    @setState list: R.assoc 'soundName', event.target.value, @state.list

  addCondition: ->
    @setState list: R.merge @state.list, conditions: R.append(utils.defaultCondition(), @state.list.conditions)

  removeCondititon: (index) ->
    if @state.list.conditions.length > 1
      conditions = R.remove(index, 1, @state.list.conditions)
      @setState list: R.assoc 'conditions', conditions, @state.list

  render: ->
    soundClass = cx 'hidden': !@state.list.useSounds
    <Modal isOpen={true} onExit={@onClose}>
      <ModalHeader>
        Orders List Editor
      </ModalHeader>
      <ModalBody>
        <div className="form-horizontal" style={height: "500px", overflowY: "auto", paddingLeft: "15px", paddingRight: "15px"}>
          <FormGroup id="listName">
            <Label>List Name:</Label>
            <Input type="text" value={@state.list.name} onChange={@onChangeName} />
          </FormGroup>

          <FormGroup id="appliesTo">
            <Label>Orders must have</Label>
            <Input type="select" value={@state.list.appliesTo} placeholder="select behavior...." onChange={@onChangeAppliesTo}>
              <option value="all">ALL conditions satisfied</option>
              <option value="any">ANY condition satisfied</option>
            </Input>
          </FormGroup>

          {R.addIndex(R.map)(@renderConditionEditor, @state.list.conditions)}

          <FormGroup check inline id="locked">
            <Label check>
              <Input type="checkbox" checked={@state.list.locked} onChange={@onChangeLocked} /> Locked (Cannot be removed by mistake unless this is unchecked)
            </Label>
          </FormGroup>

          <FormGroup check inline id="useSounds">
            <Label check>
              <Input type="checkbox" checked={@state.list.useSounds} onChange={@onChangeUseSounds} /> Play sounds when list content changes
            </Label>
          </FormGroup>

          <FormGroup id="sound" className={soundClass}>
            <Label>Sound notification type</Label>
            <Input type="select" value={@state.list.soundName} onChange={@onChangeListSoundName}>
              <option value="notification">Discrete</option>
              <option value="neworder">New Order Notification</option>
            </Input>
          </FormGroup>
        </div>
      </ModalBody>
      <ModalFooter>
        <Button color="primary" onClick={@onSave}>Save</Button>
        <Button onClick={@props.onClose}>Close</Button>
      </ModalFooter>
    </Modal>

  renderConditionEditor: (c, index) ->
    <ConditionEditor key={c.id} condition={c} onAddCondition={@addCondition}
                     onRemoveCondition={R.partial @removeCondititon, [ index ]} />


ListEditor = createReactClass
  displayName: 'ListEditor'

  mixins: [NavigationMixin]

  getInitialState: ->
    {}

  onSave: (listData) ->
    listId = @props.match.params.listId
    list = new List listData

    if listId
      listStore.updateList listId, list
    else
      listStore.addList list
    @props.history.push "/lists/#{list.id}"

  onClose: ->
    @props.history.goBack()

  render: ->
    <Editor onSave={@onSave} onClose={@onClose} listId={@props.match.params.listId}/>

ListEditor.getDerivedStateFromProps = (props, state) ->
    uiStore.setCurrentUI("lists", props.match.params.listId)

RdsListEditor = createReactClass
  displayName: 'RdsListEditor'

  mixins: [NavigationMixin]

  getInitialState: ->
    {}

  onSave: (listData) ->
    listId = @props.match.params.listId
    list = new RdsList listData

    if listId
      rdsListStore.updateList listId, list
    else
      rdsListStore.addList list
    @props.history.push "/rds/#{list.id}"

  onClose: ->
    @props.history.goBack()

  render: ->
    <Editor onSave={@onSave} onClose={@onClose} listId={@props.match.params.listId}/>

RdsListEditor.getDerivedStateFromProps = (props, state) ->
    uiStore.setCurrentUI("lists", props.match.params.listId)

module.exports =
  ListEditor: withRouter(ListEditor)
  RdsListEditor: withRouter(RdsListEditor)
