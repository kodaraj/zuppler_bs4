define ['utils/trackSeenOrders'], (Tracker) ->
  describe 'Tracker', ->
    it 'returns # of new items', ->
      tracker = new Tracker
      expect(tracker.track([1,2,3]).lastChange).toEqual 3
      expect(tracker.track([1,2,4]).lastChange).toEqual 1

    it '#replace param', ->
      tracker = new Tracker
      expect(tracker.track([1,2,3], false).lastChange).toEqual 3
      expect(tracker.track([1,2,4], false).lastChange).toEqual 1
      expect(tracker.size()).toEqual 4
      expect(tracker.track([3, 4], false).lastChange).toEqual 0 # seen in first step

  describe 'just checking', ->
    it 'works for app', ->
      expect("works").toEqual 'works'
