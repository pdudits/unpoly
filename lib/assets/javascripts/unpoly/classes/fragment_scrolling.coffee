u = up.util
e = up.element

# UpdateLayer: autoMeans: ['hash', 'top-if-main']
# OpenLayer: autoMeans: ['hash']

class up.FragmentScrolling

  constructor: (@options) ->
    @rewriteDeprecatedOptions()

    @fragment = @options.fragment or up.fail('Must pass a { fragment } option')
    @autoMeans = @options.autoMeans or up.fail('Must pass an { autoMeans } option')
    @hash = @options.hash
    @origin = @options.origin
    @layer = @options.layer or up.fail('Must pass a { layer } option')
    @mode = @options.mode
    @scrollOptions = u.pick(@options, ['revealTop', 'revealMax', 'revealSnap', 'scrollBehavior'])
    @scroll = @options.scroll

  process: ->
    # @tryProcess() returns undefined if an option cannot be applied.
    # @process() returns a resolved promise if no option cannot be applied,
    # satisfying our external signature as async method.
    (@shouldProcess() && @tryProcess(@options.scroll)) || Promise.resolve()

  tryProcess: (scrollOpt) ->
    switch scrollOpt
      when 'top'
        # If the user has passed { scroll: 'top' } we scroll to the top all
        # viewports that are either containing or are contained by element.
        return @reset()
      when 'top-if-main'
        return @resetIfTargetIsMain()
      when 'restore'
        return @restore()
      when 'hash'
        return @hash && up.viewport.revealHash(@hash, @scrollOptions)
      when 'target', 'reveal'
        return @revealElement(@fragment)
      when 'auto', true
        return u.find @autoMeans, (autoOpt) => @tryProcess(autoOpt)
      else
        if u.isString(scrollOpt)
          return @revealSelector(scrollOpt)
        if u.isFunction(scrollOpt)
          return scrollOpt(@options)

  revealSelector: (selector) ->
    getFragmentOpts = { @layer, @origin }
    # Prefer selecting a descendant of @fragment, but if not possible search through @fragment's entire layer
    if (match = up.fragment.get(@fragment, selector, getFragmentOpts) || up.fragment.get(selector, getFragmentOpts))
      return @revealElement(match)
    else
      up.warn('up.render()', 'Tried to reveal selector "%s", but no matching element found', selector)
      return

  reset: ->
    return up.viewport.resetScroll(u.merge(@scrollOptions, around: @fragment))

  restore: ->
    return up.viewport.restoreScroll(u.merge(@scrollOptions, around: @fragment))

  resetIfTargetIsMain: ->
    if e.matches(@fragment, up.viewport.autoResetSelector({ @layer, @mode }))
      return @reset()

  revealElement: (element) ->
    return up.reveal(element, @scrollOptions)
    
  shouldProcess: ->
    # Only emit an up:fragment:scroll event if a truthy scrollOpt would
    # otherwise trigger a built-in scroll strategy.
    return @scroll && up.event.nobodyPrevents(@fragment, 'up:fragment:scroll', @options)

  rewriteDeprecatedOptions: ->
    if u.isUndefined(@options.scroll)
      # Rewrite deprecated { reveal } option (it had multiple variants)
      if u.isString(@options.reveal)
        up.legacy.deprecated("Option { reveal: '#{@options.reveal}' }", "{ scroll: '#{@options.reveal}' }")
        @options.scroll = @options.reveal
      else if @options.reveal == true
        up.legacy.deprecated('Option { reveal: true }', "{ scroll: 'target' }")
        @options.scroll = 'target'
      else if @options.reveal == false
        up.legacy.deprecated('Option { reveal: false }', "{ scroll: false }")
        @options.scroll = false

      # Rewrite deprecated { resetScroll } option
      if u.isDefined(@options.resetScroll)
        up.legacy.deprecated('Option { resetScroll: true }', "{ scroll: 'top' }")
        @options.scroll = 'top'

      # Rewrite deprecated { restoreScroll } option
      if u.isDefined(@options.restoreScroll)
        up.legacy.deprecated('Option { restoreScroll: true }', "{ scroll: 'restore' }")
        @options.scroll = 'restore'
