describe 'resource instance returned by CachedResource.get', ->
  {CachedResource, $httpBackend, resourceInstance} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-test', '/mock/:id', {}, 
        save:
          method: "POST"

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  it "has default actions", ->
    for action in ['get', 'query']
      expect( CachedResource ).to.have.property action

  describe 'resourceInstance', ->
    beforeEach ->
      $httpBackend.expectGET('/mock/1').respond magic: 'Here is the response'
      resourceInstance = CachedResource.get id: 1
      $httpBackend.flush()

    it "has default actions", ->
      for action in ['$save', '$remove', '$delete']
        expect( resourceInstance ).to.have.property action

  it "binds custom actions", ->
    expect( CachedResource.charge ).to.be.defined
