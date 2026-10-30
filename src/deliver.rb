require 'json'
require 'fileutils'
require 'digest'
require 'time'
Dir.chdir(File.expand_path('..',__dir__))
story=JSON.parse(File.read('content/story.json'))
timeline=JSON.parse(File.read('output/timeline.json'))
chapters=timeline['shots'].map{|s|{'index'=>s['index']+1,'title'=>story['scenes'][s['index']]['title'],'chapter'=>story['scenes'][s['index']]['chapter'],'start'=>s['start'],'duration'=>s['duration']}}
File.write('output/chapters.json',JSON.pretty_generate(chapters))
FileUtils.cp('content/narration.md','output/narration.md')
FileUtils.cp('content/sources.md','output/sources.md')
FileUtils.cp('output/previews/scene-00.png','output/poster.png')
audio=JSON.parse(File.read('output/audio-qc.json'))
encoded=File.exist?('output/encoded-qc.json') ? JSON.parse(File.read('output/encoded-qc.json')) : nil
video=JSON.parse(File.read('output/video-qc.json'))
failures=[]
failures<<'encoded verification' if encoded && !encoded['passed']
failures<<'video dimensions' unless video['width']==1920 && video['height']==1080
failures<<'fps' unless (video['fps']-30).abs<0.01
failures<<'audio track' unless video['audio_tracks']==1
failures<<'duration' unless (video['duration_seconds']-timeline['duration']).abs<0.15
failures<<'audio clipping' unless audio['clipped_samples']==0
failures<<'all scenes' unless timeline['shots'].size==story['scenes'].size
failures<<'all narration clips' unless timeline['clips'].size==story['scenes'].sum{|s|s['narration'].size}
last_end=0
timeline['captions'].each do |c|
 failures<<'subtitle order/range' unless c['start']>=last_end-0.002 && c['end']>c['start'] && c['end']<=timeline['duration']+0.001
 last_end=c['end']
end
report={'generated_at'=>Time.now.utc.iso8601,'passed'=>failures.empty?,'failures'=>failures.uniq,'chapters'=>chapters.size,'narration_clips'=>timeline['clips'].size,'subtitle_cues'=>timeline['captions'].size,'audio'=>audio,'video'=>video,'encoded'=>encoded,'voice'=>'zh-CN-YunxiNeural','video_sha256'=>Digest::SHA256.file('output/quantum-computing.mp4').hexdigest}
File.write('output/validation.json',JSON.pretty_generate(report))
abort(report.inspect) unless failures.empty?
system('zip','-q','-r','output/quantum-computing-source.zip','src','content','assets/yunxi','README.md','render.sh','.gitignore','output/index.html','output/chapters.json','output/timeline.json','output/quantum-computing.zh-CN.srt','output/quantum-computing.zh-CN.vtt','output/validation.json','output/encoded-qc.json') or abort('Source archive failed')
puts JSON.pretty_generate(report)

