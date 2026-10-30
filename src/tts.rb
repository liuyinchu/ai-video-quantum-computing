#!/usr/bin/ruby
require 'json'
require 'digest'
require 'open3'
require 'fileutils'
$stdout.sync = true
root = File.expand_path('..', __dir__)
Dir.chdir(root)
story = JSON.parse(File.read('content/story.json'))
queue = Queue.new
story['scenes'].each_with_index { |scene, si| scene['narration'].each_with_index { |text, ci| queue << [si,ci,text] } }
failures = Queue.new
workers = Array.new(1) do
  Thread.new do
    loop do
      begin
        si, ci, text = queue.pop(true)
      rescue ThreadError
        break
      end
      stem = format('%02d_%02d',si,ci)
      audio = "assets/audio/#{stem}.mp3"
      meta = "assets/audio/#{stem}.json"
      digest = Digest::SHA256.hexdigest(text)
      if File.exist?(audio) && File.exist?(meta) && JSON.parse(File.read(meta))['sha256'] == digest
        puts "CACHED #{stem}"
        next
      end
      success = false
      5.times do |attempt|
        begin
          raw, err, status = Open3.capture3('curl','--fail','--silent','--show-error','--max-time','100','--get','https://api.milorapart.top/apis/mbAIsc','--data-urlencode','format=mp3','--data-urlencode',"text=#{text}")
          raise "API #{err}" unless status.success?
          response = JSON.parse(raw)
          url = response['url']
          raise "Unexpected response #{raw[0,300]}" unless response['code'] == 200 && url && url.start_with?('https://media.milorapart.top/voice/')
          _, err, status = Open3.capture3('curl','--fail','--silent','--show-error','--max-time','100',url,'-o',"#{audio}.part")
          raise "Audio download #{err}" unless status.success? && File.size("#{audio}.part") > 1024
          info, _, valid = Open3.capture3('afinfo',"#{audio}.part")
          raise "Invalid audio" unless valid.success? && info.include?('48000')
          File.rename("#{audio}.part",audio)
          File.write(meta,JSON.pretty_generate({'text'=>text,'sha256'=>digest,'voice'=>'曼波 / AI诗歌剧','provider'=>'https://api.milorapart.top/apis/mbAIsc','source_url'=>url,'generated_at'=>Time.now.utc.to_s}))
          puts "READY #{stem} #{File.size(audio)} bytes #{text[0,24]}"
          success = true
          break
        rescue => e
          if err && err.include?("429");warn "RATE LIMIT: stopping requests; inspect Retry-After before resuming.";exit(78);end
          warn "RETRY #{stem} attempt #{attempt+1}: #{e.message}"
          sleep(err.include?("429") ? 65 + attempt*25 : 5 + attempt*5)
        end
      end
      failures << stem unless success
      sleep 6
    end
  end
end
workers.each(&:join)
if failures.empty?
  puts 'TTS COMPLETE'
else
  warn "FAILED #{failures.size} clips"
  exit 1
end

