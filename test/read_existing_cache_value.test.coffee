describe 'Read existing cache value', ->
  {CachedResource, $httpBackend, $timeout} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'class-read-test', '/mock/:id', {id: '@id'}

  describe 'empty cache', ->
    describe 'query for array of resources', ->
      beforeEach ->
        $httpBackend.expectGET('/mock?type=foo').respond [
          {
            id: 1
            type: 'foo'
            value: 'bar'
          },
          {
            id: 2
            type: 'foo'
            value: 'baz'
          }
        ]

        CachedResource.query {type: 'foo'}
        $httpBackend.flush()

      it 'caches the array', ->
        expect(localStorage.getItem('cachedResource://class-read-test/array?type=foo')).to.contain 1

      it 'caches the individual resources', ->
        expect(localStorage.getItem('cachedResource://class-read-test?id=1')).to.contain 'bar'
        expect(localStorage.getItem('cachedResource://class-read-test?id=2')).to.contain 'baz'

