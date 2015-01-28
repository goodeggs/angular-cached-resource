describe 'adding resources to cache', ->

  {Computer, $httpBackend, $q} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $q = $injector.get '$q'
      $httpBackend = $injector.get '$httpBackend'
      Computer = $cachedResource 'computer', '/computer/:sn', {sn: '@sn'},

  describe 'with a class method', ->

    describe '$addToCache', ->
      it 'adds', ->
        Computer.$addToCache {sn: '12-23921-FF2', name: 'HOLMES IV'}
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=12-23921-FF2').value).to.deep.equal {sn: '12-23921-FF2', name: 'HOLMES IV'}

      it 'does not add $promise and $httpPromise properties to localStorage', ->
        Computer.$addToCache {sn: '12-23921-FF2', name: 'HOLMES IV', $promise: $q.defer(), $httpPromise: $q.defer()}
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=12-23921-FF2').value).to.deep.equal {sn: '12-23921-FF2', name: 'HOLMES IV'}

    describe '$addArrayToCache', ->

      it 'adds', ->
        Computer.$addArrayToCache {type: 'megalomaniacal'}, [{sn: '983-0912992-CCTV', name: 'GERTY 3000'}, {sn: 'dead-4beef', name: 'HAL 9000'}]
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer/array?type=megalomaniacal').value).to.deep.equal [{sn: '983-0912992-CCTV'}, {sn: 'dead-4beef'}]
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=983-0912992-CCTV').value).to.deep.equal {sn: '983-0912992-CCTV', name: 'GERTY 3000'}
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=dead-4beef').value).to.deep.equal {sn: 'dead-4beef', name: 'HAL 9000'}

      it 'does not add $promise and $httpPromise properties to localStorage', ->
        computers = [
          {sn: '983-0912992-CCTV', name: 'GERTY 3000', $promise: $q.defer(), $httpPromise: $q.defer()}
          {sn: 'dead-4beef', name: 'HAL 9000', $promise: $q.defer(), $httpPromise: $q.defer()}
        ]
        Computer.$addArrayToCache {type: 'megalomaniacal'}, computers
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer/array?type=megalomaniacal').value).to.deep.equal [{sn: '983-0912992-CCTV'}, {sn: 'dead-4beef'}]
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=983-0912992-CCTV').value).to.deep.equal {sn: '983-0912992-CCTV', name: 'GERTY 3000'}
        expect(angular.fromJson(localStorage.getItem 'cachedResource://computer?sn=dead-4beef').value).to.deep.equal {sn: 'dead-4beef', name: 'HAL 9000'}


  describe 'with an instance method', ->
    {computer} = {}

    beforeEach ->
      computer = new Computer {sn: '424242-42424242', name: 'Deep Thought'}

    it 'has an $$addToCache method', ->
      computer.$$addToCache()
      expect(angular.fromJson(localStorage.getItem('cachedResource://computer?sn=424242-42424242')).value).to.deep.equal {sn: '424242-42424242', name: 'Deep Thought'}

    it 'does not add $promise and $httpPromise properties to localStorage', ->
      computer.$promise = $q.defer()
      computer.$httpPromise = $q.defer()
      computer.$$addToCache()
      expect(angular.fromJson(localStorage.getItem('cachedResource://computer?sn=424242-42424242')).value).to.deep.equal {sn: '424242-42424242', name: 'Deep Thought'}

