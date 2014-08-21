describe 'localStoragePrefix', ->
  describe 'when changed with $cachedResourceProvider.setLocalStoragePrefix()', ->
    beforeEach ->
      providerTest = angular.module 'providerTest', ['ngCachedResource']
      providerTest.config ['$cachedResourceProvider', ($cachedResourceProvider) ->
        $cachedResourceProvider.setLocalStoragePrefix "test://"
      ]
      module('providerTest')

    it "is used by to save all localStorage caches", ->
      inject ($injector) ->
        $cachedResource = $injector.get '$cachedResource'
        $httpBackend = $injector.get '$httpBackend'
        Apple = $cachedResource 'apple', '/apple/:id', {id: '@id'}

        Apple.$addToCache {id: '123'}
        expect(angular.fromJson(localStorage.getItem 'test://apple?id=123').value).to.deep.equal {id: '123'}
