# can we mock localStorage? if not (ie Firefox), this test is not gonna work...
localStorageIsMockable = do ->
  temp = window.localStorage.setItem
  window.localStorage.setItem = -> 'test'
  conditional = try
      window.localStorage.setItem() is 'test'
    catch
      false
  window.localStorage.setItem = temp
  conditional

conditionallyDescribe = if localStorageIsMockable then describe else xdescribe
conditionallyDescribe 'a full localStorage cache', ->
  {CachedResource, $httpBackend, $log} = {}

  beforeEach ->
    sinon.stub(window.localStorage, 'setItem').throws 'QuotaExceededError'
    inject ($injector) ->
      $log = $injector.get '$log'
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'full-local-storage-cache', '/mock/:id', id: '@id'

  afterEach ->
    window.localStorage.setItem.restore()

  it 'still succeeds at GET requests', ->
    $httpBackend.expectGET('/mock/42').respond question: 'The ultimate question of life, the universe, and everything'
    resourceInstance = CachedResource.get id: 42
    $httpBackend.flush()
    expect(resourceInstance.question).to.equal 'The ultimate question of life, the universe, and everything'

  it 'still succeeds at POST requests', ->
    $httpBackend.expectPOST('/mock/42', id: 42, player: 'Jackie Robinson').respond 200
    CachedResource.save {id: 42}, {id: 42, player: 'Jackie Robinson'}
    $httpBackend.flush()

  it 'logs an error on a failed write to localStorage', ->
    CachedResource.save {id: 42}, {id: 42, player: 'Jackie Robinson'}
    expect($log.error.logs[0][0]).to.contain "ngCachedResource"
    expect($log.error.logs[0][1]).to.contain "Failed to write to localStorage"
    expect($log.error.logs[0][2]).to.have.property 'key', 'cachedResource://full-local-storage-cache?id=42'
    expect($log.error.logs[0][2]).to.have.property 'value', '{"value":{"id":42,"player":"Jackie Robinson"},"dirty":true}'


