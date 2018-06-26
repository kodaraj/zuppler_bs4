define ['stores/lists', 'immutable'], (lists, Immutable) ->
  describe 'lists', ->
    lastValue = null
    # it "should add to list", (done) ->
    #   lists.getAll().onValue (v) -> lastValue = v
    #   lists.addList('confirmed', {state: 'confirmed'})
    #   setTimeout ->
    #     expect(lastValue.count()).toBe 1
    #     done()
    #   , 0

    # Fails with no network
    # it "should have at least on order", (done) ->
    #   expect(lastValue).toBeDefined()
    #   count = 0
    #   lastValue.get(0).orders.onValue (orders) ->
    #     count = orders.length
    #   setTimeout ->
    #     expect(count).toBe 1
    #     done()
    #   , 1000

    # it "should remove by id", (done) ->
    #   lastList = null
    #   id = lastValue.get(0).id
    #   lists.getAll().onValue (v) -> lastList = v
    #   lists.removeList id
    #   setTimeout ->
    #     expect(lastList.count()).toBe 0
    #     done()
    #   , 0
