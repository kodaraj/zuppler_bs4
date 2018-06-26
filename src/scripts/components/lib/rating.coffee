React = require 'react'
{Icon }= require 'react-fa'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


Rating = createReactClass
  displayName: 'rating'
  props:
    score: PropTypes.number.isRequired

  render: ->
    maxStars = 5
    score = @props.score * maxStars

    makeStar = R.curry (name, n) -> <Icon key={"#{name}-#{n}"} name={name} />

    fullStars = R.map makeStar('star'), R.range 0, Math.floor(score)
    halfStars = R.map makeStar('star-half-o'), R.range Math.floor(score), Math.ceil(score)
    emptyStars = R.map makeStar('star-o'), R.range Math.ceil(score), 5

    <span title={score}>
      {fullStars}{halfStars}{emptyStars}
    </span>

module.exports = Rating
