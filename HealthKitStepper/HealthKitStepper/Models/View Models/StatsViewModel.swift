//
//  StatsViewModel.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/20/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation
import Combine


/// This protocol defines a method that fetches the data, the response should be observed by the view controller
protocol StatsDataSource {
  var authStatus: String { get set }
  var stepsForToday: Double { get set }
  var stepHistory: [StepsStatistic] { get set }
  var error: Error? { get set }
  
  var dailyAvg: Double { get }
  var dailyMin: Double { get }
  var dailyMax: Double { get }
  
  func fetchStats()
}


class StatsViewModel {
  
  enum StatsError: Error {
    case noPermission
    case authError
    case readError
  }
  
  /// Observable properties that can be used to update the UI.
  @Published public internal (set) var authStatus = "Checking HealthKit authorization status..."
  @Published public internal (set) var stepsForToday: Double = 0
  @Published public internal (set) var stepHistory = [StepsStatistic]()
  @Published public internal (set) var error: Error? = nil
  
  public private (set) var isChronological = true
  
  init() {
    HealthKitHelper.shared.dataNotAvailableBlock = { [weak self] in
      self?.error = StatsError.noPermission
    }
  }
}

extension StatsViewModel: StatsDataSource {
  public var dailyAvg: Double {
    return 0.0
  }
  public var dailyMin: Double {
    return 0.0
  }
  public var dailyMax: Double {
    return 0.0
  }
  
  public func authorize() {
    HealthKitHelper.shared.getAuthorizationStatus()
  }
  
  public func fetchStats() {
//    HealthKitHelper.shared.getTodaysSteps()
//    HealthKitHelper.shared.getStepHistory()
  }
}

extension Double {
  var shortString: String {
    guard self > 99999 else { return String(format: "%.0", self) }
    
    let newUnitvalue = self / 1000
    return String(format: "%.2", newUnitvalue)
  }
}
