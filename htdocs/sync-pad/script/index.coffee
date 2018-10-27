
window.create_pad = (name, title, text, id) ->
	li = create_li name, title, text, id
	last = $('main > ul > li:last-child')
	$('main > ul')
		.append li
		.append last

window.create_li = (name, title, text, id) ->
	text_pad = create_text_pad name, title, text, id
	$(text_pad).css('display', 'none')
	$('main').prepend text_pad
	li = document.createElement 'li'
	button_delete = document.createElement 'button'
	button_edit = document.createElement 'button'
	button_view = document.createElement 'button'
	div = document.createElement 'div'
	div_menu = document.createElement 'div'
	input_hidden_title = document.createElement 'input'
	input_hidden_id = document.createElement 'input'
	input_text = document.createElement 'input'
	button_delete.innerHTML = '×'
	button_edit.innerHTML = 'Edit'
	button_view.innerHTML = 'View'
	$(button_delete).on 'click', ->
		if onDelete? then onDelete(li)
		$(li).animate
			width: '0',
			height: '0',
			padding: '0'
		setTimeout ->
			$(li).remove()
		, 1500
		qualia.pad.delete id
	li.setAttribute 'id', 'FILE_ID_' + id
	button_delete.setAttribute 'class', 'delete'
	button_edit.setAttribute 'class', 'edit'
	$(button_edit).on 'click', ->
		console.log text_pad
		if $(text_pad).css('display') is 'none'
			$(text_pad)
				.fadeIn()
			return $(text_pad).val $(text_pad).val()
	button_view.setAttribute 'class', 'view'
	input_text.setAttribute 'class', 'pad-name'
	input_text.setAttribute 'value', name
	input_text.setAttribute 'type', 'text'
	div_menu.setAttribute 'class', 'menu'
	input_hidden_title.setAttribute 'name', name
	input_hidden_title.setAttribute 'type', 'hidden'
	input_hidden_id.setAttribute 'id', id
	input_hidden_id.setAttribute 'type', 'hidden'
	div_menu.appendChild button_edit
	#div_menu.appendChild button_view
	div_menu.appendChild input_text
	div.appendChild button_delete
	div.appendChild div_menu
	div.appendChild input_text
	li.appendChild div
	li.appendChild input_hidden_id
	li.appendChild input_hidden_title
	return li

window.create_text_pad = (name, title, text, id) ->
	div = document.createElement 'div'
	header = document.createElement 'header'
	span_title = document.createElement 'span'
	span_name = document.createElement 'span'
	button_close = document.createElement 'button'
	textarea = document.createElement 'textarea'
	div.setAttribute 'class', 'pad'
	div.setAttribute 'id', id
	span_title.setAttribute 'class', 'title'
	span_name.setAttribute 'class', 'name'
	button_close.setAttribute 'class', 'close'
	textarea.setAttribute 'class', 'text'
	span_name.innerHTML = name
	span_title.innerHTML = title
	button_close.innerHTML = '×'
	header.appendChild span_title
	header.appendChild span_name
	header.appendChild button_close
	div.appendChild header
	div.appendChild textarea
	$(button_close).on 'click', ->
		$(div).fadeOut()
	$(textarea)
		.on 'keyup', ->
			qualia.pad.update name, title, $(textarea).val(), id
		.on 'keydown', (e) ->
			if (e.keyCode is 9)
				e.preventDefault()
				elem = e.target
				start = elem.selectionStart
				end = elem.selectionEnd
				value = elem.value
				elem.value = "#{value.substring 0, start}\t#{value.substring end}"
				elem.selectionStart = elem.selectionEnd = start + 1
				return false
		.val text
	$(div).on 'mousedown', ->
		$('main > div').css 'z-index', '9'
		$(@).css 'z-index', '10'
	$(div).draggable().css 'position', ''
	return div
$ ->
	qualia.set_background_function 'html'
	( ->
		socket = io.connect 'http://172.17.31.21:3001/' # location.href.replace(/(https?:\/\/[^\/]*)\/.*\//, '$1:3001')
		socket.on 'message', (data) ->
			console.log data
			switch data.type
				when 'pads'
					for pad in data.pads
						create_pad pad.name, pad.title, pad.text, pad.id
					break
				when 'update'
					$('#' + data.pad.id + ' > textarea')?.val(data.pad.text)
					break
				when 'delete'
					$('#' + data.pad.id).fadeOut()
					pad_file = $('#FILE_ID_' + data.pad.id)
						.animate
							width: '0',
							height: '0',
							padding: '0'
					setTimeout ->
						$(pad_file).remove()
					, 1500
					break
				when 'create'
					create_pad data.pad.name, data.pad.title, data.text, data.pad.id
					break
		window.qualia.pad =
			create: (name, title) ->
				socket.emit 'message',
					type: 'create'
					name: name
					title: title
					text: ''

			update: (name, title, text, id) ->
				socket.emit 'message',
					type: 'update'
					pad:
						name: name
						title: title
						text: text
						id: id
			delete: (id) ->
				socket.emit 'message',
					type: 'delete'
					id: id
			create_prompt: ->
				if (name = prompt('ファイル名'))
					if (title = prompt('タイトル'))
						qualia.pad.create name, title

	).call @

	( ->
		$('main > ul > li:last-child > button#new-pad')
			.on 'click', qualia.pad.create_prompt
		$('.pad').draggable()
		$('.pad > header > button').on 'click', ->
			pad = $(@).parent().parent()
			pad.fadeOut()
			setTimeout ->
				pad.remove()
			, 1000
	).call @