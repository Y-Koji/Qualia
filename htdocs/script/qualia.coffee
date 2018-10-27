
window.qualia = {}

( -> # Web Notification
	Notification?.requestPermission (status) ->
		if Notification.permission isnt status
			Notification.permission = status
	window.WebNotify = (title, body, icon, timeout) ->
		document.querySelector('#sound')?.load()
		document.querySelector('#sound')?.play()
		n = new Notification?(title,
			body: body
			icon: icon
		)
		setTimeout ->
			n?.close()
		, timeout
	window.qualia.notify = (status) ->
		WebNotify 'Info', status, '/icon/info.png', 2000 
).call @

cancelEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()
$('html')
	.on 'dragenter', cancelEvent
	.on 'dragover', cancelEvent
	.on 'drop', cancelEvent

window.qualia.set_background_function = (target_element) ->
	target_element = $('body')
	$('html').on 'drop', (event) ->
		file = event.originalEvent.dataTransfer.files?[0]
		if not file then return
		if not file.name.match(/^.*.(jpg|png|gif)/) then return alert('背景はPNG/JPGしか設定できません!')
		target = $(@)
		reader = new FileReader()
		reader.onload = (e) ->
			img = e.target.result
			localStorage.background = img
			target_element
				.css 
					'background':'url("' + img + '")'
					'background-size': 'cover'
					'background-attachment': 'fixed'
		reader.readAsDataURL file
	if localStorage.background
		target_element
			.css
				'background': 'url("' + localStorage.background + '")'
				'background-size': 'cover'
				'background-attachment': 'fixed'
$ ->
	shortcut.add 'Ctrl+Z', ->
		if localStorage.background
			localStorage.removeItem 'background'
			qualia.notify '背景画像を削除しました'
			location.href = location.href
	shortcut.add 'Ctrl+Space', ->
		location.href = '/'
	shortcut.add 'Ctrl+A', ->
		if localStorage.href is location.href
			localStorage.removeItem 'href'
			qualia.notify '開いているページの記録を削除しました'
		else
			localStorage.href = location.href
			qualia.notify '開いてるページの記憶を設定しました!'
if localStorage.href
	if location.href isnt localStorage.href
		if confirm(localStorage.href + ' が記憶されています、開きますか?')
			location.href = localStorage.href

window.qualia.upload = (file, name, path, progress, done, error) ->
	fd = new FormData()
	fd.append 'filename', name.replace(/([\/\\<>~|])/g, '_')
	fd.append 'path', path.replace(/\//g, '\\')
	fd.append 'file', file

	$
		.ajax
			async: true
			xhr: ->
				XHR = $.ajaxSettings.xhr()
				if (XHR.upload)
					XHR.upload.addEventListener 'progress', (e) ->
						progress? parseInt(e.loaded/e.total*10000)/100
				return XHR
			method: 'post'
			url: '/api/upload.json'
			data: fd
			processData: false
			contentType: false
		.done done
		.error error

$ ->
	span = $(document.createElement('sapn'))
	span.css
		'position': 'fixed'
		'display': 'block'
		'right': '0'
		'bottom': '0'
		'background': 'url("/img/qualia.png")'
		'background-size': 'cover'
		'width': '150px'
		'height': '50px'
		'z-index': '0'
	$(document.body).append span
