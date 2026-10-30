import Foundation
import AVFoundation

do {
 let mode=CommandLine.arguments.dropFirst().first ?? "preview"
 switch mode {
 case "audio": try makeAudio()
 case "preview": try preview()
 case "render": try render()
 case "sample": try render(0,300)
 case "mux": try mux()
 default: print("Usage: quantum-film audio|preview|render|sample|mux"); exit(1)
 }
} catch { fputs("ERROR: \(error)\n",stderr); exit(1) }
