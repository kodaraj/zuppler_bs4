R = require 'ramda'

options = [
  id: 'identification'
  title: "Identification"
  selected: true
  fields: [
    { id: "id", title: "Order ID", default: true }
    { id: "code", title: "Conf. Code", default: true }
    { id: "permalink", title: "Restaurant ID" }
    { id: "restaurant", title: "Restaurant Name", default: true }
  ]
,
  id: 'settings'
  title: "Information"
  selected: true
  fields: [
    { id: 'service', title: 'Service Type', default: true }
    { id: 'timetype', title: 'Time Type', default: true }
    { id: 'date', title: 'Order Date', default: true }
    { id: 'time', title: 'Order Time', default: true }
    { id: 'payment', title: 'Payment', default: true }
    { id: 'payment_details', title: 'Payment Details' }
    { id: 'comments', title: 'Special Instr.' }
  ]
,
  id: 'totals'
  title: "Totals"
  fields: [
    { id: 'subtotal', title: 'Subtotal' }
    { id: 'discount', title: 'Discount' }
    { id: 'discount_code', title: 'Discount Codes' }
    { id: 'delivery', title: 'Delivery Charge' }
    { id: 'service', title: 'Service Charge' }
    { id: 'tax', title: 'Tax' }
    { id: 'tip', title: 'Tip' }
    { id: 'total', title: 'Total', default: true }
  ]
,
  id: 'customer'
  title: "Customer"
  fields: [
    { id: 'name', title: 'Name', default: true }
    { id: 'email', title: 'Email' }
    { id: 'phone', title: 'Phone' }
  ]
,
  id: 'source'
  title: "Source"
  fields: [
    { id: 'channel_permalink', title: 'Channel ID' }
    { id: 'integration', title: 'Page Address' }
    { id: 'tracking', title: 'Custom Track #' }
  ]
,
  id: 'addresses'
  title: "Address"
  fields: [
    { id: 'address', title: "Address", default: true }
  ]
,
  id: 'items'
  title: "Items & Modifiers"
  fields: [
    { id: 'menu', title: 'Menu' }
    { id: 'category', title: 'Category' }
    { id: 'name', title: 'Item Name' }
    { id: 'barcode', title: 'Item Barcode' }
    { id: 'quantity', title: 'Quantity' }
    { id: 'price', title: 'Item Price' }
    { id: 'tax', title: 'Tax' }
    { id: 'item_total', title: 'Item Total' }
    { id: 'total', title: 'Total' }
    { id: 'comments', title: 'Special Instr' }
    { id: 'modifier', title: 'Modifier Name' }
    { id: 'option', title: 'Modifier Option' }
    { id: 'modifier_quantity', title: 'Modifier Quantity' }
    { id: 'modifier_price', title: 'Modifier Price' }
    { id: 'modifier_tax', title: 'Modifier Tax' }
    { id: 'modifier_total', title: 'Modifier Total' }
  ]
,
  id: 'custom_data'
  title: "Extra Information"
  fields: [
    { id: 'combined', title: 'All data combined on a column separated by commas' }
    { id: 'fields', title: 'Separated columns in the output' }
  ]
,
  id: 'rds'
  title: "Delivery Info"
  fields: [
    { id: 'driver_name', title: "Driver Name", default: true }
    { id: 'delivery_state', title: "Delivery State", default: true }
  ]
]


isDefault = R.propOr(false, 'default')
onlyChecked = (field) -> !!field.checked
resetChecked = (field) -> R.merge field, { checked: false }
resetSectionFields = R.pipe(R.prop('fields'), R.ap([resetChecked]))

makeDefaultOptions = ->
  opts = R.clone options
  updateSectionSelection = (section) ->
    id: section.id
    title: section.title
    checked: R.any(isDefault, section.fields)
    fields: R.map (field) ->
      R.assoc 'checked', isDefault(field), field
    , section.fields

  R.map updateSectionSelection, opts

toRequestOptions = (opts) ->
  transformOpts = (sum, section) ->
    fieldIds = R.map(R.prop('id'), R.filter(onlyChecked, section.fields))
    R.assoc section.id, fieldIds, sum

  params = R.reduce transformOpts, {}, R.filter(onlyChecked, opts)
  params.sections_order = R.map(R.prop('id'), R.filter(onlyChecked, opts))
  params

resetAllOptions = (opts) ->
  sections = R.map resetChecked, opts
  resetSections = (section) ->
    R.merge(section, { fields: resetSectionFields(section) })
  R.map resetSections, sections

fromRequestOptions = (opts) ->
  options = resetAllOptions(makeDefaultOptions())

  updateSectionFromParams = (section) ->
    sectionParam = opts[section.id]
    section.checked = !!sectionParam and sectionParam.length > 0
    if section.checked
      section.fields = R.map (field) ->
        field.checked = R.contains(field.id, sectionParam)
        field
      , section.fields
    section

  sectionsOrder = (section) ->
    pos = opts.sections_order.indexOf(section.id)
    if pos >= 0 then pos else 100 # send it to the end

  R.sortBy sectionsOrder, R.map updateSectionFromParams, options

toggleSection = (sections, id, enabled) ->
  section = R.find R.pipe(R.prop('id'), R.equals(id)), sections
  section.checked = enabled
  sections

toggleSectionField = (sections, section_id, id, enabled) ->
  findById = (id) -> R.find R.pipe(R.prop('id'), R.equals(id))
  sectionFinder = findById(section_id)
  fieldFinder = findById(id)
  section = sectionFinder(sections)
  field = fieldFinder(section.fields)
  field.checked = enabled
  sections

module.exports =
  makeDefaultOptions: makeDefaultOptions
  toRequestOptions: toRequestOptions
  fromRequestOptions: fromRequestOptions
  toggleSection: toggleSection
  toggleSectionField: toggleSectionField
