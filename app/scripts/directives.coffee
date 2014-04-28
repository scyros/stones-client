'use strict'

###
Pagination directive.
It uses Bootstrap pagination CSS classes.
###
angular.module('stones')
  .directive 'stPagination', [
    '$compile',
    '$timeout',
    ($compile, $timeout) ->
      template: '<ul class="pagination"><li ng-class="stGetStepDownClass()"><a href="#" ng-click="stStepDown()">&laquo;</a></li><li ng-repeat="step in stSteps" ng-class="stGetStepClass(step)"><a href="#" ng-click="stGoStep(step)">{{ step }}</a></li><li ng-class="stGetStepUpClass()"><a href="#" ng-click="stStepUp()">&raquo;</a></li></ul>'
      link: (scope, elm, attrs) ->
        scope.stSteps = []

        scope.$watch 'total_pages', () ->
          scope.stSteps = (n for n in [1..scope.total_pages])
        scope.$watch 'stSteps', () ->
          $timeout () ->
            elm.find('a')
              .bind 'click', (e) ->
                e.preventDefault()
                false
              return
          , 500
          return

        scope.stGetStepDownClass = () ->
          ###
          Sets previous button class
          ###
          cls = []
          if scope.current_page >= 1 then cls.push 'disabled'
          return cls

        scope.stGetStepUpClass = () ->
          ###
          Sets next button class
          ###
          cls = []
          if scope.current_page <= scope.total_pages then cls.push 'disabled'
          return cls

        scope.stGetStepClass = (step) ->
          ###
          Sets disabled and active classes according to current step
          ###
          cls = []
          if step is scope.current_page
            cls.push 'active'
          return cls

        scope.stStepDown = () ->
          ###
          Go one step down
          ###
          if scope.current_page > 1 then scope.current_page--

        scope.stStepUp = () ->
          ###
          Go one step up
          ###
          if scope.current_page < scope.total_pages then scope.current_page++

        scope.stGoStep = (step) ->
          ###
          Go to one specific step
          ###
          if step > 1 and step < scope.total_pages
            scope.current_page = step
    ]

###
Tooltip directive.
It uses Bootstrap tooltip.
###
angular.module('stones')
  .directive 'stTitle', [
    '$compile',
    ($compile) ->
      restrict: 'A'
      link: (scope, elm, attrs) ->
        title = attrs.stTitle
        elm.attr 'title', title
        elm.tooltip
          title: title
          container: 'body'
          placement: 'auto bottom'
  ]

###
100% height directive.
Sets box height to the maximum possible within body bounds.
###
angular.module('stones')
  .directive 'stHeight100', [
    () ->
      restrict: 'A'
      link: (scope, _elm, attrs) ->
        elm = $(_elm)
        body_height = $('body').height()
        top = elm.offset().top
        height = body_height - top
        elm.height(height)
  ]

###
No navigation directive.
Prevents anchor default behavior.
It prevents from follow links in all anchors inside element where the directive
has been declarated.
If that element is an anchor itself, its behavior is modified.
###
angular.module('stones')
  .directive 'stNoNav', [
    () ->
      restrict: 'A'
      link: (scope, _elm, attrs) ->
        elm = $(_elm)
        if elm.prop('tagName').toLowerCase() is 'a'
          elm.bind 'click', (e) ->
            e.preventDefault()
        else
          elm.find('a').bind 'click', (e) ->
            e.preventDefault()
  ]

###
Spy directives.
Allows DOM movement accordingly with sections positions.
Inspired in: https://gist.github.com/alxhill/6886760
###
angular.module('stones')
  .directive 'stSpy', [
    '$window',
    ($window) ->
      restrict: 'A'
      require: '^stScrollSpy'
      link: (scope, elm, attrs, stScrollSpy) ->
        speed = attrs.stSpeed ? 1500
        stScrollSpy.addSpy
          id: attrs.stSpy
          in: -> elm.addClass 'active'
          out: -> elm.removeClass 'active'

        elm.bind 'click', (e) ->
          $('html, body').animate
            scrollTop: $('#' + attrs.stSpy).offset().top
          , speed
  ]

