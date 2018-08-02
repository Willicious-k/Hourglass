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

  let frameDelta: Float = 0.03

  @IBOutlet weak var timeBar: UIProgressView!
  @IBOutlet weak var leftImageView: UIImageView!
  @IBOutlet weak var rightImageView: UIImageView!
  @IBOutlet weak var leftImageCenterX: NSLayoutConstraint!
  @IBOutlet weak var rightImageCenterX: NSLayoutConstraint!
  
  var nextItem: ImageItem! // url is cacheKey
  var willMoveToLeft: Bool = false
  var imageModel: ImageModel!
  var duration: Int = 0

  var disposeBag = DisposeBag()
  var timer = Observable<Int>.empty()
  var startNext = PublishSubject<Void>()
  var subscription: Disposable!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    timeBar.setProgress(1.0, animated: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // subscribing to slider.rx.value does not emit any event
    // because it actually requires ControlEvent
    startNext //.debug("startNext")
      .subscribe(onNext: { _ in
        self.willMoveToLeft = !self.willMoveToLeft
        self.prepareNextImage()
        self.renderShow()
        self.refreshTimer()
        self.refreshSubscription()
      }, onError: { error in
        print("error: \(error.localizedDescription)")
        self.navigationController?.popViewController(animated: true)
      })
      .disposed(by: disposeBag)

    imageModel.modelReady //.debug("modelReady")
      .filter({ (ready) -> Bool in
        ready
      })
      .subscribe(onNext: { _ in
        self.startNext.onNext(Void())
      })
      .disposed(by: disposeBag)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    disposeBag = DisposeBag()
  }

  private func prepareNextImage() {
    nextItem = imageModel.fetchNext()
    guard let url = URL(string: nextItem.media) else { return }

    if willMoveToLeft {
      rightImageView.kf.setImage(with: url)
    } else {
      leftImageView.kf.setImage(with: url)
    }
  }

  private func renderShow() {
    if willMoveToLeft {
      leftImageCenterX.constant = -(UIScreen.main.nativeBounds.width / 2.0)
      rightImageCenterX.constant = 0
    } else {
      leftImageCenterX.constant = 0
      rightImageCenterX.constant = (UIScreen.main.nativeBounds.width / 2.0)
    }

    UIView.animate(withDuration: 0.3, animations: {
      self.view.layoutIfNeeded()
      if self.willMoveToLeft {
        self.leftImageView.alpha = 0.0
        self.rightImageView.alpha = 1.0
      } else {
        self.leftImageView.alpha = 1.0
        self.rightImageView.alpha = 0.0
      }
    }, completion: nil)
  }

  private func refreshTimer() {
    timer = Observable<Int>.interval(Double(frameDelta), scheduler: MainScheduler.instance)
                           .take(Double(duration), scheduler: MainScheduler.instance)
  }

  private func refreshSubscription() {
    subscription = timer.map { (delta) -> Float in
        let passed = Float(delta) * self.frameDelta
        if self.willMoveToLeft {
          let leftOver = Float(self.duration) - passed
          return leftOver / Float(self.duration)
        } else {
          return passed / Float(self.duration)
        }
      }
      .subscribe(onNext: { progress in
        self.timeBar.setProgress(progress, animated: false)
      }, onCompleted: {
        self.subscription.dispose()
        self.startNext.onNext(Void())
      })
  }

}
