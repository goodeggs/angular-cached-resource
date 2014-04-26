describe 'class with custom actions', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-with-custom-actions', '/mock/:id', {id: '@id'},
        charge:
          method: "PATCH"

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  it "has default actions", ->
    for action in ['get', 'query', 'save', 'remove', 'delete']
      expect( CachedResource ).to.have.property action

  it "has custom PATCH action", ->
    $httpBackend.expectPATCH('/mock/1', {id: 1, amount: '$77.00'}).respond 200
    expect( CachedResource ).to.have.property 'charge'
    CachedResource.charge id: 1, amount: '$77.00'
    $httpBackend.flush()

  describe 'resourceInstance', ->
    {resourceInstance} = {}

    beforeEach ->
      resourceInstance = new CachedResource id: 1, amount: '$77.00'

    it "has default actions", ->
      for action in ['$save', '$remove', '$delete']
        expect( resourceInstance ).to.have.property action

    it "has custom PATCH action", ->
      $httpBackend.expectPATCH('/mock/1', {id: 1, amount: '$77.00'}).respond 200
      expect( resourceInstance ).to.have.property '$charge'
      resourceInstance.$charge()
      $httpBackend.flush()
