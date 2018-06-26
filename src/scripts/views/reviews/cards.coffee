React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
R = require 'ramda'
cx = require 'classnames'
NavigationMixin = require 'components/lib/navigation'
Rating = require 'components/lib/rating'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ Card, CardHeader, CardFooter, CardBody, CardColumns } = require 'reactstrap'
import Pagination from "react-js-pagination"

moment = require 'moment'
orderStore = require 'stores/order'
presenceStore = require 'stores/presence'

ReactBacon = require 'react-bacon'
{ shorten } = require 'zuppler-js/lib/utils/text'

{ timeSlice } = require 'utils/time'

Cards = createReactClass
  displayName: 'Cards'
  mixins: [ReactBacon.BaconMixin]

  propTypes:
    model: PropTypes.object.isRequired
    selectedOrder: PropTypes.object
    selectedReview: PropTypes.object
    # reviews: PropTypes.array.isRequired
    # selected: PropTypes.object
    columns: PropTypes.number.isRequired
    # page: PropTypes.number
    onOpenReview: PropTypes.func.isRequired

  getInitialState: ->
    page: 1
    reviews: []

  componentDidMount: ->
    @plug @props.model.data, 'reviews'
    @plug @props.model.page, 'page'

  onSetPage: (page) ->
    @props.model.setPage page

  render: ->
    <div>
      {@renderReviews()}
      {@renderPagination()}
    </div>

  renderReviews: () ->
    <Reviews reviews={@state.reviews} selected={@props.selectedOrder}
              columns={@props.columns} onOpenReview={ @props.onOpenReview }/>

  renderPagination: ->
     <MetaPagination page={@state.page} onSetPage=(@onSetPage) />


Reviews = createReactClass
  displayName: 'Reviews'
  propTypes:
    reviews: PropTypes.array.isRequired
    selected: PropTypes.object
    columns: PropTypes.number.isRequired

  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    ordersToUsers: {}

  componentDidMount: ->
    @plug presenceStore.orders, 'ordersToUsers'

  render: ->
    if @props.columns > 1
      <CardColumns>
        {R.map @renderCard, @props.reviews}
      </CardColumns>
    else
      <Card>
        {R.map @renderCard, @props.reviews}
      </Card>

  renderCard: (review) ->
    active = @props.selected and @props.selected.id == review.id
    users = @state.ordersToUsers[review.session.name] || []
    <ReviewCard key = {review.id} review={review} users={users} active={active} onOpenReview={@props.onOpenReview}></ReviewCard>

ReviewCard = createReactClass
  displayName: 'ReviewCard'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    review: PropTypes.object.isRequired
    users: PropTypes.array
    active: PropTypes.bool

  orderStateClass: ->
    state = @props.review.status
    score = Math.floor(@props.review.session.average * 5)
    cx "panel-review-#{state}-#{score}", 'active': @props.active

  renderHeader: ->
    <div style={textOverflow: "ellipsis", overflow: "hidden", whiteSpace: "nowrap"}>
      { shorten @props.review.comment, 45, true}
    </div>

  renderFooter: (users) ->
    timeInfo = moment(new Date @props.review.session.updated).fromNow()
    orderId = @props.review.session.name.split('-')[0]
    <span className="card-footer">
      <span key="c"><Icon name="clock-o" /> { timeInfo }</span>
      <span key="i"><Icon name="info" /> { @props.review.status }</span>
      <span key="t"><Icon name="ticket" /> { orderId }</span>
      <span className="presence-info">{users}</span>
    </span>

  render: ->
    initials = R.compose(R.join(""), R.map((str)-> str.substring(0, 1)), R.split(/\s+/))
    roleToClass = R.map (n) -> "presence-role-#{n}"

    users = @props.users.map (u) ->
      className = cx "label", "label-default", roleToClass(u.roles).join(" ")
      <span key={u.email} className={className} title={u.user}>{initials u.user || "N A"}</span>

    <Card onClick={R.partial @props.onOpenReview, [@props.review]} className={@orderStateClass()}>
      <CardHeader>{@renderHeader()}</CardHeader>
      <CardBody>
        <span key="rating" className="customer-name">
          <Rating score={@props.review.session.average} />
        </span>
      </CardBody>
      <CardFooter>{@renderFooter(users)}</CardFooter>
    </Card>

MetaPagination = createReactClass
  displayName: 'MetaPagination'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    page: PropTypes.number.isRequired
    onSetPage: PropTypes.func.isRequired

  selectPage: (pageNumber, event) ->
    @props.onSetPage pageNumber

  render: ->
    pages = 100

    <Pagination
      prevPageText='prev'
      nextPageText='next'
      firstPageText='first'
      lastPageText='last'
      itemsCountPerPage = {20}
      activePage={@props.page}
      pageRangeDisplayed={3}
      onChange={@selectPage}
      totalItemsCount = {pages*20}
      itemClass="page-item"
      linkClass="page-link"
    />

module.exports = Cards
