//
//  ImageModel.swift
//  Hourglass
//
//  Created by Will on 2018. 7. 31..
//  Copyright © 2018년 Cell5. All rights reserved.
//

import Foundation
import Runes
import Curry
import Argo


//MARK:- DataModel Description
struct ImageList {
  let items: [ImageItem]
}

extension ImageList: Argo.Decodable {
  static func decode(_ json: JSON) -> Decoded<ImageList> {
    return curry(ImageList.init)
      <^> json <|| "items"
  }
}

struct ImageItem {
  let title: String
  let link: String
  let author: String
}

extension ImageItem: Argo.Decodable {
  static func decode(_ json: JSON) -> Decoded<ImageItem> {
    return curry(ImageItem.init)
      <^> json <| "title"
      <*> json <| "link"
      <*> json <| "author"
  }
}
