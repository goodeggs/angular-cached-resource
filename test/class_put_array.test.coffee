describe 'CachedResource.put array', ->
  {CachedResource, $httpBackend, $timeout, $log} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      $log = $injector.get '$log'
      CachedResource = $cachedResource 'Astronauts', '/astronauts/:name', {name: '@name'},
        putArray:
          isArray: true
          method: 'PUT'
    $log.reset()

  it 'updates the cache with the http response', ->
    response = CachedResource.putArray [
      {name: 'Buzz Aldrin'}
      {name: 'Neil Armstrong'}
    ]

    expect(JSON.parse localStorage.getItem('cachedResource://Astronauts?name=Buzz Aldrin')).to.have.deep.property 'value.name', 'Buzz Aldrin'
    expect(JSON.parse localStorage.getItem('cachedResource://Astronauts?name=Neil Armstrong')).to.have.deep.property 'value.name', 'Neil Armstrong'

    $httpBackend.expectPUT('/astronauts', [{name: 'Buzz Aldrin'},{name: 'Neil Armstrong'}]).respond 200, [
      {name: 'Buzz Aldrin', favoriteColor: 'blue'}
      {name: 'Neil Armstrong', favoriteColor: 'yellow'}
    ]

    $httpBackend.flush()

    expect(JSON.parse localStorage.getItem('cachedResource://Astronauts?name=Buzz Aldrin')).to.have.deep.property 'value.favoriteColor', 'blue'
    expect(JSON.parse localStorage.getItem('cachedResource://Astronauts?name=Neil Armstrong')).to.have.deep.property 'value.favoriteColor', 'yellow'
