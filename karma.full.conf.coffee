module.exports = (config) ->

  options =
    singleRun: yes

    frameworks: [
      'mocha'
      'sinon-chai'
    ]

    files: [
      'bower_components/angular/angular.js'
      'bower_components/angular-mocks/angular-mocks.js'
      'bower_components/angular-resource/angular-resource.js'

      'angular-cached-resource.js'

      'test/_config.coffee'
      'test/*.test.coffee'
    ]

    preprocessors:
      '**/*.coffee': ['coffee']

    browsers:
      if process.env.CI is 'true'
        [
          'PhantomJS'
        ]
      else
        [
          'PhantomJS'
          'Chrome'
          'Firefox'
#          'Safari'
        ]


  config.set options
