//
//  SplashViewController.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import UIKit
import HealthKit

class SplashViewController: UIViewController {
  
  @IBOutlet weak var statusLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupHealthKit()
  }

  private func setupHealthKit() {
    let _ = HealthKitHelper.shared.$authStatus
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { status in
        self.statusLabel?.text = status
      }
    
    HealthKitHelper.shared.dataNotAvailableBlock = { [weak self] in
      let alertController = UIAlertController(
        title: "Health Data Unavailable",
        message: "Unable to access health data. Check device capabilities.",
        preferredStyle: .alert)
      let action = UIAlertAction(title: "Dismiss", style: .default)
      
      alertController.addAction(action)
      
      self?.present(alertController, animated: true)
    }
    
    HealthKitHelper.shared.getAuthorizationStatus()
  }
  
  @IBAction func didTapAuthorizeButton(_ sender: Any) {
    HealthKitHelper.shared.requestAuthorization() { [weak self] in
      DispatchQueue.main.async {
        let stepsVC = StepsTableViewController()
        self?.navigationController?.setViewControllers([stepsVC], animated: true)
      }
    }
  }

}
