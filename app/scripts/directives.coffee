'use strict'

# Generates UUIDs
uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length


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
      scope: true
      link: (scope, elm, attrs) ->
        title = attrs.stTitle
        elm.attr 'title', title
        elm.tooltip
          title: title
          container: 'body'
          placement: 'auto bottom'

        scope.$on '$destroy', () ->
          elm.tooltip 'destroy'
          return

        return
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
Typeahead directive
Allow to fetch and pick data based on typed characters.
###
angular.module('stones').
  directive 'stTypeahead', [
    '$parse',
    '$compile',
    ($parse, $compile) ->
      scope: true
      restrict: 'EA'
      require: ['stTypeahead', '^?ngModel']
      controller: [
        '$scope',
        '$element',
        '$attrs',
        '$transclude',
        (scope, elm, attrs, transcludeFn) ->
          @source = []
          @ngModel = null
          @dropdown = null
          @currentItem = null
          @selected = false
          @focused = false
          @mousedOver = false
          @allowNew = false
          @index = scope.$index
          @typedCounter = 0
          @sortFn = (a, b) =>
            if a.label > b.label
              return 1
            else if b.label > a.label
              return -1
            else
              return 0
          @selectFn = (value, index) => return

          # Set source to perform searches
          @setSource = (source) =>
            getLabel = (item) ->
              if attrs.stTypeaheadLabel?
                return item[attrs.stTypeaheadLabel]
              else if item.label?
                return item.label
              return item

            getValue = (item) ->
              if attrs.stTypeaheadValue?
                return item[attrs.stTypeaheadValue]
              else if item.value?
                return item.value
              return item

            @source = []

            if angular.isArray source
              for item in source
                @source.push
                  label: getLabel item
                  value: getValue item
            else if angular.isObject source
              for key, value of source
                @source.push
                  label: key
                  value: getValue value

            @matchItems()
            return

          # Find items according to typed characters
          @matchItems = (value) =>
            # Don't match anything if there aren't typed characters
            if @typedCounter is 0 then return

            if not value? or value is ''
              scope.stMatchedItems = @source
            else
              re = new RegExp value, 'i'
              scope.stMatchedItems = (item for item in @source when re.test item.label)
              @currentItem = (item for item in scope.stMatchedItems when item.label is value)

            scope.stMatchedItems.sort @sortFn
            @show()
            return

          # Propagate selection made
          @selectItem = (item_) =>
            item = if item_? then item_ else @currentItem

            if item?
              @currentItem = item
              @ngModel.$setViewValue item.label
              elm.val item.label
              @selectFn item.value, @index
            else
              if not @allowNew
                @currentItem = null
                @ngModel.$setViewValue ''
                elm.val ''
                @selectFn '', @index

            @hide()
            @typedCounter = 0
            return

          # Add or removes 'active' class to/from dropdown items
          @setItemClass = (item) =>
            if item is @currentItem
              return 'active'
            return

          # Go one item up
          @prev = () =>
            index = scope.stMatchedItems.indexOf @currentItem
            if index is (scope.stMatchedItems.length - 1) then index -= 1
            @currentItem = scope.stMatchedItems[index + 1]
            return

          # Go one item down
          @next = () =>
            index = scope.stMatchedItems.indexOf @currentItem
            if index is 0 then index += 1
            @currentItem = scope.stMatchedItems[index - 1]
            return

          # Hide dropdown
          @hide = () =>
            @dropdown.hide()
            return

          # Show dropdown
          @show = () =>
            if scope.stMatchedItems.length
              offset = elm.offset()
              offset.top += elm[0].offsetHeight + 2
              @dropdown.css 'top', offset.top
              @dropdown.css 'left', offset.left
              @dropdown.show()
            else
              @hide()
            return

          # Binding to keydown event
          @keydownFn = (e) =>
            switch e.keyCode
              when 9 then @selectItem()
              when 13
                e.preventDefault()
                @selectItem()
              when 38 then @next()
              when 40 then @prev()
              when 27 then @hide()
              else @typedCounter++
            scope.$apply()
            return

          # Binding to focus event
          @focusFn = (e) =>
            empty = e.currentTarget.value is ''
            if empty then @typedCounter++
            @focused = true
            @matchItems e.currentTarget.value
            scope.$apply()
            return

          # Binding to blur event
          @blurFn = (e) =>
            @focused = false
            if not @mousedOver then @hide()
            scope.$apply()
            return

          # Binding to mouseenter event
          @mouseenterFn = (e) =>
            @mousedOver = true
            @dropdown.find('li').removeClass 'active'
            scope.$apply()
            return

          # Binding to mouseleave event
          @mouseleaveFn = (e) =>
            @mousedOver = false
            index = scope.stMatchedItems.indexOf @currentItem
            if index isnt -1
              @dropdown.find('li').eq(index).addClass 'active'
            scope.$apply()
            return

          # Scope bindings
          scope.stSelectItem = @selectItem
          scope.stSetItemClass = @setItemClass

          # Add dropdown to DOM
          tplSimple = '
<ul class="typeahead dropdown-menu">
  <li ng-repeat="stItem in stMatchedItems" ng-click="stSelectItem(stItem)" ng-class="stSetItemClass(stItem)">
    <a href="#">{{ stItem.label }}</a>
  </li>
</ul>'
          tpl = tplSimple

          @dropdown = $compile(tpl)(scope)
          angular.element('body').append @dropdown
          @dropdown.bind 'mouseenter', @mouseenterFn
          @dropdown.bind 'mouseleave', @mouseleaveFn

          # Clear dropdown from DOM
          scope.$on '$destroy', (e) =>
            @dropdown.remove()
            return

          # Element events
          elm.bind 'keydown', @keydownFn
          elm.bind 'focus', @focusFn
          elm.bind 'blur', @blurFn

          return
        ]
      link: (scope, elm, attrs, ctrls, transcludeFn) ->
        stTypeaheadCtrl = ctrls[0]
        ngModel = ctrls[1]
        if not ngModel? or not stTypeaheadCtrl? then return

        stTypeaheadCtrl.ngModel = ngModel

        # Update view if model changes
        ngModel.$viewChangeListeners.push () ->
          stTypeaheadCtrl.matchItems ngModel.$viewValue
          return

        # set SelectFn and SortFn
        if $parse(attrs.stTypeaheadSelectFn)(scope)?
          stTypeaheadCtrl.selectFn = $parse(attrs.stTypeaheadSelectFn)(scope)
        if $parse(attrs.stTypeadeadSortFn)(scope)?
          stTypeaheadCtrl.sortFn = $parse(attrs.stTypeaheadSortFn)(scope)

        # Change source
        stTypeaheadCtrl.setSource $parse(attrs.stTypeahead) scope
        scope.$watchCollection attrs.stTypeahead, (value, old) =>
          if value? and value isnt old
            stTypeaheadCtrl.setSource value
          return

        return
  ]


