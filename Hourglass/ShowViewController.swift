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

  @IBOutlet weak var slider: UISlider!

  let disposeBag = DisposeBag()
  let viewModel = ShowViewModel()
  var duration: Int = 0
  var currentImage: ImageItem!

  var timer = Observable<Int>.empty()
  var subscription: Disposable!
  let restartSubject = PublishSubject<Void>()

  override func viewDidLoad() {
    super.viewDidLoad()
    slider.setValue(Float(duration), animated: true)

    restartSubject
      .subscribe(onNext: {
        //restart subscrption, restart timer
        self.timer = Observable<Int>.interval(0.03, scheduler: MainScheduler.instance)
                                    .take(Double(self.duration), scheduler: MainScheduler.instance)
        self.makeSubscription()
      })
    .disposed(by: disposeBag)

    restartSubject.onNext(Void())
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  private func makeSubscription() {
    subscription = timer.debug("timer?")
      .map({ (i) -> Float in
        Float(i) * (0.03)
      })
      .subscribe(onNext: { value in
        let timeLeft = Float(self.duration) - value
          self.slider.setValue(timeLeft, animated: true)
      }, onCompleted: {
        self.subscription.dispose()
        self.restartSubject.onNext(Void())
      })
  }

}
