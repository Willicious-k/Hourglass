//
//  ImageModel.swift
//  Hourglass
//
//  Created by Will on 2018. 7. 31..
//  Copyright © 2018년 Cell5. All rights reserved.
//

import Foundation
import Alamofire
import Kingfisher
import RxSwift
import RxCocoa
import Runes
import Curry
import Argo

class ImageModel {

  enum ModelError: String, Error {
    case lostVC = "Lost VC"
    case connectionFailed = "connection to Flickr failed"
  }

  private let endpoint = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne?format=json")!
  private var images = BehaviorSubject<[ImageItem]>(value: [])

  let modelReady = BehaviorSubject<Bool>(value: false)
  let disposeBag = DisposeBag()

  init() {
    getFeedList() //.debug("IM init")
      .do(onSuccess: { list in
        let prefetcher = ImagePrefetcher.init(urls: self.listToURL(list) )
        prefetcher.start()
      })
      .subscribe(onSuccess: { list in
        self.images.onNext(list.items)
        self.modelReady.onNext(true)
      })
      .disposed(by: disposeBag)

    images
      .filter { (list) -> Bool in
        list.count == 2
      }
      .subscribe(onNext: { list in
        self.doPrefetch()
      })
      .disposed(by: disposeBag)
  }

  deinit {
    ImageCache.default.clearDiskCache()
    ImageCache.default.clearMemoryCache()
  }

  func fetchNext() -> ImageItem {
    guard var list = try? images.value() else {
      return ImageItem(title: " ", link: " ", author: " ", media: " ")
    }
    let next = list.removeFirst()
    images.onNext(list)
    return next
  }

  private func getFeedList() -> Single<ImageList> {
    return Single.create(subscribe: { [weak self] (maker) -> Disposable in
      guard let `self` = self else {
        maker(SingleEvent.error(ModelError.lostVC))
        return Disposables.create()
      }

      Alamofire.request(self.endpoint)
        .validate(statusCode: 200..<399)
        .responseData { (response) in
          if let _ = response.error {
            maker(SingleEvent.error(ModelError.connectionFailed))
          }

          if let data = response.data {
            // removes unnecessary wrapper: jsonFlickrFeed( {...} )
            let result = data.dropFirst(15).dropLast(1)

            // if crashes, fixed format has changed
            let list = ImageList.decode( Argo.JSON(try! JSONSerialization.jsonObject(with: result) ) )
            maker(SingleEvent.success(list.value!))
          }
      }
      return Disposables.create()
    })
  }

  private func doPrefetch() {
    getFeedList()
      .do(onSuccess: { list in
        let prefetcher = ImagePrefetcher.init(urls: self.listToURL(list))
        prefetcher.start()
      })
      .subscribe(onSuccess: { list in
        if let oldList = try? self.images.value() {
          let newList = oldList + list.items
          print("\(oldList.count) -> \(newList.count)")
          self.images.onNext(newList)
        }
      })
      .disposed(by: disposeBag)
  }

  private func listToURL(_ list: ImageList) -> [URL] {
    let items = list.items
    let urls = items.map { (item) -> URL in
      return URL(string: item.media)! // if this crashes, URL from Flickr is wrong
    }
    return urls
  }

}

//MARK:- DataModel Description
struct ImageList {
  let items: [ImageItem]
}

extension ImageList: Argo.Decodable {

  static func decode(_ json: JSON) -> Decoded<ImageList> {
    let initialized = curry(ImageList.init)
      <^> json <|| "items"

    return initialized
  }
}

struct ImageItem {
  let title: String
  let link: String
  let author: String
  let media: String
}

extension ImageItem: Argo.Decodable {
  static func decode(_ json: JSON) -> Decoded<ImageItem> {
    let initialized = curry(ImageItem.init)
      <^> json <| "title"
      <*> json <| "link"
      <*> json <| "author"
      <*> json <| ["media", "m"]

    return initialized
  }
}
