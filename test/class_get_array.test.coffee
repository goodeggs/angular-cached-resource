describe 'CachedResource.get array resource collections', ->
  {$httpBackend, CachedResource, resourceCollection} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-array-test', '/colors/:color',
        color: '@color'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'when cache is empty', ->

    expectSuccessfulGET = ->
      $httpBackend.expectGET('/colors').respond [
        { color: 'red', hex: '#FF0000' }
        { color: 'green', hex: '#00FF00' }
        { color: 'blue', hex: '#0000FF' }
        { color: 'papayawhip', hex: '#FFEFD5' }
      ]

    expectFailingGET = ->
      $httpBackend.expectGET('/colors').respond 500

    beforeEach ->
      resourceCollection = CachedResource.query()

    describe 'have a $promise that', ->
      {$promise} = {}

      beforeEach ->
        expect(resourceCollection).to.have.property '$promise'
        {$promise} = resourceCollection

      it 'resolves when the request is complete', (done) ->
        expectSuccessfulGET()
        resourceCollection.$promise.then ->
          expect(resourceCollection.length).to.equal 4
          done()
        $httpBackend.flush()

    describe 'have an $httpPromise that', ->
      {$httpPromise} = {}

      beforeEach =>
        expect(resourceCollection).to.have.property '$httpPromise'
        {$httpPromise} = resourceCollection

      it 'resolves when the request is complete', (done) ->
        expectSuccessfulGET()
        resourceCollection.$promise.then ->
          expect(resourceCollection.length).to.equal 4
          done()
        $httpBackend.flush()

      it 'is rejected when the request fails', (done) ->
        expectFailingGET()
        resourceCollection.$promise.catch (error) ->
          expect(error.status).to.equal 500
          done()
        $httpBackend.flush()

  describe 'when cache is full', ->
    stringifyColorArray = (colors) -> colors.map((c) -> c.color).toString()
    colors = [
        { color: 'red', hex: '#FF0000' }
        { color: 'green', hex: '#00FF00' }
        { color: 'blue', hex: '#0000FF' }
        { color: 'papayawhip', hex: '#FFEFD5' }
      ]

    beforeEach ->
      $httpBackend.expectGET('/colors').respond colors
      CachedResource.query()
      $httpBackend.flush()

    describe 'and connection is unavailable', ->
      beforeEach ->
        $httpBackend.expectGET('/colors').respond 500
        resourceCollection = CachedResource.query()

      it 'immediately contains data from the cache', ->

        expect(resourceCollection.length).to.equal 4
        expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors)
        $httpBackend.flush()

      it 'has a $promise that is immediately resolved with the cached data', (done) ->
        resourceCollection.$promise.then (data) ->
          expect(data.length).to.equal 4
          expect(stringifyColorArray(data)).to.eql stringifyColorArray(colors)
          done()
        $httpBackend.flush()

      it 'has an $httpPromise that gets rejected', (done) ->
        resourceCollection.$httpPromise.catch (error) ->
          expect(error.status).to.equal 500
          done()
        $httpBackend.flush()

    describe 'and connection is available', ->
      beforeEach ->
        $httpBackend.expectGET('/colors').respond [
          { color: 'burlywood', hex: '#DEB887' }
          { color: 'honeydew', hex: '#F0FFF0' }
        ]
        resourceCollection = CachedResource.query()

      it 'immediately contains data from the cache', ->
        expect(resourceCollection.length).to.equal 4
        expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors)
        $httpBackend.flush()

      it 'has a $promise that immediately resolves with the cached data', (done) ->
        resourceCollection.$promise.then (data) ->
          expect(data.length).to.equal 4
          expect(stringifyColorArray(data)).to.eql stringifyColorArray(colors)
          done()
        $httpBackend.flush()

      it 'has an $httpPromise that resolves with the new data', (done) ->
        resourceCollection.$httpPromise.then (data) ->
          expect(data.length).to.equal 2
          done()
        $httpBackend.flush()

      it 'updates the object in memory after an HTTP request is made', ->
        $httpBackend.flush()
        expect(resourceCollection.length).to.equal 2

