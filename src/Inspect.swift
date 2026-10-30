import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
func u(_ p:String)->URL{root.appendingPathComponent(p)}
do {
 let a=AVURLAsset(url:u("output/quantum-computing.mp4"))
 let timeline=try JSONSerialization.jsonObject(with:Data(contentsOf:u("output/timeline.json"))) as! [String:Any]
 let shots=timeline["shots"] as! [[String:Any]]
 try FileManager.default.createDirectory(at:u("output/verified"),withIntermediateDirectories:true)
 let generator=AVAssetImageGenerator(asset:a);generator.appliesPreferredTrackTransform=true
 generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
 var verified=[Double]()
 let cw=1600,ch=Int(ceil(Double(shots.count)/4))*245
 let c=CGContext(data:nil,width:cw,height:ch,bitsPerComponent:8,bytesPerRow:cw*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.setFillColor(CGColor(gray:0.02,alpha:1));c.fill(CGRect(x:0,y:0,width:cw,height:ch))
 for (i,s) in shots.enumerated() {
  let sec=(s["start"] as! Double)+min(7,(s["duration"] as! Double)*0.4)
  var actual=CMTime.zero
  let image=try generator.copyCGImage(at:CMTime(seconds:sec,preferredTimescale:600),actualTime:&actual)
  guard image.width==1920 && image.height==1080 else{throw NSError(domain:"Wrong decoded dimensions",code:1)}
  verified.append(actual.seconds)
  let dest=CGImageDestinationCreateWithURL(u(String(format:"output/verified/frame-%02d.jpg",i)) as CFURL,UTType.jpeg.identifier as CFString,1,nil)!
  CGImageDestinationAddImage(dest,image,[kCGImageDestinationLossyCompressionQuality:0.85] as CFDictionary);CGImageDestinationFinalize(dest)
  let x=(i%4)*400,y=ch-(i/4+1)*245
  c.draw(image,in:CGRect(x:Double(x+4),y:Double(y+12),width:392.0,height:220.5))
 }
 let dest=CGImageDestinationCreateWithURL(u("output/verified/contact.jpg") as CFURL,UTType.jpeg.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(dest,c.makeImage()!,[kCGImageDestinationLossyCompressionQuality:0.86] as CFDictionary);CGImageDestinationFinalize(dest)
 let reader=try AVAssetReader(asset:a)
 guard let track=a.tracks(withMediaType:.audio).first else{throw NSError(domain:"No audio track",code:1)}
 let settings:[String:Any]=[AVFormatIDKey:kAudioFormatLinearPCM,AVLinearPCMIsFloatKey:true,AVLinearPCMBitDepthKey:32,AVLinearPCMIsNonInterleaved:false,AVNumberOfChannelsKey:2,AVSampleRateKey:48000]
 let out=AVAssetReaderTrackOutput(track:track,outputSettings:settings);reader.add(out)
 guard reader.startReading() else{throw reader.error!}
 var peak:Float=0,count=0,clipped=0,energy=0.0
 while let sample=out.copyNextSampleBuffer() {
  guard let buffer=CMSampleBufferGetDataBuffer(sample) else{throw NSError(domain:"No PCM data",code:1)}
  let n=CMBlockBufferGetDataLength(buffer)
  var data=Data(count:n)
  let status=data.withUnsafeMutableBytes{CMBlockBufferCopyDataBytes(buffer,atOffset:0,dataLength:n,destination:$0.baseAddress!)}
  guard status==kCMBlockBufferNoErr else{throw NSError(domain:"PCM read",code:Int(status))}
  data.withUnsafeBytes { raw in
   let f=raw.bindMemory(to:Float.self)
   for v in f {peak=max(peak,abs(v));energy+=Double(v*v);count+=1;if abs(v)>=0.999{clipped+=1}}
  }
 }
 guard reader.status == .completed && count>100000 else{throw reader.error ?? NSError(domain:"Incomplete decoded audio",code:1)}
 let report:[String:Any]=["decoded_scene_frames":verified.count,"frame_timestamps":verified,"decoded_audio_samples":count,"decoded_audio_peak_dBFS":20*log10(max(Double(peak),1e-9)),"decoded_audio_rms_dBFS":10*log10(energy/Double(count)),"decoded_audio_clipped_samples":clipped,"passed":clipped==0]
 let json=try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys])
 try json.write(to:u("output/encoded-qc.json"))
 print(String(data:json,encoding:.utf8)!)
} catch {fputs("INSPECT ERROR: \(error)\n",stderr);exit(1)}

