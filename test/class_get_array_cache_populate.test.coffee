describe 'CachedResource.get cache population from an isArray request', ->
  {$httpBackend, CachedResource} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-array-test', '/colors/:color', {color: '@color'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'when cache is populated by a parameterless query', ->
    beforeEach ->
      $httpBackend.expectGET('/colors').respond [
        { color: 'darkorchid', hex: '#9932CC', cached: true }
        { color: 'lawngreen', hex: '#7CFC00', cached: true }
        { color: 'cornflowerblue', hex: '#6495ED', cached: true }
        { color: 'papayawhip', hex: '#FFEFD5', cached: true }
      ]
      CachedResource.query()
      $httpBackend.flush()

    describe 'making a request against a cached resource', ->
      {resourceInstance} = {}

      beforeEach ->
        $httpBackend.expectGET('/colors/lawngreen').respond 500
        resourceInstance = CachedResource.get color: 'lawngreen'

      it 'should immediately return values from the cache', ->
        expect(resourceInstance.hex).to.equal '#7CFC00'
        $httpBackend.flush()

  describe 'when cache is populated by a query with parameters', ->
    beforeEach ->
      $httpBackend.expectGET('/colors?set=limitedX11').respond [
        { color: 'darkorchid', hex: '#9932CC', cached: true }
        { color: 'lawngreen', hex: '#7CFC00', cached: true }
        { color: 'cornflowerblue', hex: '#6495ED', cached: true }
        { color: 'papayawhip', hex: '#FFEFD5', cached: true }
      ]
      CachedResource.query set: 'limitedX11'
      $httpBackend.flush()

    describe 'making a request against a cached resource', ->
      {resourceInstance} = {}

      beforeEach ->
        $httpBackend.expectGET('/colors/lawngreen').respond 500
        resourceInstance = CachedResource.get color: 'lawngreen'

      it 'should immediately return values from the cache', ->
        expect(resourceInstance.hex).to.equal '#7CFC00'
        $httpBackend.flush()

