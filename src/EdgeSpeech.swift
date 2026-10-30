import Foundation
import CryptoKit
final class SpeechDelegate: NSObject, URLSessionWebSocketDelegate {
 func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) { print("SOCKET OPEN"); fflush(stdout) }
 func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) { print("SOCKET CLOSE \(closeCode.rawValue) \(reason.flatMap{String(data:$0,encoding:.utf8)} ?? "")"); fflush(stdout) }
}

@main struct EdgeSpeech {
 static func main() async {
  do {
   let token="6A5AA1D4EAFF4E9FB37E23D68491D6F4"
   let guid={UUID().uuidString.replacingOccurrences(of:"-",with:"")}
   let version="143.0.3650.75"
   let now=Date().timeIntervalSince1970+11644473600.0
   let ticks=Int64(floor(now/300)*300*10000000)
   let legacyDigest=SHA256.hash(data:Data("\(ticks)\(token)".utf8)).map{String(format:"%02X",$0)}.joined()
   let digest=ProcessInfo.processInfo.environment["EDGE_GEC_TOKEN"] ?? legacyDigest
   let endpoint="wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=\(token)&ConnectionId=\(guid())&Sec-MS-GEC=\(digest)&Sec-MS-GEC-Version=2-\(version)"
   var request=URLRequest(url:URL(string:endpoint)!)
   request.timeoutInterval=35
   let headers=["Origin":"chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold","User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0","Pragma":"no-cache","Cache-Control":"no-cache","Cookie":"muid=\(guid());"]
   for (k,v) in headers {request.setValue(v,forHTTPHeaderField:k)}
   let config=URLSessionConfiguration.default;config.timeoutIntervalForRequest=35;config.timeoutIntervalForResource=60
   let delegate=SpeechDelegate();let session=URLSession(configuration:config,delegate:delegate,delegateQueue:nil)
   let ws=session.webSocketTask(with:request);ws.resume()
   let formatter=DateFormatter();formatter.locale=Locale(identifier:"en_US_POSIX");formatter.timeZone=TimeZone(secondsFromGMT:0);formatter.dateFormat="EEE MMM dd yyyy HH:mm:ss 'GMT+0000 (Coordinated Universal Time)'"
   let timestamp=formatter.string(from:Date())
   let text=CommandLine.arguments.count>1 ? try String(contentsOfFile:CommandLine.arguments[1],encoding:.utf8) : "量子计算，究竟是一场革命，还是被误解的魔法？"
   let escaped=text.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;")
   let speechConfig="X-Timestamp:\(timestamp)\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"true\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}\r\n"
   try await ws.send(.string(speechConfig))
   let ssml="<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='Microsoft Server Speech Text to Speech Voice (zh-CN, YunxiNeural)'><prosody pitch='+0Hz' rate='+0%' volume='+0%'>\(escaped)</prosody></voice></speak>"
   try await ws.send(.string("X-RequestId:\(guid())\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:\(timestamp)Z\r\nPath:ssml\r\n\r\n\(ssml)"))
   var audio=Data();var metadata=[String]()
   while true {
    let message=try await ws.receive()
    switch message {
    case .string(let s):
     if s.contains("Path:turn.end"){break}
     if s.contains("Path:audio.metadata"){metadata.append(s)}
     continue
    case .data(let data):
     if data.count>=2 {
      let n=Int(data[0])*256+Int(data[1])
      if data.count>n+2 {audio.append(data[(n+2)...])}
     }
     continue
    @unknown default:continue
    }
    break
   }
   ws.cancel(with:.normalClosure,reason:nil);session.invalidateAndCancel()
   guard audio.count>1000 else{throw NSError(domain:"No audio returned",code:1)}
   let out=CommandLine.arguments.count>2 ? CommandLine.arguments[2] : "assets/audio/yunxi-probe.mp3"
   try audio.write(to:URL(fileURLWithPath:out))
   try JSONEncoder().encode(metadata).write(to:URL(fileURLWithPath:out+".boundaries.json"));print("READY \(out) \(audio.count) bytes")
  } catch {fputs("EDGE ERROR: \(error)\n",stderr);exit(1)}
 }
}

