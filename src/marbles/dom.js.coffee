#= require ../polyfills/querySelector
#= require_self
#= require ./dom/input_selection

Marbles.DOM = DOM = {
  querySelector: (selector, el) -> (el || document).querySelector(selector)
  querySelectorAll: (selector, el) -> (el || document).querySelectorAll(selector)

  match: (el, selector) ->
    return unless el
    _.any @querySelectorAll(selector, el.parentNode), (_el) => _el == el

  attr: (el, name) ->
    return unless el
    el.attributes?.getNamedItem(name)?.value

  replaceChildren: (el, new_children...) ->
    for child in el.childNodes
      el.removeChild(child)

    for child in new_children
      el.appendChild(child)

    el

  replaceWithHTML: (el, html) ->
    tmp_el = document.createElement('div')
    tmp_el.innerHTML = html
    new_el = tmp_el.firstChild
    DOM.replaceWith(el, new_el)
    new_el

  replaceWith: (el, new_el) ->
    el.parentNode.replaceChild(new_el, el)
    new_el

  prependChild: (el, node) ->
    el.insertBefore(node, el.firstChild)

  removeNode: (el) ->
    el.parentNode?.removeChild(el)

  prependHTML: (el, html) ->
    tmp_el = document.createElement('tbody')
    tmp_el.innerHTML = html
    child_nodes = tmp_el.childNodes
    for index in [(child_nodes.length-1)..0]
      node = child_nodes[index]
      continue unless node
      DOM.prependChild(el, node)
    el

  appendHTML: (el, html) ->
    tmp_el = document.createElement('tbody')
    tmp_el.innerHTML = html
    for node in tmp_el.childNodes
      continue unless node
      el.appendChild(node)
    el

  insertHTMLAfter: (html, reference_el) ->
    tmp_el = document.createElement('tbody')
    tmp_el.innerHTML = html
    if tmp_el.childNodes.length == 1
      el = tmp_el.childNodes[0]
      return DOM.insertAfter(el, reference_el)
    else
      els = []
      for i in [(tmp_el.childNodes.length-1)..0]
        continue unless (node = tmp_el.childNodes[i])
        els.unshift(DOM.insertAfter(node, reference_el))
      els

  insertBefore: (el, reference_el) ->
    reference_el.parentNode?.insertBefore(el, reference_el)

  insertAfter: (el, reference_el) ->
    DOM.insertBefore(el, reference_el)
    DOM.insertBefore(reference_el, el)
    el

  windowHeight: ->
    return window.innerHeight if window.innerHeight
    return document.body.offsetHeight if document.body.offsetHeight
    document.documentElement?.offsetHeight

  windowWidth: ->
    return window.innerWidth if window.innerWidth
    return document.body.offsetWidth if document.body.offsetWidth
    document.documentElement?.offsetWidth

  innerWidth: (el) ->
    width = parseInt @getStyle(el, 'width')
    padding = parseInt(@getStyle(el, 'padding-left'))
    padding += parseInt(@getStyle(el, 'padding-right'))
    width - padding

  addClass: (el, class_name) ->
    return unless el
    classes = el.className.split(' ')
    classes = _.uniq(classes.concat(class_name.split(' ')))
    el.className = classes.join(' ')
    el

  removeClass: (el, class_name) ->
    return unless el
    classes = el.className.split(' ')
    classes = _.without(classes, class_name.split(' ')...)
    el.className = classes.join(' ')
    el

  show: (el, options={}) ->
    return unless el
    if options.visibility
      el.style.visibility = 'visible'
    else
      el.style.display = 'block'

  hide: (el, options={}) ->
    return unless el
    if options.visibility
      el.style.visibility = 'hidden'
    else
      el.style.display = 'none'

  isVisible: (el, options={}) ->
    DOM.getStyle(el, 'display') != 'none' &&
    DOM.getStyle(el, 'visibility') != 'hidden' &&
    (!options.check_exists || DOM.exists(el))

  exists: (el) ->
    _.any(DOM.parentNodes(el), (_el) -> _el == document.body)

  getStyle: (el, name) ->
    val = el.style[name]
    val = DOM.getComputedStyle(el, name) if !val || val.match(/^[\s\r\t\n]*$/)
    val

  getComputedStyle: (el, name) ->
    document.defaultView?.getComputedStyle(el)[name]

  setStyle: (el, name, value) ->
    el.style[name] = value

  setStyles: (el, styles) ->
    for name, value of styles
      @setStyle(el, name, value)

  parentNodes: (el) ->
    nodes = []
    node = el
    while node = node.parentNode
      nodes.push(node)
    nodes

  _events: {}
  _event_id_counter: 0
  _generateEventId: -> @_event_id_counter++

  on: (el, events, callback, capture=false) ->
    return unless el
    method = 'addEventListener' if el.addEventListener
    method ?= 'attachEvent' if el.attachEvent
    return unless method

    for event in events.split(' ')
      event_id = @_generateEventId()
      el._events ?= []
      @_events[event_id] = el[method](event, callback, capture)
      el._events.push(event_id)

  off: (el, events, callback, capture=false) ->
    return unless el
    method = 'removeEventListener' if el.removeEventListener
    method ?= 'detachEvent' if el.detachEvent
    return unless method

    for event in events.split(' ')
      el[method](event, callback, capture)

  formElementValue: (el) ->
    if el.nodeName.toLowerCase() == 'select'
      multiple = el.multiple
      value = if multiple then [] else ""
      for option in DOM.querySelectorAll('option', el)
        continue unless option.selected
        if multiple
          value.push option.value
        else
          value = option.value
          break
      value
    else
      el.value

  serializeForm: (form) ->
    params = {}
    for el in DOM.querySelectorAll('[name]', form)
      name = el.name
      value = DOM.formElementValue(el)
      params[name] = value
    params

  setElementValue: (el, val) ->
    if el.nodeName.toLowerCase() == 'select' && el.multiple
      val = [val] unless _.isArray(val)
      for option in DOM.querySelectorAll('option', el)
        option.selected = true if val.indexOf(option.value) != -1
    else
      el.value = val

  loadFormParams: (form, params) ->
    for key, val of params
      el = DOM.querySelectorAllOne("[name=#{key}]")
      continue unless el
      DOM.setElementValue(el, val)

}

