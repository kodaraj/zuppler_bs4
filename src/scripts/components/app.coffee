React = require 'react'
createReactClass = require 'create-react-class'
Layout = require 'views/layouts/sidebar'
PageHeader = require 'components/header'
uiStore = require 'stores/ui'
OrderPage = require 'views/order/order'
{ Route, Switch } = require 'react-router'
UserSettingsModal = require 'components/settings'
Welcome = require 'components/welcome'
PrivateRoute = require 'components/privateroute'
{ Grid, Col, Row, Button } = require 'reactstrap'
{ ListsIndex, CartsIndex } = require 'views/layouts/lists'
{ ListEditor, RdsListEditor } = require 'views/orders/editor'
Takeout = require 'views/orders/takeout'
Orders = require 'views/orders'
Reviews = require 'views/reviews'
RdsOrders = require 'views/rds_orders'
OrderTab = require 'views/order/order-tab'
CartView = require 'views/carts'
Sidebar = require 'views/sidebar'

Application = createReactClass

  renderSound: (soundName) ->
    id = "noise-service-#{soundName}"
    mp3 = "../sounds/#{soundName}.mp3"
    ogg = "../sounds/#{soundName}.ogg"
    <audio id={id}>
      <h1>Your browser does not support audio playback. Please try using Chrome or Firefox.</h1>
      <source key="mp3" src={mp3}/>
      <source key="ogg" src={ogg}/>
    </audio>

  render: ->
    <div>
      <PageHeader />
      <Route exact path="/hello" component={Welcome} />
      <PrivateRoute path="/settings" component={UserSettingsModal} />
      <Layout>
        <Switch>
          <Route exact path="/" component={Welcome} />
          <Route exact path="/lists/new" component={ListEditor} />
          <Route exact path="/lists" component={ListsIndex} />
          <Route exact path="/rds/new" component={RdsListEditor} />
          <Route exact path="/rds/:listId/edit" component={RdsListEditor} />
          <Route exact path="/lists/:listId/edit" component={ListEditor} />
          <Route exact path="/lists/:listId/takeout" component={Takeout} />
          <Route path="/lists/:listId/:order?/:orderId?" component={Orders} />
          <Route path="/rds/:listId/:order?/:orderId?" component={RdsOrders} />
          <Route path="/reviews/:selectorId/:order?/:orderId?" component={Reviews} />
          <Route exact path="/orders/:orderId" component={OrderTab} />
        </Switch>
      </Layout>
      <span>
        { @renderSound("notification") }
        { @renderSound("neworder") }
      </span>
    </div>

  renderRoutes: ->
    # <Route exact path="/carts" component={CartsIndex} />
    # <Route exact path="/carts/new" component={CartView} />
    # <Route exact path="/carts/:cartId" component={CartView} />
    null

module.exports = Application
