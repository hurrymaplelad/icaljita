###
@fileoverview
Boolean operators.

@author mikesamuel@gmail.com
@author adam@hmlad.com 
- Node/Coffeescript port
###

module.exports =

  ALWAYS_TRUE: -> true

  'and': (predicates) ->
    predicates = predicates.slice(0)
    (v) ->
      for p in predicates
        return false unless p(v)
      true

  'or': (predicates) ->
    predicates = predicates.slice(0)
    (v) ->
      for p in predicates
        return true if p(v)
      false

  'not': (predicate) ->
    (v) -> not predicate(v)
