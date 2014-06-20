describe 'bound params do not match array response', ->
  {villains, $httpBackend, $log} = {}

  beforeEach ->
    module 'ngCachedResource'
    inject ($injector) ->
      $log = $injector.get '$log'
      $httpBackend = $injector.get '$httpBackend'
      $cachedResource = $injector.get '$cachedResource'
      Villain = $cachedResource('villain', '/villain/:name', { name: '@name'})
      villains = Villain.query()

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()
    $log.reset()

  it 'should display a warning message', ->
    $httpBackend.expectGET('/villain').respond [
      { name: 'Dracula', powers: ['Superhuman strength', 'Immortality', 'Shapeshifting'], weakness: 'Decapitation' }
      { nickname: 'You-Know-Who', powers: ['Magic', 'Flight', 'Parcelmouth'], weakness: 'Killing curse' }
    ]
    $httpBackend.flush()
    expect($log.error.logs.length).to.equal 1
    expect($log.error.logs[0][0]).to.equal 'ngCachedResource'
    expect($log.error.logs[0][1]).to.contain 'boundParams'
