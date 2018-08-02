//
//  ViewController.swift
//  Hourglass
//
//  Created by Will on 2018. 7. 24..
//  Copyright © 2018년 Cell5. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LandingViewController: UIViewController {

  @IBOutlet weak var timer: UISlider!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!

  var imageModel: ImageModel!
  let disposeBag = DisposeBag()

  @IBAction func unwindToLanding(segue: UIStoryboardSegue) { }

  override func viewDidLoad() {
    super.viewDidLoad()

    timer.rx.value
      .filter { value in
        value < 1
      }.subscribe(onNext: { value in
        self.startButton.isEnabled = false
      }).disposed(by: disposeBag)

    timer.rx.value
      .filter { value in
        value >= 1
      }.subscribe(onNext: { value in
        self.startButton.isEnabled = true
      }).disposed(by: disposeBag)

    timer.rx.value
      .subscribe(onNext: { value in
        let second = Int(value)
        self.durationLabel.text = String(second)
      }).disposed(by: disposeBag)

    let events = ControlEvent.merge([timer.rx.controlEvent(UIControlEvents.touchDown).asObservable(),
                                     timer.rx.controlEvent(UIControlEvents.touchUpInside).asObservable(),
                                     timer.rx.controlEvent(UIControlEvents.touchUpOutside).asObservable()])
    events.subscribe(onNext: {
      let value = Int(self.timer.value)
        self.durationLabel.text = "\(value) seconds"
        self.timer.setValue(Float(value), animated: true)
      }).disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    durationLabel.text = " "
    startButton.isEnabled = false
    timer.setValue(Float(0.0), animated: false)
    imageModel = ImageModel()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let dest = segue.destination as? ShowViewController {
      dest.duration = Int(timer.value)
      dest.imageModel = imageModel
    }
  }

}

