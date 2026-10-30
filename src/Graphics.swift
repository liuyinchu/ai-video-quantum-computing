import Foundation
import AppKit
import CoreGraphics
import CoreText
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

let W=1920, H=1080
let cyan=CGColor(red:0.23,green:0.92,blue:1,alpha:1)
let mint=CGColor(red:0.47,green:1,blue:0.74,alpha:1)
let violet=CGColor(red:0.65,green:0.46,blue:1,alpha:1)
let orange=CGColor(red:1,green:0.63,blue:0.35,alpha:1)
let white=CGColor(red:0.94,green:0.97,blue:1,alpha:1)
let muted=CGColor(red:0.49,green:0.60,blue:0.72,alpha:1)
func alpha(_ c:CGColor,_ a:Double)->CGColor { c.copy(alpha:CGFloat(max(0,min(1,a))))! }
func ease(_ x:Double)->Double { let t=max(0,min(1,x)); return t*t*(3-2*t) }
struct P3 { var x:Double; var y:Double; var z:Double }
struct P2 { var x:Double; var y:Double; var z:Double }
func proj(_ p:P3,_ t:Double,_ cx:Double,_ cy:Double,_ r:Double)->P2 {
 let a=t*0.17,b=0.28+sin(t*0.11)*0.15
 let xx=p.x*cos(a)+p.z*sin(a),zz = -p.x*sin(a)+p.z*cos(a)
 let yy=p.y*cos(b)-zz*sin(b),z=p.y*sin(b)+zz*cos(b)
 let f=3.4/(3.4-z)
 return P2(x:cx+r*xx*f,y:cy+r*yy*f,z:z)
}
var cache=[String:CTLine]()
func text(_ c:CGContext,_ s:String,_ x:Double,_ y:Double,_ size:Double=32,_ color:CGColor=white,_ center:Bool=false,_ mono:Bool=false,_ limit:Double=1800) {
 let key=s+"|\(size)|\(color.components ?? [])|\(mono)"
 let l:CTLine
 if let cached=cache[key] { l=cached } else {
  let font=CTFontCreateWithName((mono ? "Menlo-Regular" : "PingFangSC-Semibold") as CFString,CGFloat(size),nil)
  let a=NSAttributedString(string:s,attributes:[NSAttributedString.Key(kCTFontAttributeName as String):font,NSAttributedString.Key(kCTForegroundColorAttributeName as String):color])
  l=CTLineCreateWithAttributedString(a); if cache.count<16000 { cache[key]=l }
 }
 let width=CTLineGetTypographicBounds(l,nil,nil,nil)
 let scale=min(1,limit/max(1,width))
 c.saveGState(); c.translateBy(x:CGFloat(x-(center ? width*scale/2 : 0)),y:CGFloat(y+size*0.91*scale)); c.scaleBy(x:CGFloat(scale),y:CGFloat(-scale)); c.textMatrix = .identity; c.textPosition = .zero; CTLineDraw(l,c); c.beginPath(); c.restoreGState()
}
func path(_ c:CGContext,_ pts:[CGPoint],_ color:CGColor,_ width:Double=2,_ glow:Bool=false,_ close:Bool=false) {
 guard !pts.isEmpty else{return}
 c.saveGState(); c.setStrokeColor(color); c.setLineWidth(CGFloat(width)); c.setLineCap(.round); c.setLineJoin(.round)
 if glow { c.setShadow(offset:.zero,blur:12,color:alpha(color,0.7)) }
 c.beginPath(); c.move(to:pts[0]); for p in pts.dropFirst(){c.addLine(to:p)}; if close {c.closePath()};c.strokePath();c.restoreGState()
}
func line(_ c:CGContext,_ x:Double,_ y:Double,_ xx:Double,_ yy:Double,_ color:CGColor,_ width:Double=2,_ glow:Bool=false) {path(c,[CGPoint(x:x,y:y),CGPoint(x:xx,y:yy)],color,width,glow)}
func disc(_ c:CGContext,_ x:Double,_ y:Double,_ r:Double,_ color:CGColor,_ glow:Bool=false) {
 c.saveGState(); if glow {c.setShadow(offset:.zero,blur:CGFloat(r*2.2+8),color:alpha(color,0.7))}; c.setFillColor(color);c.fillEllipse(in:CGRect(x:x-r,y:y-r,width:2*r,height:2*r));c.restoreGState()
}
func ring(_ c:CGContext,_ x:Double,_ y:Double,_ r:Double,_ color:CGColor,_ width:Double=2) {c.setStrokeColor(color);c.setLineWidth(CGFloat(width));c.strokeEllipse(in:CGRect(x:x-r,y:y-r,width:2*r,height:2*r))}
func box(_ c:CGContext,_ x:Double,_ y:Double,_ w:Double,_ h:Double,_ color:CGColor,_ fill:Double=0.08) {
 let rect=CGRect(x:x,y:y,width:w,height:h);let p=CGPath(roundedRect:rect,cornerWidth:18,cornerHeight:18,transform:nil)
 c.beginPath();c.setFillColor(alpha(color,fill));c.addPath(p);c.fillPath();c.setStrokeColor(alpha(color,0.38));c.setLineWidth(1.3);c.beginPath();c.addPath(p);c.strokePath()
}
func arrow(_ c:CGContext,_ x:Double,_ y:Double,_ xx:Double,_ yy:Double,_ color:CGColor) {
 line(c,x,y,xx,yy,color,3,true);let a=atan2(yy-y,xx-x)
 line(c,xx,yy,xx-16*cos(a-0.45),yy-16*sin(a-0.45),color,3)
 line(c,xx,yy,xx-16*cos(a+0.45),yy-16*sin(a+0.45),color,3)
}
func wave(_ c:CGContext,_ x:Double,_ y:Double,_ w:Double,_ amp:Double,_ phase:Double,_ color:CGColor,_ cycles:Double=3,_ gain:Double=1) {
 var pts=[CGPoint]()
 for i in 0...240 {let u=Double(i)/240;pts.append(CGPoint(x:x+w*u,y:y+sin(u*cycles*2*Double.pi+phase)*amp*gain))}
 path(c,pts,color,3.5,true)
}
func orbit(_ c:CGContext,_ cx:Double,_ cy:Double,_ r:Double,_ t:Double,_ color:CGColor=cyan,_ dense:Bool=true) {
 for lat in stride(from:-75.0,through:75,by:15) {
  let a=lat*Double.pi/180
  var pts=[CGPoint]()
  for i in 0...96 {let b=Double(i)/96*2*Double.pi;let q=proj(P3(x:cos(a)*cos(b),y:sin(a),z:cos(a)*sin(b)),t,cx,cy,r);pts.append(CGPoint(x:q.x,y:q.y))}
  path(c,pts,alpha(color,0.16),1.1)
 }
 for m in 0..<12 {
  let b=Double(m)*Double.pi/6
  var pts=[CGPoint]()
  for i in 0...96 {let a=Double(i)/96*2*Double.pi;let q=proj(P3(x:cos(a)*cos(b),y:sin(a),z:cos(a)*sin(b)),t,cx,cy,r);pts.append(CGPoint(x:q.x,y:q.y))}
  path(c,pts,alpha(color,0.18),1)
 }
 if dense {
  for i in 0..<360 {
   let y=1-2*(Double(i)+0.5)/360,rr=sqrt(1-y*y),a=Double(i)*2.39996323
   let q=proj(P3(x:rr*cos(a),y:y,z:rr*sin(a)),t,cx,cy,r)
   disc(c,q.x,q.y,1.3+1.2*(q.z+1),alpha(i%5==0 ? violet : color,0.22+0.37*(q.z+1)))
  }
 }
 for j in 0..<3 {
  var pts=[CGPoint]()
  for i in 0...150 {
   let a=Double(i)/150*Double.pi*2
   let p=P3(x:1.25*cos(a),y:0.22*sin(a+Double(j))*Double(j+1),z:1.25*sin(a))
   let q=proj(p,t+Double(j)*5,cx,cy,r)
   pts.append(CGPoint(x:q.x,y:q.y))
  }
  path(c,pts,alpha(j==1 ? violet : color,0.48),1.6,true)
 }
 disc(c,cx,cy,5,white,true)
}
func background()->CGImage {
 let c=CGContext(data:nil,width:W,height:H,bitsPerComponent:8,bytesPerRow:W*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 c.setFillColor(CGColor(red:0.008,green:0.014,blue:0.037,alpha:1));c.fill(CGRect(x:0,y:0,width:W,height:H))
 let cs=CGColorSpaceCreateDeviceRGB()
 let g=CGGradient(colorsSpace:cs,colors:[CGColor(red:0.025,green:0.045,blue:0.09,alpha:1),CGColor(red:0.008,green:0.014,blue:0.037,alpha:1)] as CFArray,locations:[0,1])!
 c.drawLinearGradient(g,start:CGPoint(x:0,y:1080),end:CGPoint(x:1600,y:0),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation])
 let blue=CGGradient(colorsSpace:cs,colors:[CGColor(red:0.04,green:0.25,blue:0.36,alpha:0.36),CGColor(red:0.03,green:0.12,blue:0.20,alpha:0)] as CFArray,locations:[0,1])!
 c.drawRadialGradient(blue,startCenter:CGPoint(x:1300,y:540),startRadius:0,endCenter:CGPoint(x:1300,y:540),endRadius:850,options:[])
 let purple=CGGradient(colorsSpace:cs,colors:[CGColor(red:0.20,green:0.06,blue:0.40,alpha:0.25),CGColor(red:0.10,green:0.02,blue:0.20,alpha:0)] as CFArray,locations:[0,1])!
 c.drawRadialGradient(purple,startCenter:CGPoint(x:180,y:240),startRadius:0,endCenter:CGPoint(x:180,y:240),endRadius:720,options:[])
 return c.makeImage()!
}
let bg=background()
func ambient(_ c:CGContext,_ t:Double) {
 c.saveGState();c.translateBy(x:0,y:1080);c.scaleBy(x:1,y:-1);c.draw(bg,in:CGRect(x:0,y:0,width:W,height:H));c.restoreGState()
 for i in 0..<95 {
  let x=Double((i*731+83)%1920)+sin(t*0.08+Double(i))*8
  let y=Double((i*379+67)%850)
  let opacity=0.14+0.17*(0.5+0.5*sin(t*0.7+Double(i)))
  disc(c,x,y,i%7==0 ? 1.8 : 1,alpha(white,opacity))
 }
 for i in -9...9 {line(c,960+Double(i)*95,750,960+Double(i)*260,1080,alpha(cyan,0.045),1)}
 for i in 0..<9 {
  let q=(Double(i)+t.truncatingRemainder(dividingBy:4)/4)/9
  let y=750+q*q*360
  line(c,0,y,1920,y,alpha(cyan,0.05),1)
 }
}
func gate(_ c:CGContext,_ x:Double,_ y:Double,_ label:String,_ color:CGColor=cyan,_ active:Bool=true) {box(c,x-46,y-46,92,92,color,active ? 0.19:0.04);text(c,label,x,y-28,46,active ? white : muted,true)}

