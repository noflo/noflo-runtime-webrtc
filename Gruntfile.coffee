module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'runtime/*.js']
      tasks: ['test']

    # Browser verison building
    noflo_browser:
      build:
        files:
          'browser/noflo-runtime-webrtc.js': ['component.json']

    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'
      runtime:
        options:
          bare: true
        expand: true
        cwd: 'runtime'
        src: ['**.coffee']
        dest: 'runtime'
        ext: '.js'

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['test/*.js']
        options:
          reporter: 'spec'
          require: 'coffee-script/register'

    # Web server for the browser tests
    connect:
      server:
        options:
          port: 8000

    # BDD tests on browser
    mocha_phantomjs:
      all:
        options:
          output: 'spec/result.xml'
          reporter: 'spec'
          urls: ['http://localhost:8000/spec/runner.html']
          failWithOutput: true

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-noflo-browser'

  @registerTask 'build', ['coffee', 'noflo_browser']
  @registerTask 'test', ['build', 'mochaTest', 'connect', 'mocha_phantomjs']
  @registerTask 'default', ['test']
