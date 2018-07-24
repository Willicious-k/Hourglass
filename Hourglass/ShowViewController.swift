//
//  ShowViewController.swift
//  Hourglass
//
//  Created by Will on 2018. 7. 24..
//  Copyright © 2018년 Cell5. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher

class ShowViewController: UIViewController {

  enum Request {
    case initialized(Int)
    case nextImage
    case secChanged(Int)
  }

  @IBOutlet weak var timer: UISlider!
  @IBOutlet weak var durationLabel: UILabel!

  let disposeBag = DisposeBag()
  let viewModel = ShowViewModel()
  var initialDuration: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    timer.setValue(Float(initialDuration), animated: true)
  }

}
