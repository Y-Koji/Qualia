
qualia.user = if localStorage.user then JSON.parse(localStorage.user) else { name: '', color: '#da5483' }

userAgent = window.navigator.userAgent.toLowerCase()
if userAgent.indexOf("msie") != -1
	alert 'IE はだぁ～め！！！'
	location.href = '/'

htmlspecialchars = (html) ->
	return html
		.replace /<a href="(.*)" .*<\/a>/g, '$1'
		.replace /</g, '&lt;'
		.replace />/g, '&gt;'
		.replace /(https?:\/\/[^$ \n<>]+)/g, '<a href="$1" target="_blank">$1</a>'

date_converter = (date) ->
	if not date then return ''
	date = new Date(date)
	now = new Date()
	offset = Math.floor((now - date) / 1000)
	if offset < 60 then return offset + '秒前'
	else if offset < (60 * 60) then return Math.floor(offset / 60) + '分前'
	else if offset < (60 * 60 * 24) then return Math.floor(offset / (60 * 60)) + '時間前'
	else return Math.floor(offset / (60 * 60 * 24)) + '日前'

$ ->
	qualia.set_background_function 'body'

	( -> # Qualia Chat ViewModel Settings
		class ViewModel
			constructor: () ->
				self = @
				@timeline = ko.observableArray []
				@login =
					users: ko.observableArray []
				@uploads = ko.observableArray []
				@postform =
					name: ko.observable qualia.user.name
					text: ko.observable ''
					color: ko.observable qualia.user.color
					submit: (event) ->
						return event.returnValue = false
					update: ->
						if self.postform.name().split(' ').join('') is ''
							name = ''
							while ((name = prompt('名前をいれてください').split(' ').join('')) is '' or not name)
								;
							self.postform.name name
							self.postform.update()
						console.log @postform
						qualia.user.name = self.postform.name()
						qualia.user.color = self.postform.color()
						localStorage.user = JSON.stringify qualia.user
				if @postform.name().split(' ').join('') is ''
					setTimeout ->
						name = ''
						while ((name = prompt('名前をいれてください').split(' ').join('')) is '' or not name)
							;
						self.postform.name name
						self.postform.update()
						alert '名前は投稿フォームでいつでも変更できます！'
					, 1000

			get_post: (id, name, text, color, date, reply_submit, delete_request, reply_target) ->
				post =
					name: name
					text: text
					date: ko.observable(date_converter date)
					color: color
					id: id
					delete_request: ->
						delete_request? id
					reply_text: ''
					reply_submit: (event) ->
						reply_submit?({
							message: post.reply_text,
							to: id
						})
						return event.returnValue = false
					reply_visible: if reply_target then 'block' else 'none'
					target:
						name: if reply_target?.name then reply_target.name else 'default'
						text: if reply_target?.text then reply_target.text else ''
						color: if reply_target?.color then reply_target.color else '#FFF'

				setInterval ->
					post.date(date_converter date)
				, 1000

				return post
			add_post: (post) ->
				@timeline.splice 0, 0, post
				if not is_focus then WebNotify post.name, post.text, '/api/user/icon.json?name=' + post.name, 5000

		window.VM = new ViewModel()
		ko.applyBindings VM
	).call @

	( -> # Drag&Drop
		event_offset = 0
		$('html')
			.on 'dragenter', (event) ->
				if event_offset is 0
					$('main div#upload-area').animate
						'width': '500px'
						'height': '300px'
						'border': '2px solid transparent',
						duration: 'slow'
				event_offset++
			.on 'dragleave', (event) ->
				if event_offset is 1
					$('main div#upload-area').animate
						'width': '0'
						'height': '0'
						'border': 'none',
						duration: 'slow'
				event_offset--
			.on 'drop', (event) ->
				if event_offset is 1
					$('main div#upload-area').animate
						'width': '0'
						'height': '0'
						'border': 'none',
						duration: 'slow'
				event_offset = 0
		$('main div#upload-area span')
			.on 'dragenter', (event) ->
				$(@).css 'background', 'rgba(255, 255, 255, .3)'
			.on 'dragleave', (event) ->
				$(@).css 'background', ''
			.on 'drop', (event) ->
				event.preventDefault()
				event.stopPropagation()
				element = $(@)
				element.css 'background', ''
				element.parent().animate
					'width': '0'
					'height': '0'
					'border': 'none',
					duration: 'slow'
				event_offset--
				files = event.originalEvent.dataTransfer.files
				for file in files
					type = element.attr('id')
					switch type
						when 'icon'
							if file.name.toLowerCase().match(/^.*\.(jpg|png|gif)$/)
								name = $('main form#post-form > input[type=text]').val()
								qualia.upload file, name + '.png', 'icon\\', ->
									location.href = location.href
							else
								alert 'JPG/PNG/GIF形式しかアイコンに設定できません!!'
							break
						when 'file'
							( ->
								obj =
									filename: file.name
									status: ko.observable 0
								VM.uploads.push obj
								progress = (status) ->
									obj.status status
									console.log status
									if status is 100
										VM.uploads.remove obj
								qualia.upload file, file.name, 'chat\\file\\', progress, ->
									url = location.href + 'file/' + encodeURIComponent(file.name)
									switch url.replace(/.*\.(.*)$/, '$1')
										when 'jpg'
											send_easy 'img:' + url
											break
										when 'png'
											send_easy 'img:' + url
											break
										when 'gif'
											send_easy 'img:' + url
										else
											send_easy url
							).call @
							break

					if type is 'icon' then break
	).call @

	( -> # Focus
		window.is_focus = true
		$(window).on 'blur', ->
			window.is_focus = false
		$(window).on 'focus', ->
			window.is_focus = true
	).call @

	( -> # WebSocket
		socket = io.connect '127.0.0.1:3000' #location.href.replace(/(https?:\/\/[^\/]*)\/.*\//, '$1:3000')
		socket.on 'connect' , ->
			socket.emit 'connected',
				name: VM.postform.name()
			socket.on 'message', (data) ->
				switch data.type
					when 'login'
						for img in document.querySelectorAll('#users > li.user img')
							if $(img).attr('title') is data.name
								return console.log data.name + 'Duplicate user.'
						WebNotify 'ログイン情報', '「' + data.name + '」さんがログインしました', '/api/user/icon.json?name=' + data.name, 5000
						VM.login.users.push
							name: data.name
							logout: ->
								socket.emit 'message',
									type: 'force-logout'
									name: data.name
									src_name: VM.postform.name()
						break
					when 'logout'
						console.log 'LOGOUT: ' + data.name
						WebNotify 'ログイン情報', '「' + data.name + '」さんがログアウトしました', '/api/user/icon.json?name=' + data.name, 5000
						$(document.querySelector('.user.' + data.name)).remove()
						break
					when 'force-logout-request'
						socket.close()
						document.write '通知: ' + data.src_name + ' さんによって強制ログアウトされました'
						break
					when 'send'
						if $('#' + data.id).length isnt 0
							return console.log 'Duplicate post.'
						reply_submit = (data) ->
							name = VM.postform.name()
							color = VM.postform.color()
							send name, data.message, color, 'reply', data
						delete_request = (id) ->
							send null, null, null, 'delete',
								id: id
						post = VM.get_post data.id,
							data.name,
							data.text,
							data.color,
							data.date,
							reply_submit,
							delete_request
						VM.add_post post
						break
					when 'file'
						reply_submit = (data) ->
							name = VM.postform.name()
							color = VM.postform.color()
							send name, data.message, color, 'reply',
								target: data.target
						delete_request = (id) ->
							send null, null, null, 'delete',
								id: id
						post = VM.get_post data.id,
							data.name,
							'<a href="./file/' + data.data.filename + '">' + data.data.filename + '</a>',
							data.color,
							data.date,
							reply_submit,
							delete_request
						VM.add_post post
						break;
					when 'reply'
						if $('#' + data.id).length isnt 0
							return console.log 'Duplicate post.'
						reply_submit = (data) ->
							name = VM.postform.name()
							color = VM.postform.color()
							send name, data.message, color, 'reply', data
						delete_request = (id) ->
							send null, null, null, 'delete',
								id: id
						post = VM.get_post data.id,
							data.name,
							data.text,
							data.color,
							data.date,
							reply_submit,
							delete_request,
							name: data.to.name
							text: data.to.text
							color: 'rgb(51, 85, 255)'
						VM.add_post post
						break
					when 'delete'
						console.log data.status
						$('#' + data.id).css('min-height', '0')
							.css('background', '#ff3257')
							.children('button').remove()
						$('#' + data.id).animate({'height': '0'}, 1000).fadeOut().queue -> $(@).remove()
			window.send = (name, text, color, type, data) ->
				if name? then name = htmlspecialchars name
				if text?
					if 0 is text.indexOf('pre:') then text = '<pre>' + text.replace(/pre:/, '') + '</pre>'
					else if text.match(/data:image\//)
					else if text.match(/^img:(.*)/) then text = text.replace /^img:(.*)/g, '<img src="$1" width="auto" height="auto" />'
					else
						if text.match(/code:.*/)
							text = text
								.replace /</g, '&lt;'
								.replace />/g, '&gt;'
								.replace /(.*)"(.*)"(.*)/g, '$1<span style="color: #1C9E54;">"$2"</span>$3'
								.replace /code:([\s\S]*)/, '<pre style="font-family: consolas; font-style: italic; font-size: .8em;">$1</pre>'
								.replace /(for )/g, '<span style="color: #FF2DA4;">for </span>'
								.replace /(while )/g, '<span style="color: #FF2DA4;">while </span>'
								.replace /(if )/g, '<span style="color: #FF2DA4;">if </span>'
								.replace /(else )/g, '<span style="color: #FF2DA4;">else </span>'
								.replace /(switch )/g, '<span style="color: #FF2DA4;">switch </span>'
								.replace /(case )/g, '<span style="color: #FF2DA4;">case </span>'
								.replace /(default:)/g, '<span style="color: #FF2DA4;">default</span>:'
								.replace /(break;)/g, '<span style="color: #FF2DA4;">break</span>;'
								.replace /(continue )/g, '<span style="color: #FF2DA4;">continue </span>'
								.replace /(return )/g, '<span style="color: #FF2DA4;">return </span>'
								.replace /(assign )/g, '<span style="color: #FF2DA4;">assign </span>'
								.replace /(posedge )/g, '<span style="color: #FF2DA4;">posedge </span>'
								.replace /(negedge )/g, '<span style="color: #FF2DA4;">negedge </span>'
								.replace /(void )/g, '<span style="color: #2DA8FF;">void </span>'
								.replace /(int )/g, '<span style="color: #2DA8FF;">int </span>'
								.replace /(double )/g, '<span style="color: #2DA8FF;">double </span>'
								.replace /(short )/g, '<span style="color: #2DA8FF;">short </span>'
								.replace /(long )/g, '<span style="color: #2DA8FF;">long </span>'
								.replace /(char )/g, '<span style="color: #2DA8FF;">char </span>'
								.replace /(module )/g, '<span style="color: #2DA8FF;">module </span>'
								.replace /(endmodule)/g, '<span style="color: #2DA8FF;">endmodule</span>'
								.replace /(always)/g, '<span style="color: #2DA8FF;">always</span>'
								.replace /(input )/g, '<span style="color: #2DA8FF;">input </span>'
								.replace /(output )/g, '<span style="color: #2DA8FF;">output </span>'
								.replace /(inout )/g, '<span style="color: #2DA8FF;">inout </span>'
								.replace /(reg )/g, '<span style="color: #2DA8FF;">reg </span>'
								.replace /(wire )/g, '<span style="color: #2DA8FF;">wire </span>'
								.replace /(<=)/g, '<span style="color: #FF2EB3;"><=</span>'
								.replace /(begin)/g, '<span style="color: #FF2EB3;"> begin</span>'
								.replace /(end)/g, '<span style="color: #FF2EB3;">end</span>'
								.replace /(#include )/g, '<span style="color: #6B6B6B;">#include </span>'
								.replace /\/\/(.*)/g, '<span style="color: #1C9E54;">//$1</span>'
								.replace /\/\*([\s\S]*)\*\//g, '<span style="color: #1C9E54;">/*$1*/</span>'
							text += '\n<span style="font-size: .7em; text-decoration: underline;">This program code is ' + text.split('\n').length.toString() + ' line.</span>'
						else
							text = text
								.replace /(^|\n)p:(.*)/g, '<p>$2 </p>'
								.replace /script:(.*)\:script/g, '<script>$1</script>'
								.replace /style:(.*)\/style/g, '<style>$1</style>'
								.replace /color\[(.*)\]:(.*)\:color/g, '<span style="color: $1;">$2</span>'
								.replace /font\[size=([0-9]+)\]:(.*):font/g, '<span style="font-size: $1px;">$2</span>'
							if text.match(/(https?:\/\/[^$ \n<>]+)/)
								text = text.replace /(https?:\/\/[^$ \n<>]+)/g, '<a href="$1" target="_blank">' + decodeURIComponent(text) + '</a>'
				socket.emit 'message',
					type: if type then type else 'send'
					name: name
					text: text
					color: color
					data: data
			window.send_easy = (text) ->
				name = VM.postform.name()
				color = VM.postform.color()
				send name, text, color
			window.upload = (file, type) ->
				reader = new FileReader()
				reader.onload = (event) ->
					data = event.target.result
					switch type
						when 'icon'
							if file.name.match(/^.*.png/)
							else
								# NOT ICON-FILE FUNCTION
								alert 'アイコンファイルはpng形式しか設定できません'
							break
						else
							socket.emit 'upload',
								type: 'file'
								file: data
								name: file.name
							send_easy location.href + 'file/' + encodeURIComponent(file.name)
							break
				reader.readAsBinaryString file
	).call @

	( -> # PostForm
		$('upload-state').draggable()
		$('#post-form')
			.draggable
				start: (event) ->
					$('main form#post-form > header').css 'background', '#32ff9b'
					$('main form#post-form').css 'border', '1px solid #32ff9b'
					$('main form#post-form').css 'height', ''
				stop: (event) ->
					$('main form#post-form > header').css 'background', '#ff3257'
					$('main form#post-form').css 'border', '1px solid #ff3257'
					$('main form#post-form').css 'height', ''
			.css 'position', ''
			.on 'mousemove', ->
				if localStorage.getItem('postform-position')
					localStorage.setItem 'postform-position', JSON.stringify(
						X: $('#post-form').position().left
						Y: $('#post-form').position().top
					)
		$('form').on 'submit', ->
			name = VM.postform.name()
			text = $(document.querySelector('#post-form > textarea')).val()
			color = VM.postform.color()
			send name, text, color
			$('main form#post-form > textarea').val('').focus()

		if localStorage.getItem('postform-position')
			$('#post-form')
				.css 'left', JSON.parse(localStorage.getItem('postform-position')).X
				.css 'top', JSON.parse(localStorage.getItem('postform-position')).Y
				.css 'bottom', 'auto'
			return false
	).call @

	( -> # Shortcut
		shortcut.add 'Ctrl+Enter', -> $('#post-form').submit()
		shortcut.add 'Ctrl+R', ->
			if localStorage.getItem('postform-position')
				localStorage.removeItem 'postform-position'
				WebNotify 'Info', '投稿フォームの固定を解除しました。', '/icon/info.png', 5000
			else
				localStorage.setItem 'postform-position', JSON.stringify(
					X: $('#post-form').position().left
					Y: $('#post-form').position().top
				)
				WebNotify 'Info', '投稿フォームを固定しました。', '/icon/info.png', 5000
	).call @

	( -> # menu setting
		is_visible = false
		$(document.querySelector('#menu')).on 'click', ->
			if not is_visible
				is_visible = true
				$(@).css
					overflow: 'visible'
					background: 'rgba(255, 255, 255, .3)'
					border: '1px solid rgba(0, 0, 0, .5)'

			else
				is_visible = false
				$(@).css
					overflow: 'hidden'
					background: ''
					border: ''
		$(document.querySelectorAll('#menu a')).click -> return false
	).call @
