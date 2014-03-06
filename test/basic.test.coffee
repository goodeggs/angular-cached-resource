describe 'cacheResource', ->
  {cacheResource} = {}

  beforeEach ->
    module('cached-resource')
    inject (_cacheResource_) ->
      cacheResource = _cacheResource_

  it 'wraps a resource', ->
    fakeResource =
      get: -> @getArgs = arguments
      query: -> @queryArgs = arguments

    cached = cacheResource(fakeResource)
    cached.get({_id: 1})

    expect(fakeResource.getArgs[0]).to.have.property '_id', 1
