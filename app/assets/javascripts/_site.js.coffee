window.feedbin ?= {}

window.addEventListener "load", (->
  new FastClick(document.body)
  return
), false

$.extend feedbin,
  
  showNotification: (text) ->
    messages = $('[data-behavior~=messages]')
    messages.text(text)
    messages.addClass('show')
    setTimeout ( ->
      messages.removeClass('show')
    ), 3000

  updateEntries: (entries, header) ->
    $('.entries ul').html(entries)
    $('.entries-header').html(header)

  appendEntries: (entries, header) ->
    $('.entries ul').append(entries)
    $('.entries-header').html(header)

  updatePager: (html) ->
    $('[data-behavior~=pagination]').html(html)

  updateEntryContent: (html) ->
    $('[data-behavior~=entry_content_target]').html(html)

  modalBox: (html) ->
    $('.modal-target').html(html)
    $('.modal').modal
      backdrop: false
    feedbin.modalShowing = true

  updateFeeds: (feeds) ->
    $('[data-behavior~=feeds_target]').html(feeds)

  clearEntries: ->
    $('[data-behavior~=entries_target]').html('')

  clearEntry: ->
    $('[data-behavior~=entry_content_target]' ).html('')
    
  syntaxHighlight: ->
    $('[data-behavior~=entry_content_target] pre').each (i, e) ->
      hljs.highlightBlock(e)
    
  hideTagsForm: (form) ->
    if not form
      form = $('.tags-form-wrap')
    form.animate
      height: 0
    
  blogContent: (content) ->
    content = $.parseJSON(content)
    $('.blog-post').text(content.title);
    $('.blog-post').attr('href', content.url);

  precacheImages: (data) ->
    if feedbin.data.precacheImages == true && feedbin.data.mobile == false
      entries = []
      $.each data, (index, entry) ->
        if entry.read == false
          entries.push(entry.content)
      $(entries.join())

  localizeTime: (container) ->
    $('time', container).each ->
      date = $(@).attr('datetime')
      if date
        date = new Date(date)
        $(@).text(date.format("%B %d, %Y - %l:%M %p"))

  applyUserTitles: ->
    $('[data-behavior~=user_title]').each ->
      index = $(@).data('feed-id')
      newTitle = feedbin.data.userTitles[index]
      $(@).text(newTitle)

  queryString: (name) ->
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regexS = "[\\?&]" + name + "=([^&#]*)"
    regex = new RegExp(regexS)
    results = regex.exec(window.location.search)
    if results?
      decodeURIComponent results[1].replace(/\+/g, " ")
    else
      null

  openLinkInBackground: (href) ->
    anchor = document.createElement("a")
    anchor.href = href
    event = document.createEvent("MouseEvents")
    event.initMouseEvent "click", true, true, window, 0, 0, 0, 0, 0, true, false, false, true, 0, null
    anchor.dispatchEvent event

  updateTitle: (title) ->
    docTitle = $('title')
    docTitle.text(title) unless docTitle.text() is title

  autocomplete: (element) ->
    element.autocomplete
      serviceUrl: feedbin.data.tagsPath
      appendTo: $(element).closest(".tags-form").children("[data-behavior=tag_completions]")
      delimiter: /(,)\s*/

  autoHeight: ->
    $('.collection-edit-wrapper').height($(window).height() - 210)

  entries: {}

  preloadEntries: (entry_ids) ->
    $.getJSON feedbin.data.preloadEntriesPath, {ids: entry_ids.join(',')}, (data) ->
      $.extend feedbin.entries, data
      feedbin.precacheImages(data)
    
  updateReadCount: (id, entry, target) ->
    if entry.read == false
      $.post $(target).data('mark-as-read-path')
      feedbin.CountInstance.updateCount(entry.feed_id, entry.tags, 'decrement')
      $("[data-entry-id=#{id}]").addClass('read')
      feedbin.entries[id].read = true
      
      if feedbin.data.showUnreadCount
        count = $('[data-behavior~=all_unread]').find('.count').text() * 1
        if count == 0
          title = "Feedbin"
        else if count >= 1000
          title = "Feedbin (1,000+)"
        else
          title = "Feedbin (#{count})"

        feedbin.updateTitle(title)
    
  readability: (target) ->
    feedId = $('[data-feed-id]', target).data('feed-id')
    if feedbin.data.readabilitySettings[feedId] == true && feedbin.data.stickyReadability
      $('.button-toggle-content').find('span').addClass('active')
      $('[data-behavior~=entry_content_wrap]').html('Loading Readability&hellip;')
      $('[data-behavior~=toggle_content_view]').submit()
    
  formatEntryContent: (resetScroll = true) ->
    if resetScroll
      $('.entry-content').prop('scrollTop', 0)
    $('[data-behavior~=entry_content_target]').fitVids({ customSelector: "iframe[src*='youtu.be'], iframe[src*='view.vzaar.com']"});
    feedbin.syntaxHighlight()
    
  refresh: ->
    if feedbin.data != null
      $.get(feedbin.data.autoUpdatePath)

  shareOpen: ->
    $('[data-behavior~=toggle_share_menu]').parents('.dropdown-wrap').hasClass('open')

  updateFontSize: (direction) ->
    fontContainer = $("[data-font-size]")
    currentFontSize = fontContainer.data('font-size')
    if direction == 'increase'
      newFontSize = currentFontSize + 1
    else
      newFontSize = currentFontSize - 1
    if feedbin.data.fontSizes[newFontSize]
      fontContainer.removeClass("font-size-#{currentFontSize}")
      fontContainer.addClass("font-size-#{newFontSize}")
      fontContainer.data('font-size', newFontSize)

  matchHeights: (elements) ->
    height = 0
    $.each elements, (index, element) ->
      $(element).css({'height': ''})
      outerHeight = $(element).outerHeight()
      if outerHeight > height
        height = outerHeight

    elements.css
      height: height

  disableMarkRead: () ->
    feedbin.markReadData = null
    $('[data-behavior~=mark_all_as_read]').attr('disabled', 'disabled')
      
  markRead: () ->
    $('.entries li').addClass('read')
    $.post feedbin.data.markAsReadPath, feedbin.markReadData
      
  hideQueue: []

  feedCandidates: []
  
  modalShowing: false
  
  images: []
  
  feedXhr: null
  
  markReadData: null

