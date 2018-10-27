
http = require 'http'
qualia = require 'Qualia'

process.env.TMP = '.\\tmep\\'
process.env.TEMP = '.\\tmp\\'

qualia.http.listen 8080
qualia.chat.listen 3000
qualia.syncpad.listen 3001
