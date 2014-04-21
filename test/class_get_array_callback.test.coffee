describe 'CachedResource.get array resource collections with callback', ->
  {$httpBackend, CachedResource} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-array-callback-test', '/colors/:color',
        color: '@color'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  it 'only calls the callback once', ->
    $httpBackend.expectGET('/colors').respond [
      { color: 'red', hex: '#FF0000' }
      { color: 'green', hex: '#00FF00' }
      { color: 'blue', hex: '#0000FF' }
      { color: 'papayawhip', hex: '#FFEFD5' }
    ]

    callbackHitCount = 0
    CachedResource.query ->
      callbackHitCount++

    $httpBackend.flush()

    expect(callbackHitCount).to.equal 1
