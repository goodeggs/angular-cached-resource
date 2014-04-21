describe '$cachedResource.clearUndefined()', ->
  {$cachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'with two items in the cache, one without a corresponding resource class', ->

    beforeEach ->
      $httpBackend.whenGET('/monkey/donkey_kong').respond 200, {accessory: 'red tie', name: 'donkey_kong'}
      Monkey = $cachedResource "clear-undefined", "/monkey/:name", name: '@name'
      Monkey.get name: 'donkey_kong'
      $httpBackend.flush()
      localStorage.setItem 'cachedResource://lizard/kaptain_k_rool', { accessory: 'blunderbuss', type: 'lizard' }

    it 'clears the resource without the corresponding class', ->
      $cachedResource.clearUndefined()
      expect(localStorage.getItem 'cachedResource://lizard/kaptain_k_rool').to.not.be.ok
      expect(localStorage.length).to.equal 1
