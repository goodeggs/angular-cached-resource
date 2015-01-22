describe 'CachedResource.get array resource $push', ->
  {$httpBackend, CachedResource} = {}

  stringifyColorArray = (colors) ->
    (color.color for color in colors)

  colors = ->
    [
      { color: 'red', hex: '#FF0000' }
      { color: 'green', hex: '#00FF00' }
      { color: 'blue', hex: '#0000FF' }
      { color: 'papayawhip', hex: '#FFEFD5' }
    ]

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-get-array-test', '/colors/:color',
        color: '@color'

  describe 'a resolved resource collection', ->

    {resourceCollection} = {}

    beforeEach ->
      $httpBackend.expectGET('/colors').respond colors()
      resourceCollection = CachedResource.query()
      $httpBackend.flush()

    it 'contains individual cachedResource instances', ->
      expect(resourceCollection[i].$cache).to.be.true for i in [0...4]
      expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors())

    describe 'a newly created resource', ->
      {purple} = {}
      beforeEach ->
        purple = new CachedResource(color: 'purple', hex: '#FF00FF')

      describe 'when saved and pushed onto the collection', ->
        beforeEach ->
          $httpBackend.expectPOST('/colors/purple').respond 201
          purple.$save()
          $httpBackend.flush()
          resourceCollection.$push purple

        it 'adds the item to the collection', ->
          expect(resourceCollection.length).to.equal 5
          expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors()).concat('purple')

        describe 'a refetch when the connection is unavailable', ->
          beforeEach ->
            $httpBackend.expectGET('/colors').respond 500
            resourceCollection = CachedResource.query()
            $httpBackend.flush()

          it 'loads from the cache the newly $pushed resource with the collection', ->
            expect(resourceCollection.length).to.equal 5
            expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors()).concat('purple')

      describe 'when saved in an offline state and pushed onto the collection', ->
        beforeEach ->
          $httpBackend.expectPOST('/colors/purple').respond 500
          purple.$save()
          $httpBackend.flush()
          resourceCollection.$push purple

        describe 'a refetch when the connection is still unavailable', ->
          beforeEach ->
            $httpBackend.expectPOST('/colors/purple').respond 500 # the attempt to resave
            resourceCollection = CachedResource.query()
            $httpBackend.flush()

          it 'loads from the cache the newly $pushed resource with the collection', ->
            expect(resourceCollection.length).to.equal 5
            expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors()).concat('purple')

      describe 'when unsaved when pushed onto the collection', ->
        beforeEach ->
          resourceCollection.$push purple

        describe 'a refetch when the connection is unavailable', ->
          beforeEach ->
            $httpBackend.expectGET('/colors').respond 500
            resourceCollection = CachedResource.query()
            $httpBackend.flush()

          it 'loads from the cache the newly $pushed resource in the state at the time of the $push with the collection', ->
            expect(resourceCollection.length).to.equal 5
            expect(stringifyColorArray(resourceCollection)).to.eql stringifyColorArray(colors()).concat('purple')

      describe 'when saved, then edited and pushed onto the collection', ->
        beforeEach ->
          $httpBackend.expectPOST('/colors/purple').respond 201
          purple.$save()
          $httpBackend.flush()
          purple.hex = '#EE00EE'
          resourceCollection.$push purple

        describe 'a refetch when the connection is unavailable', ->
          beforeEach ->
            $httpBackend.expectGET('/colors').respond 500
            resourceCollection = CachedResource.query()
            $httpBackend.flush()

          it 'loads from the cache the newly $pushed resource in its last saved state with the collection', ->
            expect(resourceCollection.length).to.equal 5
            expect(resourceCollection[4].hex).to.equal '#FF00FF'
