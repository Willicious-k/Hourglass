//
//  ShowViewModel.swift
//  Hourglass
//
//  Created by Will on 2018. 7. 24..
//  Copyright © 2018년 Cell5. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import Argo

class ShowViewModel {

  enum ModelError: String, Error {
    case lostVC = "Lost showVC"
    case connectionFailed = "connection to Flickr failed"
  }

  private let endpoint = URL(string: "https://api.flickr.com/services/feeds/photos_public.gne?format=json")!
  private var images = BehaviorSubject<[ImageItem]>(value: [])

  let modelReady = PublishSubject<Void>()
  let disposeBag = DisposeBag()

  init() {
    getFeedList() //.debug("VM init")
      .subscribe(onSuccess: { list in
        self.images.onNext(list.items)
        self.modelReady.onNext(Void())
      })
      .disposed(by: disposeBag)

    images
      .filter { (list) -> Bool in
        list.count == 2
      }
      .subscribe(onNext: { list in // list.count == 2
        self.doPrefetch()
      })
      .disposed(by: disposeBag)
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
      .subscribe(onSuccess: { list in
        if let oldList = try? self.images.value() {
          let newList = oldList + list.items
          print("\(oldList.count) -> \(newList.count)")
          self.images.onNext(newList)
        }
      })
      .disposed(by: disposeBag)
  }

}
