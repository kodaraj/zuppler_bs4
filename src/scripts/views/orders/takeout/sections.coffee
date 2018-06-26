React = require 'react'
{ Icon }= require 'react-fa'
R = require 'ramda'
createReactClass = require 'create-react-class'

ReactBacon = require 'react-bacon'
List = require 'models/list'
Condition = require 'models/condition'
NavigationMixin = require 'components/lib/navigation'
{ Row, Col, Form, FormGroup, Label, Input, Container } = require 'reactstrap'
resUtil = require 'utils/resources'
cx = require 'classnames'
PropTypes = require 'prop-types'

takeoutStore = require 'stores/takeout'
listStore = require 'stores/lists'

takeoutOptions = require 'stores/takeout_options'

sortable = require('react-sortable-mixin')
moment = require('moment')

toastr = require('components/toastr-config')

{ BaconMixin } = ReactBacon

Sections = createReactClass
  displayName: 'SectionsList'
  mixins: [sortable.ListMixin]

  props:
    sections: PropTypes.array.isRequired
    onResorted: PropTypes.func
    sortMode: PropTypes.bool.isRequired

  componentWillMount: ->
    @passProps = R.pick ['onSectionSelected', 'onSectionFieldSelected'], @props

  componentDidMount: ->
    @setState items: @props.sections

  renderSection: (section, index) ->
    if @props.sortMode
      <Section key={section.id} index={index} section={section} {...@movableProps} {...@passProps}
        onResorted={@onFieldsResorted} />
    else
      <EditSection key={section.id} section={section} {...@passProps} />

  onResorted: (sections) ->
    @props.onResorted(sections)

  onFieldsResorted: (section) ->
    @props.onResorted(@state.items)

  render: ->
    <Form inline>
      { @props.sections.map(@renderSection) }
    </Form>

EditSection = createReactClass
  displayName: 'EditSection'

  props:
    section: PropTypes.array.isRequired
    onSectionSelected: PropTypes.func.isRequired
    onSectionFieldSelected: PropTypes.func.isRequired

  render: ->
    <Container>
      <Row key={@props.section.id} style={marginBottom: '4px', borderBottom: '1px dashed #999', paddingBottom: '4px'}>
        <Col xs={4}>
            <FormGroup row check inline key={@props.section.id} onChange={R.partial(@props.onSectionSelected, [@props.section.id])}>
              <Label check>
                <Col>
                <Input type="checkbox" defaultChecked={@props.section.checked}/>{@props.section.title}
                </Col>
              </Label>
            </FormGroup>
        </Col>
        <Col xs={8} style={borderLeft : '1px solid #333'}>
          <div>
            <Fields fields={@props.section.fields} onSectionFieldSelected={@props.onSectionFieldSelected}
              section={@props.section} sortMode={false} />
          </div>
        </Col>
      </Row>
    </Container>

Section = createReactClass
  displayName: 'Section'

  mixins: [sortable.ItemMixin]

  props:
    section: PropTypes.array.isRequired
    onSectionSelected: PropTypes.func.isRequired
    onSectionFieldSelected: PropTypes.func.isRequired

  render: ->
    <Container>
      <Row key={@props.section.id} style={marginBottom: '4px', borderBottom: '1px dashed #999', paddingBottom: '4px'}>
        <Col xs={4}>
          <Icon name="bars" /> {@props.section.title}
        </Col>
        <Col xs={8} style={borderLeft : '1px solid #333'}>
          <div>
            <Fields fields={@props.section.fields}
              onResorted={@props.onResorted}
              sortMode={true} section={@props.section} />
          </div>
        </Col>
      </Row>
    </Container>


Fields = createReactClass
  displayName: 'Fields'

  mixins: [sortable.ListMixin]

  props:
    fields: PropTypes.array.isRequired
    section: PropTypes.object.isRequired
    sortMode: PropTypes.bool.isRequired
    onSectionFieldSelected: PropTypes.array.isRequired
    onResorted: PropTypes.func

  onResorted: (fields) ->
    @props.onResorted(fields)

  componentDidMount: ->
    @setState items: @props.fields

  renderField: (field, index) ->
    if @props.sortMode
      <Field key={field.id} index={index} title={field.title} checked={field.checked} {...@movableProps} />
    else
      <EditField key={field.id} title={field.title} checked={field.checked}
        onSectionFieldSelected={R.partial @props.onSectionFieldSelected, [@props.section.id, field.id]} mute={!@props.section.checked} />

  render: ->
    <Row>
      { @state.items.map(@renderField) }
    </Row>

EditField = createReactClass
  displayName: 'EditField'

  props:
    title: PropTypes.string.isRequired
    checked: PropTypes.bool.isRequired
    onSectionFieldSelected: PropTypes.func.isRequired

  render: ->
    textClass = cx "text-muted": @props.muted

    <Col key={@props.title} xs={6} className="field">
        <FormGroup check inline disabled={@props.mute} onChange={@props.onSectionFieldSelected}>
          <Label check>
            <Input type="checkbox" defaultChecked={@props.checked} />
          </Label>
        </FormGroup>
        <span className={textClass}>{@props.title}</span>
    </Col>

Field = createReactClass
  displayName: 'Field'

  mixins: [sortable.ItemMixin]

  props:
    title: PropTypes.string.isRequired
    checked: PropTypes.bool.isRequired

  render: ->
    icon = if @props.checked then React.createElement(Icon, {"name": 'check'}) else null

    <Col xs={6} className={cx 'sortable', 'text-muted': !@props.checked}>
      <Icon name="columns" /> {@props.title}
    </Col>

module.exports = Sections
