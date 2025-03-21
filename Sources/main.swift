import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
import class CoreImage.CIImage
import class Foundation.ProcessInfo
import struct Foundation.URL

enum ImgMetaErr: Error {
  case unableToLoad
  case imageNameUnknown(String)
}

typealias IO<T> = () -> Result<T, Error>

func Bind<T, U>(
  _ i: @escaping IO<T>,
  _ f: @escaping (T) -> IO<U>
) -> IO<U> {
  return {
    let rt: Result<T, Error> = i()
    return rt.flatMap {
      let t: T = $0
      return f(t)()
    }
  }
}

func Map<T, U>(
  _ i: @escaping IO<T>,
  _ pure: @escaping (T) -> Result<U, Error>
) -> IO<U> {
  return {
    let rt: Result<T, Error> = i()
    return rt.flatMap {
      let t: T = $0
      return pure(t)
    }
  }
}

typealias ImageSource = IO<CIImage>

typealias UrlToImage = (URL) -> IO<CIImage>

typealias PrintImageMeta = (CIImage) -> IO<Void>

func envValByKey(_ key: String) -> IO<String> {
  return {
    let kvd: [String: String] = ProcessInfo.processInfo.environment
    let oval: String? = kvd[key]
    guard let val = oval else {
      return .failure(ImgMetaErr.imageNameUnknown("env var \( key ) missing"))
    }

    return .success(val)
  }
}

func url2img(_ filename: URL) -> IO<CIImage> {
  return {
    let oimg: CIImage? = CIImage(contentsOf: filename)
    guard let img = oimg else {
      return .failure(ImgMetaErr.unableToLoad)
    }

    return .success(img)
  }
}

func imetprint(_ img: CIImage) -> IO<Void> {
  return {
    let extent: CGRect = img.extent
    let size: CGSize = extent.size
    let width: Float64 = size.width
    let height: Float64 = size.height

    print("width: \( width )")
    print("height: \( height )")
    print("content headroom: \( img.contentHeadroom )")
    print("opaque: \( img.isOpaque )")
    let color: String = img.colorSpace.map { "\( $0 )" } ?? ""
    print("color: \( color )")
    for (key, val) in img.properties {
      print("property \( key ): \( val )")
    }

    return .success(())
  }
}

@main
struct ImageMetadata {
  static func main() {
    let imageName: IO<String> = envValByKey("ENV_IMAGE_NAME")
    let imgUrl: IO<URL> = Map(
      imageName,
      {
        let s: String = $0
        return .success(URL(fileURLWithPath: s))
      })

    let u2img: UrlToImage = url2img

    let img: IO<CIImage> = Bind(
      imgUrl,
      u2img
    )

    let printimg: PrintImageMeta = imetprint

    let printed: IO<Void> = Bind(
      img,
      printimg
    )

    let res: Result<_, Error> = printed()

    do {
      try res.get()
    } catch {
      print("\( error )")
    }

  }
}
