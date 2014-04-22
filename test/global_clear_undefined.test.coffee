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

  describe 'with an item corresponding to a resource in the cache', ->

    beforeEach ->
      $httpBackend.whenGET('/monkey/donkey_kong').respond 200, {accessory: 'red tie', name: 'donkey_kong'}
      Monkey = $cachedResource "monkey", "/monkey/:name", name: '@name'
      Monkey.get name: 'donkey_kong'
      $httpBackend.flush()

    describe 'and another item without a corresponding resource class', ->

      beforeEach ->
        localStorage.setItem 'cachedResource://lizard/kaptain_k_rool', { accessory: 'blunderbuss', type: 'lizard' }

      it 'clears the resource without the corresponding class', ->
        $cachedResource.clearUndefined()
        expect(localStorage.getItem 'cachedResource://lizard/kaptain_k_rool').to.not.be.ok
        expect(localStorage.length).to.equal 1

    describe 'and another similarly named item without a corresponding resource class', ->

      beforeEach ->
        localStorage.setItem 'cachedResource://monkey-food/banana', { color: 'yellow', type: 'fruit' }

      it 'clears the resource without the corresponding class', ->
        $cachedResource.clearUndefined()
        expect(localStorage.getItem 'cachedResource://monkey-food/banana').to.not.be.ok
        expect(localStorage.length).to.equal 1

