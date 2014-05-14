describe 'resources with multiparameter urls', ->
  {$cachedResource, $httpBackend, resourceInstance} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'where the parameters all have bound defaults', ->
    {Plant} = {}

    beforeEach ->
      Plant = $cachedResource('resources-with-multiparameter-urls-bound', '/plants/:category/:name', {category: '@category', name: '@name'})

    it 'sends a GET request normally', ->
      $httpBackend.expectGET('/plants/carnivorous/pitcher_plant').respond 200, { category: 'carnivorous', name: 'pitcher_plant', family: 'Nepenthes' }
      plant = Plant.get category: 'carnivorous', name: 'pitcher_plant'
      $httpBackend.flush()
      expect(plant.family).to.equal 'Nepenthes'

  describe 'where some of the parameters are unbound', ->
    {Plant} = {}

    beforeEach ->
      Plant = $cachedResource('resources-with-multiparameter-urls-unbound', '/plants/:category/:name', {name: '@name'})

    it 'sends a POST request to the right URL', ->
      $httpBackend.expectPOST('/plants/carnivorous/pitcher_plant', { name: 'pitcher_plant', family: 'Nepenthes' }).respond 200
      Plant.save {category: 'carnivorous'}, { name: 'pitcher_plant', family: 'Nepenthes' }
      $httpBackend.flush()
