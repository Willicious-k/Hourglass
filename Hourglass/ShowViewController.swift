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

  @IBOutlet weak var timeBar: UIProgressView!
  @IBOutlet weak var imageView: UIImageView!

  var currentImage: ImageItem! // viewModel should give UIImage or cacheKey, not URL
  var viewModel: ShowViewModel!
  var duration: Int = 0
  let frameDelta: Float = 0.03

  var disposeBag = DisposeBag()
  var timer = Observable<Int>.empty()
  var startNext = PublishSubject<Void>()
  var subscription: Disposable!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel = ShowViewModel()
    timeBar.setProgress(1.0, animated: true)

    // subscribing to slider.rx.value does not emit any event
    // because it actually requires ControlEvent
    startNext //.debug("startNext")
      .subscribe(onNext: { _ in
        self.fetchImage()
        self.renderImage()
        self.refreshTimer()
        self.refreshSubscription()
      }, onError: { error in
        print("error: \(error.localizedDescription)")
        self.navigationController?.popViewController(animated: true)
      })
      .disposed(by: disposeBag)

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

  private func fetchImage() {
    currentImage = viewModel.fetchNext()
  }

  private func renderImage() {
    guard let imageToShow = currentImage, let link = URL(string: imageToShow.media) else { return }

    imageView.kf.setImage(with: link, options: [.transition( .flipFromRight(0.3) )])
  }

  private func refreshTimer() {
    timer = Observable<Int>.interval(Double(frameDelta), scheduler: MainScheduler.instance)
                           .take(Double(duration), scheduler: MainScheduler.instance)
  }

  private func refreshSubscription() {
    subscription = timer.map { (delta) -> Float in
        let passed = Float(delta) * self.frameDelta
        let leftOver = Float(self.duration) - passed
        return leftOver / Float(self.duration)
      }
      .subscribe(onNext: { progress in
        self.timeBar.setProgress(progress, animated: true)
      }, onCompleted: {
        self.subscription.dispose()
        self.startNext.onNext(Void())
      })
  }

}
