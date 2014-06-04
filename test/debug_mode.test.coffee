describe 'debug mode', ->
  {$cachedResourceProvider, $cachedResource, $log} = {}

  describe 'enabled', ->
    beforeEach ->
      providerTest = angular.module 'providerTest', ['ngCachedResource']
      providerTest.config ['$cachedResourceProvider', (provider) ->
        $cachedResourceProvider = provider
        $cachedResourceProvider.setDebugMode()
      ]

      module('ngCachedResource', 'providerTest')
      inject ($injector) ->
        $cachedResource = $injector.get '$cachedResource'
        $log  = $injector.get '$log'

    afterEach ->
      $log.reset()

    it 'should output a log', ->
      $cachedResource('debug-mode-test', '/test/:id', {id: '@id'})
      expect($log.debug.logs.length).to.be.gt 0

  describe 'disabled', ->
    beforeEach ->
      providerTest = angular.module 'providerTest', ['ngCachedResource']
      providerTest.config ['$cachedResourceProvider', (provider) ->
        $cachedResourceProvider = provider
        $cachedResourceProvider.setDebugMode off
      ]

      module('ngCachedResource', 'providerTest')
      inject ($injector) ->
        $cachedResource = $injector.get '$cachedResource'
        $log  = $injector.get '$log'

    afterEach ->
      $log.reset()

    it 'should output a log', ->
      $cachedResource('debug-mode-test', '/test/:id', {id: '@id'})
      $log.assertEmpty()
