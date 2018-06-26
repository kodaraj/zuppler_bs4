resUtil = require 'utils/resources'

describe 'resources methods', ->
  it 'returns correct link for method', ->
    order = 
      links: [
        {
          name: "test"
          methods: ['get', 'post']
          url: 'test-url'
        },
        {
          name: "test"
          methods: ["special"]
          url: 'test-special-url'
        }
      ]
    expect(resUtil.findResourceLink(order, "test", "get")).toEqual "test-url"
    expect(resUtil.findResourceLink(order, "test", "post")).toEqual "test-url"
    expect(resUtil.findResourceLink(order, "test", "special")).toEqual "test-special-url"