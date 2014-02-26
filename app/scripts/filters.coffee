'use strict'

angular.module('stones')
  .filter 'stTriState', () ->
    (input) ->
      out = ''
      if input is true
        out += '<i class="fa fa-check-circle" style="color:green;"></i> '
      else if input is false
        out += '<i class="fa fa-times-circle" style="color:red;"></i> '
      else
        out += '<i class="fa fa-question-circle" style="color:yellow;"></i> '
      out
