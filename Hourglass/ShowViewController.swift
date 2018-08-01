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
  @IBOutlet weak var imageView: UIImageView!
  var currentImage: ImageItem!

  let frameDelta: Float = 0.03

  var viewModel: ShowViewModel!
  var disposeBag = DisposeBag()

  var duration: Int = 0
  var timer = Observable<Int>.empty()
  var startNext = PublishSubject<Void>()
  var subscription: Disposable!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel = ShowViewModel()
    slider.setValue(Float(duration), animated: true)

    imageView.kf.indicatorType = .activity

    // subscribing to slider.rx.value does not emit any event
    // because it actually requires ControlEvent
    startNext //.debug("startNext")
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

    viewModel.modelReady //.debug("modelReady")
      .subscribe(onNext: {
        self.startNext.onNext(Void())
      })
      .disposed(by: disposeBag)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    viewModel = nil
    disposeBag = DisposeBag()
  }

  private func cleanAndFetch() {
    currentImage = viewModel.fetchNext()
  }

  private func renderImage() {
    guard let imageToShow = currentImage, let link = URL(string: imageToShow.media) else { return }
    print(imageToShow)

    imageView.kf.setImage(with: link, options: [.transition( .flipFromRight(0.3) )])
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
