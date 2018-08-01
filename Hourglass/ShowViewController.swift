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

  var currentImage: ImageItem!
  var imageView: UIImageView!

  let frameDelta: Float = 0.03
  let disposeBag = DisposeBag()
  let viewModel = ShowViewModel()

  var duration: Int = 0
  var timer = Observable<Int>.empty()
  var startNext = PublishSubject<Void>()
  var subscription: Disposable!

  override func viewDidLoad() {
    super.viewDidLoad()
    slider.setValue(Float(duration), animated: true)

    // subscribing to slider.rx.value does not emit any event
    // because it actually requires ControlEvent
    startNext
      .subscribe(onNext: { _ in
        self.cleanAndFetch()
        self.renderImage()
        self.refreshTimer()
        self.refreshSubscription()
      }, onError: { error in
        print("error: \(error.localizedDescription)")
        self.navigationController?.popViewController(animated: true)
      })
      .disposed(by: disposeBag)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    viewModel.modelReady
      .subscribe(onNext: {
        self.startNext.onNext(Void())
      })
      .disposed(by: disposeBag)
  }

  private func cleanAndFetch() {
    if let displaying = imageView {
      displaying.removeFromSuperview()
    }
    currentImage = viewModel.fetchNext()
    print(currentImage)
  }

  private func renderImage() {
    guard let imageToShow = currentImage else { return }
  }

  private func refreshTimer() {
    timer = Observable<Int>.interval(Double(frameDelta), scheduler: MainScheduler.instance)
                           .take(Double(duration), scheduler: MainScheduler.instance)
  }

  private func refreshSubscription() {
    subscription = timer.map { (delta) -> Float in
        let passed = Float(delta) * self.frameDelta
        return Float(self.duration) - passed
      }
      .subscribe(onNext: { sec in
        self.slider.setValue(sec, animated: true)
      }, onCompleted: {
        self.subscription.dispose()
        self.startNext.onNext(Void())
      })
  }

}