angular.module('stones')
  .directive 'stScrollSpy', [
    '$window',
    ($window) ->
      restrict: 'A'
      controller: [
        '$scope',
        (scope) ->
          scope.spies = []
          @addSpy = (spyObj) -> scope.spies.push spyObj
          return
      ]
      link: (scope, elm, attrs) ->
        spyElems = []

        scope.$watch 'spies', (spies) ->
          for spy in spies
            unless spyElems[spy.id]?
              spyElems[spy.id] = $('#' + spy.id)

        $($window).scroll ->
          highlightSpy = null
          for spy in scope.spies
            spy.out()

            # the elem might not have been available when it was originally cached,
            # so we check again to get another element in case this one doesn't exist.
            spyElems[spy.id] =
              if spyElems[spy.id].length is 0
                $('#' + spy.id)
              else
                spyElems[spy.id]

            # the element could still not exist, so we check first to avoid errors
            if spyElems[spy.id].length isnt 0
              if (pos = spyElems[spy.id].offset().top) - $window.scrollY <= 0
                spy.pos = pos
                highlightSpy ?= spy
                if highlightSpy.pos < spy.pos
                  highlightSpy = spy

          highlightSpy?.in()
  ]

###
File control directive.
Allow uploads.
###
angular.module('stones').
  directive 'stFileUploader', [
    '$window',
    '$compile',
    '$http',
    '$parse',
    'growl',
    ($window, $compile, $http, $parse, growl) ->
      restrict: 'EA',
      scope: true,
      replace: true,
      template: (elm, attrs) ->
        tpl = '<div class="st-file-uploader"><div class="st-file-display-container hidden"><div class="st-file-remove-overlay"><i class="fa fa-times-circle"></i></div>';
        if elm[0].tagName is 'IMG'
          tpl += '<img class="img-responsive img-rounded" />'
          attrs.$attr.stMimeType = 'st-mime-type'
          attrs.$set 'stMimeType', 'image.*'
        tpl += '</div><div class="st-file-control-container"><span class="btn btn-primary btn-sm">Selecciona</span><br />- o -<br />Arrastra aquí el archivo</div></div>'
        return tpl;
      link: (scope, _elm, attrs) ->
        isFileAPI = $window.File && $window.FileReader && $window.FileList && $window.Blob
        if not isFileAPI
          throw new Error 'FileAPI not supported'

        getter = $parse(attrs.stFileUploader)
        setter = getter.assign
        input_tpl = '<input type="file" name="' + attrs.name + '" class="invisible" ' + (if attrs.required? then ' required' else '') + '>'
        input = $compile(input_tpl)(scope)
        elm = $window.jQuery(_elm)
        elm.find('.st-file-control-container').append input
        elm.css 'position', 'relative'
        elm.css 'min-height', '130px'

        button = elm.find('.btn')
          .add('.st-file-uploader button')
        if button
          button.bind 'click', (e) ->
            input.trigger 'click'
            return

        elm.find('.st-file-remove-overlay').bind 'click', (e) ->
          setter scope, null
          elm.find('.st-file-control-container').removeClass 'hidden'
          elm.find('.st-file-display-container').addClass 'hidden'
          scope.$apply()

        fileSelectHandler = (e) ->
          e.stopPropagation()
          e.preventDefault()

          file = if e.dataTransfer? then e.dataTransfer.files[0] else e.target.files[0]
          reader = new FileReader()

          reader.onload = (e) ->
            if attrs.stMimeType is 'image.*'
              if not file.type.match(attrs.stMimeType)
                growl.addErrorMessage "File should be an image"
                throw Error 'stFileUploaderError: File should be an image'
              setter(scope, e.target.result)
              elm.find('img').attr 'src', e.target.result
              elm.find('.st-file-display-container').removeClass 'hidden'
              elm.find('.st-file-control-container').addClass 'hidden'
            scope.$apply()
            return

          reader.readAsDataURL(file)
          return

        fileDragOverHandler = (e) ->
          e.stopPropagation()
          e.preventDefault()
          e.dataTransfer.dropEffect = 'copy'
          return

        elm.find('input[type=file]').bind 'change', (e) ->
          fileSelectHandler(e)
        elm.bind 'dragover', (e) ->
          fileDragOverHandler(e.originalEvent)
        elm.bind 'drop', (e) ->
          fileSelectHandler(e.originalEvent)

        scope.$watch attrs.stFileUploader, (newValue, oldValue) ->
          base64_pattern = /data:\w*\/.+;base64/i
          if not newValue? or base64_pattern.test(newValue)
            if attrs.stMimeType is 'image.*'
              elm.find('img').removeAttr 'src'
              elm.find('.st-file-display-container').addClass 'hidden'
              elm.find('.st-file-control-container').removeClass 'hidden'
            return

          http_request = $http.get '/get_blob/' + newValue, cache: true
          http_request.success (data) ->
            if attrs.stMimeType is 'image.*'
              elm.find('img').attr 'src', data
              elm.find('.st-file-display-container').removeClass 'hidden'
              elm.find('.st-file-control-container').addClass 'hidden'
            return
          http_request.error (data) ->
            if attrs.stMimeType is 'image.*'
              elm.find('img').removeAttr 'src'
              elm.find('.st-file-display-container').addClass 'hidden'
              elm.find('.st-file-control-container').removeClass 'hidden'
            return

          return

        return
  ]

