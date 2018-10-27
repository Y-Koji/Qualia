
$ ->
	window.current = '/'
	window.root = location.href.replace(/(https?:\/\/[^\/]*)\/.*\//, '$1/')

	class ViewModel
		constructor: ->
			self = @
			@ls = ko.observableArray()
			@pwd = ko.observableArray()

			@load = (path) ->
				self.ls.splice(0, self.ls().length)

				$.ajax(
					method: 'GET'
					url: '/api/ls.json'
					data:
						path: path
				).done (data) ->
					current = root + path

					tree = current.match(root)
					self.pwd.splice 0, self.pwd().length
					console.log tree
					for dir in tree
						self.pwd.push dir
					
					for dir in data.dirs
						self.ls.push
							type: 'directory'
							data: dir
					for file in data.files
						path = current + '/' + file.name
						self.ls.push
							type: 'file'
							data: file
					$('a').click ->
						type = $(@).parent().parent().attr 'class'
						name = $(@).text()
						switch type
							when 'directory'
								VM.load current.substring(root.length) + '/' + name
								break
							when 'file'
								window.open current + '/' + name
								break
						return false

	ko.applyBindings(window.VM = new ViewModel())
	VM.load(current)