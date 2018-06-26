# Order
  * UUID
  * State
  * Due

# Phases
  1. orders api
  2. orders display
  3. orders filtering
  4. orders searching
  5. orders update push
  6. order content
  7. order actions api
  8. actions display
  9. actions create (manual action)
  10. order notifications api
  11. order notifications display
  12. order notification perform (manual)
  13. order confirmation/cancelation/refund/?

# Stores

## Orders
  Holds all orders with state and details.
  Holds list of order search results

### Actions

  *ORDER_UPDATED order data*

  Push from the server with a new order. Updates all orders list.

  *ORDER_CLEANUP*

  Remove all expired orders from the all orders list

## Lists
  Holds all lists. A list contains the filters that will be used to search and can be either:

  - Live orders list using an attribute to filter orders and a sort order. Uses Orders Store to pull data.
  - Server Search Results list based on a specific query. Updates periodically.

### Actions

  - *CREATE_SEARCH_LIST* query
  - *CREATE_LIST* properties to be filtered
  - *REMOVE_LIST*

## Order
  - holds current selected order
  - events
  - actions
  - notifications

## User
  - holds user info
  - saves defined lists

## Searches
  - Customer (name, email, phone)
  - Delivery Address
  - Restaurant
  - Date (created, due) (interval)
  - Channel
  - Total
  - Payment Type
  - State

## Sort
  - Restaurant Open

## Search
  Dates
    - (not) in interval
    - date in days X
    - date after days X
    - date before days X
    - yesterday
    - today
    - tomorrow
    - this week
    - next week

# Ordering

Create UI Flow

- Given Channel CS
- Create Shopping User
- [opt] Find User & Login as it
- Find restaurant integration
  - By order date
  - By delivery address
  - By cuisine
  - By city & name
- Create cart with given restaurant data
- Take order type and time and address
- Add items to cart
- Set payment type and tips
- Checkout using payments api

appliesTo=all
appliesTo=any

Filters:

# contains
filters[0][field]=customer_name
filters[0][op]=~
filters[0][value]=contains

# not contains
filters[1][field]=customer_name
filters[1][op]=!~
filters[1][value]=not contains

# exact match
filters[2][field]=customer_name
filters[2][op]==
filters[2][value]=exact match

# begins with
filters[3][field]=customer_name
filters[3][op]=>
filters[3][value]=begins with

# ends with
filters[4][field]=customer_name
filters[4][op]=<
filters[4][value]=ends with

# not equal
filters[0][field]=order_type
filters[0][op]=!=
filters[0][value]=PICKUP

Time Filters

# between
filters[1][field]=time
filters[1][op]=<>
filters[1][start_date]=2015-05-25T21:00:00.427Z
filters[1][end_date]=2015-05-26T20:59:59.427Z

# after
filters[2][field]=time
filters[2][op]=>
filters[2][value]=2015-05-25T21:00:00.427Z

# before
filters[3][field]=time
filters[3][op]=<
filters[3][value]=2015-05-26T20:59:59.897Z

# not between
filters[5][field]=time
filters[5][op]=><
filters[5][start_date]=2015-05-25T21:00:00.427Z
filters[5][end_date]=2015-05-26T20:59:59.427Z

appliesTo=any

Fields:

customer_name
customer_email
customer_phone
delivery_address
order_type
restaurant
time
placed
channel
payment_type
order_state
# zuppler_bs4
