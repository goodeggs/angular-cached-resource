describe 'adding resources to cache', ->

  {Computer, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      Computer = $cachedResource 'computer', '/computer/:sn', {sn: '@sn'},

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'with a class method', ->

    it '$addToCache', ->
      Computer.$addToCache {sn: '12-23921-FF2', type: 'HOLMES IV'}
      item = localStorage.getItem('cachedResource://computer?sn=12-23921-FF2')
      expect(angular.fromJson(item).value).to.deep.equal {sn: '12-23921-FF2', type: 'HOLMES IV'}

  describe 'with an instance method', ->
    {computer} = {}

    beforeEach ->
      computer = new Computer {sn: '983-0912992-CCTV', type: 'GERTY 3000'}
      computer.$$addToCache()
      expect(anglar.fromJson(localStorage.getItem('cachedResource://computer?sn=983-0912992-CCTV')).value).to.deep.equal {sn: '983-0912992-CCTV', type: 'GERTY 3000'}
