import Foundation
import CoreGraphics
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
func draw(_ c:CGContext,_ story:Story,_ timeline:Timeline,_ time:Double) {
 let idx=timeline.shots.lastIndex(where:{$0.start<=time}) ?? 0
 let shot=timeline.shots[idx],scene=story.scenes[shot.index],local=time-shot.start,p=local/shot.duration
 ambient(c,time)
 let intro=ease(local/0.8),out=ease((shot.duration-local)/0.65)
 c.saveGState();c.setAlpha(CGFloat(min(intro,out)));c.translateBy(x:CGFloat((1-intro)*35),y:0)
 text(c,"Q /",110,48,31,cyan,false,true)
 text(c,"量子计算  ·  让自然参与计算",190,52,22,muted)
 text(c,scene.chapter,1650,50,24,white,true,false,360)
 line(c,110,106,1810,106,alpha(cyan,0.15),1)
 let cinematic=["hero","finale"].contains(scene.mode)
 if !cinematic {
  text(c,scene.tag,114,135,20,cyan,false,true)
  text(c,scene.title,110,180,65,white,false,false,1690)
  text(c,scene.subtitle,116,271,30,muted,false,false,1680)
 } else {text(c,scene.tag,116,183,24,muted,false,true)}
 let phase=timeline.clips.filter{$0.scene==idx && $0.start<=time}.count-1
 graphic(c,scene,local,p,phase)
 if !cinematic {text(c,scene.note,960,915,22,muted,true,false,1710)}
 else {text(c,scene.note,118,848,25,muted)}
 c.restoreGState()
 if let caption=timeline.captions.first(where:{$0.start<=time && $0.end>time}) {
  box(c,170,962,1580,65,CGColor(gray:0,alpha:1),0.65)
  text(c,caption.text,960,972,34,white,true,false,1490)
 }
 for (i,s) in timeline.shots.enumerated() {
  let x=110+1700*s.start/timeline.duration,w=1700*s.duration/timeline.duration-3
  c.setFillColor(alpha(i<idx ? cyan : muted,i<idx ? 0.7:0.18));c.fill(CGRect(x:x,y:1047,width:w,height:3))
 }
 c.setFillColor(cyan);c.fill(CGRect(x:110,y:1047,width:1700*time/timeline.duration,height:3))
 text(c,String(format:"%02d / %02d",idx+1,timeline.shots.count),1775,1008,16,muted,true,true)
}
func context(_ width:Int=W,_ height:Int=H)->CGContext {CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!}
func png(_ image:CGImage,_ path:String)throws {
 guard let dest=CGImageDestinationCreateWithURL(url(path) as CFURL,UTType.png.identifier as CFString,1,nil) else {throw NSError(domain:"PNG",code:1)}
 CGImageDestinationAddImage(dest,image,nil);guard CGImageDestinationFinalize(dest) else{throw NSError(domain:"PNG write",code:1)}
}
func preview()throws {
 let story=try readJSON("content/story.json",Story.self)
 let timeline:Timeline
 if let tl=try? readJSON("output/timeline.json",Timeline.self){timeline=tl}
 else {timeline=Timeline(duration:Double(story.scenes.count)*24,shots:story.scenes.indices.map{Shot(index:$0,start:Double($0)*24,duration:24)},clips:[],captions:[])}
 try FileManager.default.createDirectory(at:url("output/previews"),withIntermediateDirectories:true)
 for shot in timeline.shots {
  let c=context();c.translateBy(x:0,y:CGFloat(H));c.scaleBy(x:1,y:-1)
  draw(c,story,timeline,shot.start+min(7.0,shot.duration*0.4))
  try png(c.makeImage()!,String(format:"output/previews/scene-%02d.png",shot.index))
 }
 let cw=1920,ch=Int(ceil(Double(story.scenes.count)/4))*300
 let c=context(cw,ch);c.setFillColor(CGColor(gray:0.01,alpha:1));c.fill(CGRect(x:0,y:0,width:cw,height:ch))
 for i in story.scenes.indices {
  let src=CGImageSourceCreateWithURL(url(String(format:"output/previews/scene-%02d.png",i)) as CFURL,nil)!
  let im=CGImageSourceCreateImageAtIndex(src,0,nil)!
  let x=(i%4)*480,y=ch-(i/4+1)*300
  c.draw(im,in:CGRect(x:x+4,y:y+15,width:472,height:266))
 }
 let dest=CGImageDestinationCreateWithURL(url("output/contact-sheet.jpg") as CFURL,UTType.jpeg.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(dest,c.makeImage()!,[kCGImageDestinationLossyCompressionQuality:0.85] as CFDictionary);CGImageDestinationFinalize(dest)
 print("PREVIEWS READY")
}
func render(_ start:Int=0,_ end:Int?=nil)throws {
 let story=try readJSON("content/story.json",Story.self)
 let timeline:Timeline
 if let tl=try? readJSON("output/timeline.json",Timeline.self) { timeline=tl }
 else if end != nil { timeline=Timeline(duration:576,shots:story.scenes.indices.map{Shot(index:$0,start:Double($0)*24,duration:24)},clips:[],captions:[]) }
 else { throw NSError(domain:"Create audio timeline before full render",code:1) }
 let fps=30
 let output="build/picture.mp4"
 try? FileManager.default.removeItem(at:url(output))
 let writer=try AVAssetWriter(outputURL:url(output),fileType:.mp4)
 let props:[String:Any]=[AVVideoAverageBitRateKey:7500000,AVVideoExpectedSourceFrameRateKey:fps,AVVideoMaxKeyFrameIntervalKey:fps*2,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]
 let colors:[String:Any]=[AVVideoColorPrimariesKey:AVVideoColorPrimaries_ITU_R_709_2,AVVideoTransferFunctionKey:AVVideoTransferFunction_ITU_R_709_2,AVVideoYCbCrMatrixKey:AVVideoYCbCrMatrix_ITU_R_709_2]
 let settings:[String:Any]=[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:W,AVVideoHeightKey:H,AVVideoColorPropertiesKey:colors,AVVideoCompressionPropertiesKey:props]
 let input=AVAssetWriterInput(mediaType:.video,outputSettings:settings);input.expectsMediaDataInRealTime=false
 let attrs:[String:Any]=[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,kCVPixelBufferWidthKey as String:W,kCVPixelBufferHeightKey as String:H,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true]
 let adapter=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:attrs)
 writer.add(input);guard writer.startWriting() else{throw writer.error!};writer.startSession(atSourceTime:.zero)
 let count=Int(ceil(timeline.duration*Double(fps))), stop=min(end ?? count,count),beg=Date()
 for frame in start..<stop {
  while !input.isReadyForMoreMediaData {if writer.status == .failed{throw writer.error!};Thread.sleep(forTimeInterval:0.003)}
  try autoreleasepool {
   var buf:CVPixelBuffer?;guard CVPixelBufferPoolCreatePixelBuffer(nil,adapter.pixelBufferPool!,&buf)==kCVReturnSuccess,let b=buf else{throw NSError(domain:"PixelBuffer",code:1)}
   CVPixelBufferLockBaseAddress(b,[])
   let c=CGContext(data:CVPixelBufferGetBaseAddress(b),width:W,height:H,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(b),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo.byteOrder32Little.rawValue|CGImageAlphaInfo.premultipliedFirst.rawValue)!
   c.translateBy(x:0,y:CGFloat(H));c.scaleBy(x:1,y:-1)
   draw(c,story,timeline,Double(frame)/Double(fps))
   CVPixelBufferUnlockBaseAddress(b,[])
   guard adapter.append(b,withPresentationTime:CMTime(value:Int64(frame-start),timescale:Int32(fps))) else{throw writer.error ?? NSError(domain:"Append",code:1)}
  }
  if frame%300==0 {print(String(format:"RENDER %.1f%% frame %d/%d | %.1f fps",Double(frame)*100/Double(stop),frame,stop,Double(frame-start+1)/max(0.01,Date().timeIntervalSince(beg))));fflush(stdout)}
 }
 input.markAsFinished();let semaphore=DispatchSemaphore(value:0);writer.finishWriting{semaphore.signal()};semaphore.wait()
 guard writer.status == .completed else{throw writer.error ?? NSError(domain:"Writer",code:1)}
 print("PICTURE COMPLETE")
}

