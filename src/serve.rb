#!/usr/bin/ruby
require 'webrick'
root=File.expand_path('../output',__dir__)
server=WEBrick::HTTPServer.new(Port:8765,BindAddress:'127.0.0.1',DocumentRoot:root,MimeTypes:WEBrick::HTTPUtils::DefaultMimeTypes.merge('mp4'=>'video/mp4','vtt'=>'text/vtt','srt'=>'text/plain','md'=>'text/plain','zip'=>'application/zip'),DirectoryIndex:['index.html'],AccessLog:[],Logger:WEBrick::Log.new($stderr,WEBrick::Log::WARN))
trap('INT'){server.shutdown};trap('TERM'){server.shutdown}
File.write(File.expand_path('../build/preview.pid',__dir__),Process.pid)
server.start

