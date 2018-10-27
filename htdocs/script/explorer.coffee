$ ->
	$('.unlink').on 'click', () ->
		if window.confirm('削除しますか?')
			file = $(@)
			$.ajax(
				method: 'post'
				url: '/api/unlink.json'
				data:
					path: file.attr 'name'
			).done () ->
				file.parent().remove()

	$('#mkdir').on 'click', ->
		$.ajax(
			method: 'post'
			url: '/api/mkdir.json'
			data:
				dir: $('head > title').text() + $('#dir-name').val()
		).done((data) ->
			location.href = './'
		).error (data) ->
			alert JSON.stringify(data)

	$('form').submit ->
		$('#mkdir').click()
		return false
