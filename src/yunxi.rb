#!/usr/bin/ruby
require 'json'
require 'digest'
require 'open3'
require 'fileutils'
$stdout.sync=true
Dir.chdir(File.expand_path('..',__dir__))
FileUtils.mkdir_p('assets/yunxi')
story=JSON.parse(File.read('content/story.json'))
story['scenes'].each_with_index do |scene,si|
 scene['narration'].each_with_index do |text,ci|
  stem=format('%02d_%02d',si,ci)
  base="assets/yunxi/#{stem}"
  digest=Digest::SHA256.hexdigest(text)
  if File.exist?(base+'.wav') && File.exist?(base+'.json') && JSON.parse(File.read(base+'.json'))['sha256']==digest
   puts "CACHED #{stem}";next
  end
  File.write(base+'.txt',text)
  ready=false
  3.times do |attempt|
   begin
    token,err,status=Open3.capture3('ruby','src/edge-token.rb')
    raise err unless status.success?
    log,err,status=Open3.capture3({'EDGE_GEC_TOKEN'=>token.strip},'build/edge-speech',base+'.txt',base+'.mp3')
    File.write(base+'.log',log+"\n"+err)
    raise "Cloud TTS: #{err}" unless status.success? && File.size(base+'.mp3')>1000
    _,err,status=Open3.capture3('afconvert','-f','WAVE','-d','LEI16@48000','-c','1',base+'.mp3',base+'.wav')
    raise "Decode/resample: #{err}" unless status.success?
    File.write(base+'.json',JSON.pretty_generate({'text'=>text,'sha256'=>digest,'voice'=>'zh-CN-YunxiNeural','provider'=>'Microsoft Edge Read Aloud','generated_at'=>Time.now.utc.to_s}))
    puts "READY #{stem} #{text[0,24]}"
    ready=true;break
   rescue => e
    warn "RETRY #{stem} #{attempt+1}: #{e.message}"
    sleep(5+attempt*10)
   end
  end
  abort("TTS FAILED #{stem}") unless ready
  sleep 0.65
 end
end
puts "YUNXI TTS COMPLETE"

