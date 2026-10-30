import Foundation
import AVFoundation
import CoreGraphics
import CoreText
import AppKit

struct Scene: Codable { let chapter:String; let mode:String; let tag:String; let title:String; let subtitle:String; let note:String; let narration:[String] }
struct Story: Codable { let title:String; let voice:String; let width:Int; let height:Int; let fps:Int; let scenes:[Scene] }
struct Clip: Codable { let scene:Int; let sentence:Int; let text:String; let start:Double; let duration:Double; let source:String; let trimStart:Double }
struct Shot: Codable { let index:Int; let start:Double; let duration:Double }
struct Caption: Codable { let text:String; let start:Double; let end:Double }
struct Timeline: Codable { let duration:Double; let shots:[Shot]; let clips:[Clip]; let captions:[Caption] }
let root = URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
func url(_ path:String)->URL { root.appendingPathComponent(path) }
func readJSON<T:Decodable>(_ path:String, _ type:T.Type)throws->T { try JSONDecoder().decode(type,from:Data(contentsOf:url(path))) }
func writeJSON<T:Encodable>(_ obj:T,_ path:String)throws { let e=JSONEncoder(); e.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]; try e.encode(obj).write(to:url(path)) }
func stamp(_ sec:Double,_ srt:Bool=true)->String { let n=Int((sec*1000).rounded()); return String(format:"%02d:%02d:%02d%@%03d",n/3600000,(n/60000)%60,(n/1000)%60,srt ? "," : ".",n%1000) }
func loadMono(_ path:String)throws->([Float],Double) {
 let file=try AVAudioFile(forReading:url(path))
 guard let buffer=AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length)) else { throw NSError(domain:"Buffer",code:1) }
 try file.read(into:buffer)
 guard let p=buffer.floatChannelData else { throw NSError(domain:"PCM",code:1) }
 let a=Array(UnsafeBufferPointer(start:p[0],count:Int(buffer.frameLength)))
 return (a,file.processingFormat.sampleRate)
}
func makeAudio()throws {
 let story=try readJSON("content/story.json",Story.self)
 let rate=48000.0
 var voice=[Float](), shots=[Shot](), clips=[Clip](), captions=[Caption]()
 func silence(_ d:Double) { voice += Array(repeating:Float(0),count:Int(d*rate)) }
 for (si,scene) in story.scenes.enumerated() {
  let start=Double(voice.count)/rate
  silence(si==0 ? 2.5 : 0.6)
  for (ci,txt) in scene.narration.enumerated() {
   let path=String(format:"assets/yunxi/%02d_%02d.wav",si,ci)
   var (a,sr)=try loadMono(path)
   guard sr==rate else { throw NSError(domain:"Audio sample rate must be 48000",code:1) }
   let window=480
   var first=0,last=a.count
   let rmsThreshold:Float=0.003
   for k in stride(from:0,to:max(1,a.count-window),by:window) {
    let end=min(k+window,a.count)
    var sum:Float=0; for j in k..<end { sum += a[j]*a[j] }
    if sqrt(sum/Float(end-k))>rmsThreshold { first=max(0,k-1920); break }
   }
   for k in stride(from:max(0,a.count-window),through:0,by:-window) {
    let end=min(k+window,a.count)
    var sum:Float=0; for j in k..<end { sum += a[j]*a[j] }
    if sqrt(sum/Float(end-k))>rmsThreshold { last=min(a.count,end+6000); break }
   }
   guard last>first+4800 else { throw NSError(domain:"Audio is silent: "+path,code:1) }
   a=Array(a[first..<last])
   let peak=a.map{abs($0)}.max() ?? 1
   let gain:Float=min(2.2,0.76/max(peak,0.01))
   for j in a.indices { a[j] *= gain; let fade=min(1,Float(j)/240,Float(a.count-1-j)/480); a[j] *= max(0,fade) }
   let st=Double(voice.count)/rate, dur=Double(a.count)/rate
   voice += a
   clips.append(Clip(scene:si,sentence:ci,text:txt,start:st,duration:dur,source:path,trimStart:Double(first)/rate))
   // Sentence boundaries are exact. Shorter caption cues interpolate within each sentence.
   var parts=[String](), current=""
   for char in txt {
    current.append(char)
    if (current.count>=12 && "，。；：？！".contains(char)) || current.count>=28 { parts.append(current); current="" }
   }
   if !current.isEmpty { if current.count<6 && !parts.isEmpty { parts[parts.count-1] += current } else { parts.append(current) } }
   let total=Double(parts.reduce(0){$0+$1.count})
   var offset=0.0
   for part in parts {
    let dd=dur*Double(part.count)/total
    captions.append(Caption(text:part,start:st+offset,end:st+offset+dd))
    offset += dd
   }
   silence(ci==scene.narration.count-1 ? 0.8 : 0.22)
   print(String(format:"AUDIO %02d/%02d %.2fs",si,ci,dur)); fflush(stdout)
  }
  if si==story.scenes.count-1 { silence(3.5) }
  shots.append(Shot(index:si,start:start,duration:Double(voice.count)/rate-start))
 }
 let timeline=Timeline(duration:Double(voice.count)/rate,shots:shots,clips:clips,captions:captions)
 try writeJSON(timeline,"output/timeline.json")
 let srt=captions.enumerated().map{"\($0.offset+1)\n\(stamp($0.element.start)) --> \(stamp($0.element.end))\n\($0.element.text)\n"}.joined(separator:"\n")
 try srt.write(to:url("output/quantum-computing.zh-CN.srt"),atomically:true,encoding:.utf8)
 let vtt="WEBVTT\n\n"+captions.map{"\(stamp($0.start,false)) --> \(stamp($0.end,false))\n\($0.text)\n"}.joined(separator:"\n")
 try vtt.write(to:url("output/quantum-computing.zh-CN.vtt"),atomically:true,encoding:.utf8)
 let format=AVAudioFormat(standardFormatWithSampleRate:rate,channels:2)!
 let settings:[String:Any]=[AVFormatIDKey:kAudioFormatLinearPCM,AVSampleRateKey:rate,AVNumberOfChannelsKey:2,AVLinearPCMBitDepthKey:16,AVLinearPCMIsFloatKey:false,AVLinearPCMIsBigEndianKey:false]
 let file=try AVAudioFile(forWriting:url("output/mix.wav"),settings:settings,commonFormat:.pcmFormatFloat32,interleaved:false)
 let chords:[[Double]]=[[110,164.8138,220,261.6256],[87.307,130.8128,174.614,220],[130.8128,164.8138,196,261.6256],[97.999,146.8324,196,246.9417]]
 let notes:[Double]=[440,523.251,659.255,783.991,880,783.991,659.255,523.251]
 var peak=0.0,energy=0.0,clipped=0
 var clipIdx=0,shotIdx=0
 for block in stride(from:0,to:voice.count,by:48000) {
  let count=min(48000,voice.count-block)
  let b=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(count))!
  b.frameLength=AVAudioFrameCount(count)
  let left=b.floatChannelData![0], right=b.floatChannelData![1]
  for k in 0..<count {
   let idx=block+k,t=Double(idx)/rate
   while clipIdx+1<clips.count && t>clips[clipIdx].start+clips[clipIdx].duration+0.12 { clipIdx += 1 }
   while shotIdx+1<shots.count && t>=shots[shotIdx+1].start { shotIdx += 1 }
   let speaking=t>=clips[clipIdx].start-0.12 && t<=clips[clipIdx].start+clips[clipIdx].duration+0.15
   let duck=speaking ? 0.38 : 0.85
   let chord=chords[Int(t/10)%4]
   let morph=t.truncatingRemainder(dividingBy:10)/10
   let shape=0.7+0.3*sin(Double.pi*morph)
   var pad=0.0
   for (i,f) in chord.enumerated() { pad += sin(2*Double.pi*f*t+0.16*sin(t*0.4+Double(i)))*0.008 }
   let beat=t.truncatingRemainder(dividingBy:0.625)
   let pulse=sin(2*Double.pi*54*t)*exp(-beat*18)*0.033
   let arpTime=t.truncatingRemainder(dividingBy:0.3125)
   let freq=notes[Int(t/0.3125)%8]
   let arp=sin(2*Double.pi*freq*t)*exp(-arpTime*16)*0.010
   let elapsed=t-shots[shotIdx].start
   let impact=sin(2*Double.pi*(43*t))*exp(-elapsed*3)*0.035
   let shimmer=sin(2*Double.pi*1320*t+0.7*sin(2*Double.pi*0.2*t))*0.002
   let music=(pad*shape+pulse+arp+shimmer)*duck+impact
   let fade=min(1,t/1.8,(timeline.duration-t)/2.4)
   let l=(Double(voice[idx])+music)*max(0,fade)
   let r=(Double(voice[idx])+music+sin(2*Double.pi*329.627*t)*0.004*duck)*max(0,fade)
   peak=max(peak,abs(l),abs(r)); energy += (l*l+r*r)*0.5
   if abs(l)>0.99 || abs(r)>0.99 { clipped += 1 }
   left[k]=Float(max(-0.99,min(0.99,l))); right[k]=Float(max(-0.99,min(0.99,r)))
  }
  try file.write(from:b)
 }
 try writeJSON(["duration_seconds":timeline.duration,"sample_rate":rate,"peak_dBFS":20*log10(max(peak,0.000001)),"rms_dBFS":10*log10(energy/Double(voice.count)),"clipped_samples":Double(clipped),"narration_clips":Double(clips.count)],"output/audio-qc.json")
 print("AUDIO MIX COMPLETE: \(timeline.duration) seconds")
}
func exportAsset(_ asset:AVAsset,_ output:String,_ preset:String,_ type:AVFileType)throws {
 try? FileManager.default.removeItem(at:url(output))
 guard let ex=AVAssetExportSession(asset:asset,presetName:preset) else { throw NSError(domain:"Export unavailable",code:1) }
 ex.outputURL=url(output); ex.outputFileType=type; ex.shouldOptimizeForNetworkUse=true
 let s=DispatchSemaphore(value:0)
 ex.exportAsynchronously { s.signal() }
 s.wait()
 guard ex.status == .completed else { throw ex.error ?? NSError(domain:"Export failed",code:1) }
}
func mux()throws {
 try exportAsset(AVURLAsset(url:url("output/mix.wav")),"build/mix.m4a",AVAssetExportPresetAppleM4A,.m4a)
 let composition=AVMutableComposition()
 for (path,type) in [("build/picture.mp4",AVMediaType.video),("build/mix.m4a",AVMediaType.audio)] {
  let a=AVURLAsset(url:url(path))
  guard let source=a.tracks(withMediaType:type).first, let dest=composition.addMutableTrack(withMediaType:type,preferredTrackID:kCMPersistentTrackID_Invalid) else { throw NSError(domain:"Missing track",code:1) }
  try dest.insertTimeRange(CMTimeRange(start:.zero,duration:a.duration),of:source,at:.zero)
 }
 try exportAsset(composition,"output/quantum-computing.mp4",AVAssetExportPresetPassthrough,.mp4)
 let a=AVURLAsset(url:url("output/quantum-computing.mp4"))
 let v=a.tracks(withMediaType:.video)[0]
 let ac=a.tracks(withMediaType:.audio).count
 try writeJSON(["duration_seconds":a.duration.seconds,"width":Double(v.naturalSize.width),"height":Double(v.naturalSize.height),"fps":Double(v.nominalFrameRate),"audio_tracks":Double(ac)],"output/video-qc.json")
 print("FINAL VIDEO READY \(a.duration.seconds) s")
}

