describe 'CachedResource.get cache population from an isArray request', ->
  {$httpBackend, CachedResource} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-array-test', '/colors/:color', {color: '@color'}

    $httpBackend.expectGET('/colors').respond [
      { color: 'red', hex: '#FF0000', cached: true }
      { color: 'green', hex: '#00FF00', cached: true }
      { color: 'blue', hex: '#0000FF', cached: true }
      { color: 'papayawhip', hex: '#FFEFD5', cached: true }
    ]
    CachedResource.query()
    $httpBackend.flush()

  describe 'making a request against a cached resource', ->
    {resourceInstance} = {}

    beforeEach ->
      $httpBackend.expectGET('/colors/green').respond 500
      resourceInstance = CachedResource.get color: 'green'

    it 'should immediately return values from the cache', ->
      expect(resourceInstance.hex).to.equal '#00FF00'
      $httpBackend.flush()
