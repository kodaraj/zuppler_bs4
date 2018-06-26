import userStore from 'stores/user'
import { curry, compose, map, assoc, reduce } from 'ramda'

 const OneSignal = window.OneSignal || [];
 OneSignal.push(["init", {
   appId: "559b9cb1-dda9-4f01-a5e6-4e89f536a9d1",
   autoRegister: false, /* Set to true to automatically prompt visitors */
   subdomainName: 'zuppler-customer-service',
   notifyButton: {
       enable: false /* Set to false to hide */
   }
 }]);

const makeTag = curry((prefix, id) => `${prefix}-${id}`)
const makeValTag = curry((prefix, val, id) => `${prefix}-${id}`)
const collectTags = (sum, tag) => assoc(tag, true, sum)

userStore.loggedIn.onValue( () =>
  OneSignal.push(() => {
    const aclRestaurantIds = userStore.acls().restaurants
    const userRoles = userStore.roles()
    let tags = {}

    if (userStore.hasAnyRole('restaurant', 'restaurant-staff', 'restaurant-admin')) {
      tags = reduce(collectTags, tags, map(makeTag("restaurant"), aclRestaurantIds))
    }

    if (userStore.hasAnyRole('config', 'customer-service', 'admin')) {
      tags = assoc('user_type', 'customer-service', tags)
    }

    tags = assoc('user_id', userStore.id(), tags)
    tags = assoc('user_name', userStore.name(), tags)
    tags = assoc('user_email', userStore.email(), tags)

    OneSignal.sendTags(tags)
  }))
