describe '$cachedResource.clear()', ->
  {$cachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  describe 'with a populated cache', ->

    beforeEach ->
      for category, example of {animal: 'cuttlefish', vegetable: 'romanesco', mineral: 'gneiss'}
        $httpBackend.whenGET(///^\/#{category}///).respond 200, {example}
        CachedResource = $cachedResource "clearing-cache-#{category}", "/#{category}/:id", id: '@id'
        for i in [0..5]
          CachedResource.get id: i
          $httpBackend.flush()

    it 'removes all cache entries', ->
      $cachedResource.clear()
      expect(localStorage.length).to.equal 0

    describe 'and something else in localStorage', ->

      beforeEach ->
        localStorage.setItem('shoop', 'de whoop')

      it 'leaves unrelated localStorage entries alone', ->
        $cachedResource.clear()
        expect(localStorage.getItem('shoop')).to.equal 'de whoop'
