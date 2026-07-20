import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 3 else { FileHandle.standardError.write("usage: knockout in.png out.png\n".data(using:.utf8)!); exit(2) }
let inURL = URL(fileURLWithPath: args[1]), outURL = URL(fileURLWithPath: args[2])

guard let src = CGImageSourceCreateWithURL(inURL as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("load") }
let w = img.width, h = img.height
let cs = CGColorSpaceCreateDeviceRGB()
var buf = [UInt8](repeating: 0, count: w*h*4)
let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x:0,y:0,width:w,height:h))

// white -> alpha via distance-from-white, feathered 5..26, true colors preserved
var minX=w, minY=h, maxX = -1, maxY = -1
for y in 0..<h { for x in 0..<w {
    let i=(y*w+x)*4
    let r=Int(buf[i]), g=Int(buf[i+1]), b=Int(buf[i+2])
    let d = 255 - min(r,min(g,b))
    var a: Int
    if d <= 5 { a = 0 } else if d >= 26 { a = 255 } else { a = (d-5)*255/21 }
    buf[i+3] = UInt8(a)
    if a > 12 { if x<minX{minX=x}; if x>maxX{maxX=x}; if y<minY{minY=y}; if y>maxY{maxY=y} }
}}
guard maxX >= minX else { fatalError("empty") }

let data = Data(buf)
let provider = CGDataProvider(data: data as CFData)!
let out = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4,
                  space: cs, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
let cropped = out.cropping(to: CGRect(x: minX, y: minY, width: maxX-minX+1, height: maxY-minY+1))!
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, cropped, nil)
CGImageDestinationFinalize(dest)
print("cropped \(cropped.width)x\(cropped.height) from \(w)x\(h)  bbox x\(minX)..\(maxX) y\(minY)..\(maxY)")
