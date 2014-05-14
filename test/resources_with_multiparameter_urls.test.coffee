describe 'resources with multiparameter urls', ->
  {CachedResource, $httpBackend, resourceInstance} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource('resources-with-multiparameter-urls', '/plants/:category/:name', {category: '@category', name: '@name'})

  it 'sends a GET request normally', ->
    $httpBackend.expectGET('/plants/carnivorous/pitcher_plant').respond 200, { category: 'carnivorous', name: 'pitcher_plant', family: 'Nepenthes' }
    plant = CachedResource.get category: 'carnivorous', name: 'pitcher_plant'
    $httpBackend.flush()
    expect(plant.family).to.equal 'Nepenthes'
