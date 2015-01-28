describe 'CachedResource::toJSON', ->
  {resourceInstance, $q} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $q = $injector.get '$q'
      CachedResource = $cachedResource 'instance-toJSON-test', '/mock/:id', {id: '@id'}
      resourceInstance = new CachedResource
        id: 1
        notes: 'this is a saved note'
        list: [1,2,3]
        $promise: $q.defer()
        $httpPromise: $q.defer()


  it 'omits $promise and $httpPromise properties', ->
    expect(resourceInstance.toJSON()).to.deep.equal
      id: 1
      notes: 'this is a saved note'
      list: [1,2,3]

  it 'works with JSON.stringify()', ->
    expect(JSON.parse(JSON.stringify(resourceInstance))).to.deep.equal
      id: 1
      notes: 'this is a saved note'
      list: [1,2,3]

  it 'works with angular.toJson()', ->
    expect(JSON.parse(angular.toJson(resourceInstance))).to.deep.equal
      id: 1
      notes: 'this is a saved note'
      list: [1,2,3]
