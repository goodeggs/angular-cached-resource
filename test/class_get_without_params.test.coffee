describe 'CachedResource.get without params', ->
  {$httpBackend, CachedResource} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource('class-paramless-test', '/monster')

  it 'should call the callback after it makes the initial request', (done) ->
    $httpBackend.expectGET('/monster').respond {sound: 'rarrrr'}
    CachedResource.get (response) ->
      expect(response.sound).to.equal 'rarrrr'
      done()
    $httpBackend.flush()