###
Google Maps directive
Load a map inside element with custom properties.
###
angular.module('stones')
  .directive 'stGoogleMaps', [
    '$window',
    '$parse',
    ($window, $parse) ->
      restrict: 'EA'
      link: (scope, elm, attrs, ctrls, transcludeFn) ->
        google = $window.google
        if not google?
          throw 'stGoogleMapsError: Google Maps not loaded.'
        mapOpts = $parse(attrs.stGoogleMaps)(scope)
        if not mapOpts?
          throw 'stGoogleMapsError: no map options found.'

        scope.stMap = new google.maps.Map elm[0], mapOpts
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
      template: '
<div class="st-chunked-file-uploader clearfix">
  <div class="col-md-10">
    <div class="progress" ng-class="stProgressContainerClass()">
      <div class="progress-bar" role="progressbar" aria-valuenow="{{ stprogress }}" aria-valuemin="{{ stmin }}" aria-valuemax="{{ stmax }}" ng-style="stProgressStyle()" ng-class="stProgressClass()">{{ stprogress }}%</div>
      <div class="progress-bar" role="progressbar" aria-valuenow="{{ 100 - stprogress }}" aria-valuemin="{{ stmin }}" aria-valuemax="{{ stmax }}" ng-style="stInverseProgressStyle()" ng-class="stInverseProgressClass()">{{ stInverseProgressDisplay() }}</div>
    </div>
  </div>
  <div class="col-md-2">
    <span class="btn btn-default btn-xs">Subir</span>
  </div><input type="file" class="hidden">
</div>'
      link: (scope, _elm, attrs, ngModel) ->
        elm = $window.jQuery(_elm)
        upload_url = attrs.stChunkedFileUploader
        set_filename_func = $parse(attrs.stSetFilename)(scope)
        allowed_mime_pattern = new RegExp attrs.stAllowedMimetype, 'i'
        max_size = if attrs.stMaxSize then parseFloat(attrs.stMaxSize) else null
        scope.stprogress = 0
        scope.stmin = attrs.stMin ? 0
        scope.stmax = attrs.stMax ? 100

        if not angular.isFunction(set_filename_func)
          set_filename_func = () ->
            uniqueId 32

        file = null
        filename = null
        reader = new FileReader()
        chunk_size = (256 * 1024 * 4) * 1  # 1Mb
        start = 0
        stop = start + chunk_size - 1
        active = false

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
            blob = file.slice _start, _stop + 1

          reader.readAsDataURL blob

        reader.onloadend = (e) ->
          if e.target.readyState is FileReader.DONE
            stop_ = if stop < file.size then stop else file.size - 1
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
                start = stop + 1
                stop = start + chunk_size - 1
                readChunk start, stop
              else
                ngModel.$setViewValue data.url
                if scope.save? then scope.save()
                active = false
              return
          return

        fileSelectHandler = (e) ->
          e.stopPropagation()
          e.preventDefault()

          scope.stprogress = 0
          start = 0
          stop = start + chunk_size - 1
          active = true

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
        scope.stInverseProgressStyle = () ->
          width: "#{100 - scope.stprogress}%"

        scope.stProgressClass = () ->
          if scope.stprogress < 100
            return 'progress-bar-info'
          else
            return 'progress-bar-success'
        scope.stInverseProgressClass = () ->
          ret = ''
          if scope.stprogress is 0
            ret += ' progress-bar-danger'
          else
            ret += ' progress-bar-warning'
          ret
        scope.stProgressContainerClass = () ->
          ret = 'progress'
          if active then ret += ' progress-striped active'
          ret

        scope.stInverseProgressDisplay = () ->
          if scope.stprogress is 0
            return '0%'
          ''

        scope.$watch attrs.ngModel, (newValue, oldValue) ->
          if newValue?.length? and newValue.length > 0
            scope.stprogress = 100
          else
            scope.stprogress = 0
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
      require: 'stFileUploader'
      controller: [
        '$scope',
        '$element',
        '$attrs',
        '$transclude',
        (scope, elm, attrs, transcludeFn) ->
          @elm = $window.jQuery elm
          @getter = $parse(attrs.stFileUploader)
          @setter = @getter.assign
          input_tpl = '<input type="file" name="' + attrs.name + '" class="invisible" ' + (if attrs.required? then ' required' else '') + '>'
          input = $compile(input_tpl)(scope)

          dragOverHandler = (e) ->
            e.stopPropagation()
            e.preventDefault()
            e.dataTransfer.dropEffect = 'copy'
            return

          onFileLoad = (file) =>
            return (e) =>
              if attrs.stMimeType is 'image.*'
                if not file.type.match(attrs.stMimeType)
                  growl.addErrorMessage "File should be an image"
                  throw Error 'stFileUploaderError: File should be an image'
                @setter scope, e.target.result
                @elm.find('img').attr 'src', e.target.result
                @elm.find('.st-file-display-container').removeClass 'hidden'
                @elm.find('.st-file-control-container').addClass 'hidden'
              return

          selectFileHandler = (e) =>
            e.stopPropagation()
            e.preventDefault()
            file = if e.dataTransfer? then e.dataTransfer.files[0] else e.target.files[0]
            reader = new FileReader()

            reader.onload = onFileLoad file

            reader.readAsDataURL file
            return

          @change = (value, old) =>
            base64_pattern = /data:\w*\/.+;base64/i
            if not value? or value is '' or base64_pattern.test(value)
              @elm.find('img').removeAttr 'src'
              @elm.find('.st-file-display-container').addClass 'hidden'
              @elm.find('.st-file-control-container').removeClass 'hidden'
              return

            @elm.find('img').attr 'src', value
            @elm.find('.st-file-display-container').removeClass 'hidden'
            @elm.find('.st-file-control-container').addClass 'hidden'
            return

          buttonClick = (e) =>
            input.trigger 'click'
            return

          removeClick = (e) =>
            @setter scope, null
            return

          @init = () =>
            @elm.find('.st-file-control-container').append input
            @elm.css 'position', 'relative'
            @elm.css 'min-height', '130px'

            @elm.find('input[type=file]').bind 'change', (e) ->
              selectFileHandler e
            @elm.bind 'dragover', (e) ->
              dragOverHandler e.originalEvent
            @elm.bind 'drop', (e) ->
              selectFileHandler e.originalEvent

            button = elm.find('.btn').add('.st-file-uploader button')
            if button? then button.bind 'click', buttonClick

            @elm.find('.st-file-remove-overlay').bind('click', removeClick)
              .bind 'click', (e) ->
                elm.find('.st-file-control-container').removeClass 'hidden'
                elm.find('.st-file-display-container').addClass 'hidden'
                return

            return

          return
      ]
      scope: true
      replace: true
      template: (elm, attrs) ->
        tpl = '<div class="st-file-uploader"><div class="st-file-display-container hidden"><div class="st-file-remove-overlay"><i class="fa fa-times-circle"></i></div>';
        if elm[0].tagName is 'IMG'
          tpl += '<img class="img-responsive img-rounded" style="margin: auto;" />'
          attrs.$attr.stMimeType = 'st-mime-type'
          attrs.$set 'stMimeType', 'image.*'
        tpl += '</div><div class="st-file-control-container"><span class="btn btn-primary btn-sm">Selecciona</span><br />- o -<br />Arrastra aquí el archivo</div></div>'
      link: (scope, _elm, attrs, stFileUploaderCtrl, transcludeFn) ->
        isFileAPI = $window.File && $window.FileReader && $window.FileList && $window.Blob
        if not isFileAPI
          throw new Error 'FileAPI not supported'

        scope.$watch attrs.stFileUploader, (value, old) ->
          stFileUploaderCtrl.change value, old
          return

        stFileUploaderCtrl.init()
        return
  ]


###
Datepicker directive.
Allows to pick a date from a component.
###
angular.module('stones')
  .directive 'stDatepicker', [
    '$parse',
    ($parse) ->
      require: 'ngModel'
      restrict: 'EA',
      link: (scope, elm, attrs, ngModel, transcludeFn) ->
        elm.wrap '<div class="input-group"></div>'
        input_group = elm.parent()
        input_group.prepend '<span class="input-group-addon"><i class="fa fa-calendar"></i></span>'

        options = $parse(attrs.stDatepicker) scope
        angular.extend options,
          autoclose: true

        datepicker = elm.datepicker options

        ngModel.$parsers.push (value) ->
          moment(value, 'DD/MM/YYYY').utc()
        ngModel.$formatters.push (value) ->
          moment(value).utc().format 'DD/MM/YYYY'

        return
  ]
