React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
{ Icon }= require 'react-fa'
cx = require 'classnames'
Rating = require 'components/lib/rating'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ ButtonToolbar, ButtonGroup, Button, ButtonDropdown, DropdownItem, DropdownToggle, DropdownMenu} = require 'reactstrap'

ReviewToolbar = createReactClass
  displayName: 'ReviewToolbar'

  mixins: [ReactBacon.BaconMixin]

  propTypes:
    model: PropTypes.object.isRequired

  getInitialState: ->
    asc: false
    maxRating: 5
    type: 'open'
    sortDropdown: false
    ratingDropdown: false

  componentDidMount: ->
    @plug @props.model.asc, 'asc'
    @plug @props.model.maxRating, 'maxRating'
    @plug @props.model.status, 'type'

  onChangeType: (type, event) ->
    @props.model.setReviewsType type

  onReloadReviews: ->
    @props.model.reloadReviews()

  onToggleSortDir: ->
    @props.model.toggleSortDir()

  onChangeMaxRating: (newMax, event) ->
    @props.model.setMaxRating(newMax)

  toggleSortDropdown: ->
    @setState sortDropdown: not (@state.sortDropdown)

  toggleRatingDropdown: ->
    @setState ratingDropdown: not (@state.ratingDropdown)

  render: ->
    sortByTitle =
      <span>
        <span className="badge">{if @state.type == "open" then "New Reviews" else "Archived"}</span>
      </span>

    filterTitle =
      <span>
        <span className="badge">Max Rating: <Rating score={@state.maxRating / 5.0} /></span>
      </span>

    sortDirClass = if @state.asc then "sort-amount-asc" else "sort-amount-desc"

    <ButtonToolbar>
      <ButtonGroup>
        <ButtonDropdown id="reviews-dropdown" isOpen = {@state.sortDropdown} toggle={@toggleSortDropdown}>
          <DropdownToggle>
            {sortByTitle}
          </DropdownToggle>
          <DropdownMenu>
            <DropdownItem onClick={(e) => @onChangeType("open", e)}>New Reviews</DropdownItem>
            <DropdownItem onClick={(e) => @onChangeType("seen", e)}>Archived</DropdownItem>
          </DropdownMenu>
        </ButtonDropdown>
        <Button title="Sort Direction" onClick={@onToggleSortDir}><Icon name={sortDirClass} /></Button>
        <ButtonDropdown id="review-sort-rating" isOpen = {@state.ratingDropdown} toggle = {@toggleRatingDropdown}>
          <DropdownToggle>
            {filterTitle}
          </DropdownToggle>
          <DropdownMenu>
            {R.map @_renderRatingMenuItem, R.reverse R.range(1, 6)}
          </DropdownMenu>
        </ButtonDropdown>
        <Button onClick={@onReloadReviews}><Icon name="refresh" /> Reload</Button>
      </ButtonGroup>
    </ButtonToolbar>

  _renderRatingMenuItem: (rating) ->
    <DropdownItem key = {rating} rating={rating} onClick={(e) => @onChangeMaxRating(rating, e)}><Rating score={rating / 5.0} /></DropdownItem>


module.exports = ReviewToolbar
