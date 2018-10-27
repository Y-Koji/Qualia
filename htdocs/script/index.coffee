
$ ->
	qualia.set_background_function 'html'
	$('main > div').css 'height', '0'
	$('main > div > header').css 'display', 'none'
	$('main > div').animate { 'height': '200px' }, 500
	$('main > div > header').delay(800).fadeIn(300);