$.extend feedbin,
  init:
    setData: ->
      feedbin.data = $('#feedbin-data').data()
    
    markRead: ->
      $(document).on 'click', '[data-mark-read]', ->
        feedbin.markReadData = $(@).data('mark-read')
        $('[data-behavior~=mark_all_as_read]').removeAttr('disabled')
        return
        
      $(document).on 'click', '[data-behavior~=mark_all_as_read]', ->
        unless $(@).attr('disabled')
          if feedbin.data.markAsReadConfirmation
            result = confirm(feedbin.markReadData.message)
            if result
              feedbin.markRead()
          else
            feedbin.markRead()
        return

    selectable: ->
      $(document).on 'click', '[data-behavior~=selectable]', ->
        $(@).parents('ul').find('.selected').removeClass('selected')
        $(@).parent('li').addClass('selected')
        return

    choicesSubmit: ->
      $(document).on 'ajax:beforeSend', '[data-choice-form]', ->
        $('.modal').modal('hide')
        return

    subscribeSubmit: ->
      form = $('[data-behavior~=subscription_form]')
      textField = form.find('[name="subscription[feeds][feed_url]"]')
      submit = form.find('[name="commit"]')

      $(document).on 'ajax:beforeSend', '[data-behavior~=subscription_form]', ->
        textField.attr('disabled', 'disabled')
        submit.attr('disabled', 'disabled')
        textField.blur()
        return

      $(document).on 'ajax:complete', '[data-behavior~=subscription_form]', ->
        textField.val('').removeAttr('disabled')
        submit.removeAttr('disabled')
        return

    resetEntryPostion: ->
      $(document).on 'ajax:complete', '[data-behavior~=reset_entry_position]', ->
        $('.entries').prop('scrollTop', 0)
        return

    openEntry: ->
      $(document).on 'ajax:complete', '[data-behavior~=reset_entry_content_position]', ->
        feedbin.formatEntryContent()
        return

    entryLinks: ->
      $(document).on 'click', '[data-behavior~=entry_content_wrap] a', ->
        $(this).attr('target', '_blank')
        return

    clearEntry: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=show_entries]', (event) ->
        unless $(event.target).is('.toggle-drawer')
          feedbin.clearEntry()
        return
        
    cancelFeedRequest: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=show_entries]', (event, xhr) ->
        if feedbin.feedXhr
          feedbin.feedXhr.abort()
        feedbin.feedXhr = xhr
        return
        
    tooltips: ->
      $(document).on 'mouseenter mouseleave', '[data-behavior~=tooltip]', (event) ->
        tooltip = $(this).tooltip
          delay: 0
          animation: false
        if 'mouseenter' == event.type
          tooltip.tooltip('show')
        else
          tooltip.tooltip('hide')
        return

    loadEntries: ->
      $('[data-behavior~=feeds_target] > li:first-child [data-behavior~=open_item]').click() unless $('body').hasClass('mobile')

    tagsForm: ->
      $(document).on 'click', (event) ->
        target = $(event.target)
        if not target.hasClass('toolbar-button')
          target = target.parents('.toolbar-button')
        wrap = target.find('.tags-form-wrap')
        feedbin.hideTagsForm($('.tags-form-wrap').not(wrap))
        return

      $(document).on 'click', '[data-behavior~=show_tags_form]', (event) ->
        target = $(event.target)
        if not target.hasClass('toolbar-button')
          target = target.parentsUntil('.toolbar-button')
        wrap = target.find('.tags-form-wrap')
        unless $(@).attr('disabled') == 'disabled'
          if '0px' == wrap.css('height')
            wrap.animate
              height: '138px'
            field = wrap.find('.feed_tag_list')
            field.focus()
            value = field.val()
            field.val(value)
            feedbin.autocomplete(field)
        return
    
    resize: () ->
      defaults = 
        handles: "e"
        minWidth: 200
        stop: (event, ui) ->
          form = $('[data-behavior~=resizable_form]')
          $('[name=column]', form).val($(ui.element).parents('td').data('resizable-name'))
          $('[name=width]', form).val(ui.size.width)
          form.submit()
          return
      $('.entries-wrap').resizable($.extend(defaults, {alsoResize: $('.entries-column')}))
      $('.feeds-wrap').resizable($.extend(defaults, {alsoResize: $('.feeds-column')}))

    processHideQueue: ->
      $(document).on 'click', '[data-behavior~=show_entries]', ->
        $.each feedbin.hideQueue, (i, feed_id) ->
          if feed_id != undefined && feed_id != "collection_all" && feed_id != "collection_unread"
            item = $("[data-feed-id=#{feed_id}]", '.feeds')
            $(item).hide 'fast', () ->
              $(item).remove()
              feedbin.hideQueue.remove(i)
        feedbin.hideQueue = []
        return

    feedCandidates: ->
      $(document).on 'click', '[data-behavior~=show_entries]', ->
        clickedItem = $(@).parents 'li'
        feedbin.feedCandidates = []
        feedbin.feedCandidates.push clickedItem.next().data('feed-id') if clickedItem.next().length
        feedbin.feedCandidates.push clickedItem.prev().data('feed-id') if clickedItem.prev().length
        return
        
    unauthorizedResponse: ->
      $(document).on 'ajax:complete', (event, response, status) ->
        if response.status == 401
          document.location = feedbin.data.loginUrl
        return

    screenshotTabs: ->
      $('[data-behavior~=screenshot_nav] li').first().addClass('active')
      $(document).on 'click', '[data-behavior~=screenshot_nav] a', (event) ->
        $('[data-behavior~=screenshot_nav] li').removeClass('active')
        $(@).parent('li').addClass('active')
        src = $(@).find('img').attr('src')
        $("[data-behavior~=screenshots] img").addClass('hide')
        $("[data-behavior~=screenshots] img[src='#{src}']").removeClass('hide')
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=screenshot_previous], [data-behavior~=screenshot_next]', (event) ->
        selectedScreenshot = $('[data-behavior~=screenshot_nav] li.active')
        button = $(event.target).data('behavior')
        if button.match(/screenshot_next/)
          nextScreenshot = selectedScreenshot.next()
          if nextScreenshot.length == 0
            nextScreenshot = $('li:first-child', $('[data-behavior~=screenshot_nav]'))
        else
          nextScreenshot = selectedScreenshot.prev()
          if nextScreenshot.length == 0
            nextScreenshot = $('li:last-child', $('[data-behavior~=screenshot_nav]'))
        
        nextScreenshot.find('a').click()
        event.preventDefault()
        return
      
        
    feedSelected: ->
      $(document).on 'click', '[data-behavior~=back_to_feeds]', ->
        $('.app').addClass('nothing-selected').removeClass('feed-selected entry-selected')
        return

      $(document).on 'click', '[data-behavior~=show_entries]', (event) ->
        $('.app').addClass('feed-selected').removeClass('nothing-selected entry-selected')
        return

      $(document).on 'click', '[data-behavior~=show_entry_content]', ->
        $('.app').addClass('entry-selected').removeClass('nothing-selected feed-selected')
        return
        
    addFields: ->
      $(document).on 'click', '[data-behavior~=add_fields]', (event) ->
        time = new Date().getTime() + '_insert'
        regexp = new RegExp($(@).data('id'), 'g')
        $(@).parents('[data-behavior~=add_fields_target]').find('tr:last').before($(@).data('fields').replace(regexp, time))
        event.preventDefault()
        return
        
    removeFields: ->
      $(document).on 'click', '[data-behavior~=remove_fields]', (event) ->
        $(@).prev('input[type=hidden]').val(1)
        $(@).closest('tr').addClass('hide')
        event.preventDefault()
        return
        
    dropdown: ->
      $(document).on 'click', (event) ->
        dropdown = $('.dropdown-wrap')
        unless $(event.target).is('[data-behavior~=toggle_dropdown]')
          dropdown.removeClass('open')
        return

      $(document).on 'click', '[data-behavior~=toggle_share_menu]', (event) ->
        $(".dropdown-wrap li").removeClass('selected')
        parent = $(@).closest('.dropdown-wrap')
        if parent.hasClass('open')
          parent.removeClass('open')
        else
          parent.addClass('open')
        event.preventDefault()
        return

      $(document).on 'mouseover', '.dropdown-wrap li', (event) ->
        $('.dropdown-wrap li').not(@).removeClass('selected')
        return

    drawer: ->
      $(document).on 'click', '[data-behavior~=toggle_drawer]', (event) =>
        button = $(event.currentTarget)
        drawer = button.parents('li').find('.drawer')

        if drawer.data('hidden') == true
          height = $('ul', drawer).height() + 2
          hidden = false
          text = 'hide'
        else
          height = 0
          hidden = true
          text = 'show'
      
        drawer.animate {
          height: height
        }, 300, ->
          if height > 0
            drawer.css
              height: 'auto'
        
        drawer.data('hidden', hidden)
        button.text(text)
      
        button.parent('form').submit()
        event.stopPropagation()
        event.preventDefault()
        return

    checkBoxToggle: ->
      $(document).on 'click', '[data-behavior~=check_all]', (event) =>
        $('[type="checkbox"]').prop('checked', true)
        event.preventDefault()
        return

      $(document).on 'click', '[data-behavior~=check_none]', (event) =>
        $('[type="checkbox"]').prop('checked', false)
        event.preventDefault()
        return

    validateFile: ->
      form = $('.new_import_uploader')
      input = form.find("input:file")
      unless input.val()
        form.find('[type=submit]').attr('disabled','disabled')
      
      input.on 'change', ()->
        if $(this).val()
          form.find('[type=submit]').removeAttr('disabled')
        return

    autoHeight: ->
      if $('.collection-edit-wrapper').length
        feedbin.autoHeight()
        $(window).on 'resize', () ->
          feedbin.autoHeight()
          return

    usePreloadContent: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=open_item]', (event, xhr) ->
        id = $(@).parents('li').data('entry-id')
        entry = feedbin.entries[id]
        if entry
          xhr.abort()
          feedbin.updateEntryContent(entry.content)
          feedbin.formatEntryContent()
          feedbin.localizeTime($('[data-behavior~=entry_content_target]'))
          feedbin.applyUserTitles()
          feedbin.updateReadCount(id, entry, @)
          feedbin.readability(@)
        return

    updateReadability: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_content_view]', (event, xhr) ->
        feedId = $(event.currentTarget).data('feed-id')
        if feedbin.data.stickyReadability && feedbin.data.readabilitySettings[feedId] != "undefined"
          unless $("#content_view").val() == "true" && feedbin.data.readabilitySettings[feedId] == true
            feedbin.data.readabilitySettings[feedId] = !feedbin.data.readabilitySettings[feedId]
        return

    removePreload: ->
      # Just delete the preloaded entry when something gets starred
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_starred]', (event, xhr) ->
        entryId = $(event.currentTarget).data('entry-id')
        delete feedbin.entries[entryId]
        return

    updateRead: ->
      $(document).on 'ajax:beforeSend', '[data-behavior~=toggle_read]', (event, xhr) ->
        entryId = $(event.currentTarget).data('entry-id')
        if feedbin.entries[entryId]
          feedbin.entries[entryId].read = !feedbin.entries[entryId].read
        return

    autoUpdate: ->
      setInterval ( ->
        feedbin.refresh()
      ), 300000

    entrySettings: ->
      $(document).on 'click', (event, xhr) ->
        if ($(event.target).hasClass('entry-settings') || $(event.target).parents('.entry-settings').length > 0)
          false
        else if ($(event.target).hasClass('button-settings') || $(event.target).parents('.button-settings').length > 0) && !$('.entry-settings').hasClass('open')
          top = $('.entry-toolbar').outerHeight() + $('.entry-settings').outerHeight()
          $('.entry-settings').addClass('open')
          $('[data-behavior="entry_settings_target"]').html($('[data-behavior="entry_settings_content"]').html())
          $('[data-behavior~=change_font]').val($("[data-font]").data('font'))
          $('[data-behavior~=change_font]').change ->
            fontContainer = $("[data-font]")
            currentFont = fontContainer.data('font')
            fontContainer.removeClass("font-#{currentFont}")
            fontContainer.addClass("font-#{$(@).val()}")
            fontContainer.data('font', $(@).val())
            $(@).parents('form').submit()
          
        else
          top = $('.entry-toolbar').outerHeight()
          $('.entry-settings').removeClass('open')
        $('.entry-content').animate {
          top: top
        }, 100
      return
      
    fontSize: ->
      $(document).on 'click', '[data-behavior~=increase_font]', (event) ->
        feedbin.updateFontSize('increase')
        return

      $(document).on 'click', '[data-behavior~=decrease_font]', (event) ->
        feedbin.updateFontSize('decrease')
        return
        
    entryWidth: ->
      $(document).on 'click', '[data-behavior~=entry_width]', (event) ->
        if $('[data-behavior~=entry_content_target]').hasClass('fluid')
          $('[data-behavior~=entry_content_target]').removeClass('fluid')
        else
          $('[data-behavior~=entry_content_target]').addClass('fluid')
        return
        
    filterList: ->
      feedbin.matchHeights($('.app-detail'))
      $(window).on 'resize', () ->
        feedbin.matchHeights($('.app-detail'))
        return
      
      $(document).on 'click', '[data-filter]', (event) ->
        $('[data-filter]').removeClass('active')
        $(@).addClass('active')

        filter = $(@).data('filter')
        if filter == 'all'
          $("[data-platforms]").removeClass('hide')
        else
          $("[data-behavior~=filter_target]").addClass('hide')
          $("[data-platforms~=#{filter}]").removeClass('hide')
        return
        
    showEntryActions: ->
      $(document).on 'click', '[data-behavior~=show_entry_actions]', (event) ->
        parent = $(@).parents('li')
        if parent.hasClass('show-actions')
          $('.entries li').removeClass('show-actions')
        else
          $('.entries li').removeClass('show-actions')
          parent.addClass('show-actions')
        return

      $(document).on 'click', (event) ->
        $('.entries li').removeClass('show-actions')
        return

      $(document).on 'click', '[data-behavior~=show_entry_content]', (event) ->
        unless $(event.target).is('[data-behavior~=show_entry_actions]')
          $('.entries li').removeClass('show-actions')
        return
        
    markDirectionAsRead: ->
      $(document).on 'click', '[data-behavior~=mark_below_read], [data-behavior~=mark_above_read]', (event) ->
        data = feedbin.markReadData
        if data
          data['ids'] = $(@).parents('li').prevAll().map(() ->
            $(@).data('entry-id')
          ).get().join()
          
          if $(@).is('[data-behavior~=mark_below_read]')
            $(@).parents('li').nextAll().addClass('read')
            data['direction'] = 'below'
          else
            $(@).parents('li').prevAll().addClass('read')
            data['direction'] = 'above'
            
        $.post feedbin.data.markDirectionAsReadEntries, data
        return

    formOptions: ->
      $(document).on 'click', '[data-behavior~=show_form_options]', (event) ->
        wrap = $(@).parents('.dropdown-wrap')
        if wrap.hasClass('open')
          wrap.removeClass('open')
        else
          wrap.addClass('open')
        return
      
      $(document).on 'click', '[data-behavior~=form_select] li', (event) ->
        $('.header-form-option').removeClass('selected')
        selectOption = $(@).data('select-option')
        $("[data-behavior~=#{selectOption}]").addClass('selected')
        $("[data-behavior~=show_form_options]").text($(@).text())
        return

    subscribe: ->
      # This needs to come after "[data-behavior~=form_select] li" click event
      subscription = feedbin.queryString('subscribe')
      if subscription?
        $('[data-behavior~=form_select] [data-select-option=subscribe_form]').click()
        field = $('#subscription_feeds_feed_url').val(subscription)
        field.parents('form').submit()

    searchError: ->
      $(document).on 'ajax:error', '[data-behavior~=search_form]', (event, xhr) ->
        feedbin.showNotification('Search error.');

jQuery ->
  $.each feedbin.init, (i, item) ->
    item()