###
File control directive.
Allow chunked uploads.
###
angular.module('stones').
  directive 'stChunkedFileUploader', [
    '$window',
    '$compile',
    '$http',
    '$parse',
    'growl',
    ($window, $compile, $http, $parse, growl) ->
      restrict: 'EA'
      require: 'ngModel'
      scope: true
      replace: true
      template: '<div class="st-chunked-file-uploader clearfix"><div class="col-md-10"><div class="progress"><div class="progress-bar" role="progressbar" aria-valuenow="{{ stprogress }}" aria-valuemin="{{ stmin }}" aria-valuemax="{{ stmax }}" ng-style="stProgressStyle()" ng-class="stProgressClass()">{{ stprogress }}%</div></div></div><div class="col-md-2"><span class="btn btn-default btn-xs">Subir</span></div><input type="file" class="hidden"></div>'
      link: (scope, _elm, attrs, ngModel) ->
        elm = $window.jQuery(_elm)
        upload_url = attrs.stChunkedFileUploader
        set_filename_func = $parse(attrs.stSetFilename)
        allowed_mime_pattern = new RegExp attrs.stAllowedMimetype, 'i'
        max_size = if attrs.stMaxSize then parseFloat(attrs.stMaxSize) else null
        scope.stprogress = 0
        scope.stmin = attrs.stMin ? 0
        scope.stmax = attrs.stMax ? 100

        if angular.isFunction(set_filename_func(scope))
          set_filename_func = set_filename_func(scope)
        else
          set_filename_func = () ->
            uniqueId 32

        file = null
        filename = null
        reader = new FileReader()
        chunk_size = (256 * 1024 * 4) * 2  # 2Mb
        start = 0
        stop = start + chunk_size - 1

        input = elm.find('input[type=file]')
        button = elm.find('.btn')
        if button
          button.bind 'click', (e) ->
            input.trigger 'click'
            return

        readChunk = (_start, _stop) ->
          if file.webkitSlice?
            blob = file.webkitSlice _start, _stop
          else if file.mozSlice?
            blob = file.mozSlice _start, _stop
          else
            blob = file.slice _start, _stop

          reader.readAsDataURL blob

        reader.onloadend = (e) ->
          if e.target.readyState is FileReader.DONE
            stop_ = if stop < file.size then stop else file.size
            stop_ -= 1
            content = e.target.result.split(',')[1]
            config =
              url: upload_url
              method: 'POST'
              headers:
                'Content-Range': "bytes #{start}-#{stop_}/#{file.size}"
                'Content-Type': "#{file.type}"
              params:
                filename: filename
              data: content

            if start > 0 then config.method = 'PUT'

            upload_request = $http config
            upload_request.success (data) ->
              scope.stprogress = Math.floor((stop_ + 1) / file.size * 100)
              if stop < file.size
                start = stop
                stop = start + chunk_size
                readChunk start, stop
              else
                ngModel.$setViewValue data.key
                if scope.save? then scope.save()
              return
          return

        fileSelectHandler = (e) ->
          e.stopPropagation()
          e.preventDefault()

          start = 0
          stop = start + chunk_size - 1

          file = if e.dataTransfer? then e.dataTransfer.files[0] else e.target.files[0]
          if not allowed_mime_pattern.test file.type
            growl.addErrorMessage "StFileUploaderError: #{file.type} mimetype not allowed."
            throw new Error "StFileUploaderError: #{file.type} mimetype not allowed."
          else if max_size and file.size > max_size
            growl.addErrorMessage "StFileUploaderError: #{file.name} is bigger than permitted."
            throw new Error "StFileUploaderError: #{file.name} is bigger than permitted."

          filename = set_filename_func()
          readChunk start, stop
          return

        fileDragOverHandler = (e) ->
          e.stopPropagation()
          e.preventDefault()
          e.dataTransfer.dropEffect = 'copy'
          return

        elm.find('input[type=file]').bind 'change', (e) ->
          fileSelectHandler(e)
        elm.bind 'dragover', (e) ->
          fileDragOverHandler(e.originalEvent)
        elm.bind 'drop', (e) ->
          fileSelectHandler(e.originalEvent)

        scope.stProgressStyle = () ->
          width: "#{scope.stprogress}%"

        scope.stProgressClass = () ->
          if scope.stprogress < 100
            return 'progress-bar-warning'
          else
            return 'progress-bar-success'

        scope.$watch attrs.ngModel, (newValue, oldValue) ->
          if newValue?.length? and newValue.length > 0
            scope.stprogress = 100
          else
            scope.stprogress = 0
  ]
