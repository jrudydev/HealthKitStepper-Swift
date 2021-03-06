//
//  StatsViewModel.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/20/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation
import Combine


/// These values are used to send and debounce debounce requests to the datasouce
let kDebounceThreshold: Int = 3
let kRefreshRate: Double = 60.0

let kStepsFormat: String = "%.2f"
let kStepsMaxInteger: Int = 99999

/// This protocol defines a method to fetch data, the properties should be observed by the view controller
protocol StatsDataSource {
  var stepsForToday: Double { get set }
  var stepHistory: [StepsStatistic] { get set }
  var error: Error? { get set }
  
  var dailyAvg: Double { get }
  var dailyMin: Int { get }
  var dailyMax: Int { get }
  
  func fetchStats() -> Bool
}


class StatsViewModel {
  
  enum StatsError: Error {
    case noPermission
    case authError
    case readError
  }
  
  enum Metric {
    case min
    case max
    case avg
    
    var prev: Metric {
      switch self {
      case .min: return .avg
      case .max: return .min
      case .avg: return .max
      }
    }
    
    var next: Metric {
      switch self {
      case .min: return .max
      case .max: return .avg
      case .avg: return .min
      }
    }
  }
  
  /// Observable properties that can be used to update the UI.
  @Published public internal (set) var stepsForToday: Double = 0
  @Published public internal (set) var stepHistory = [StepsStatistic]()
  @Published public internal (set) var error: Error? = nil
  
  public private (set) var isChronological = true
  
  private var lastFetched: Date? = nil
  public private (set) var currentMetric: Metric = .avg
  
  private var subscriptions = Set<AnyCancellable>()
  
  init() {
    HealthKitHelper.shared.dataNotAvailableBlock = { [weak self] in
      self?.error = StatsError.noPermission
    }
    
    let _ = Timer.publish(every: kRefreshRate, on: RunLoop.main, in: .common)
      .autoconnect()
      .sink { _ in
        print("Refreshing steps...")
        self.fetchStats()
      }
      .store(in: &subscriptions)
  }
  
  internal var fetchBlock: () -> Void {
    return {
      HealthKitHelper.shared.getTodaysSteps() { steps, error in
        guard error == nil else { self.error = error!; return }
        
        self.stepsForToday = steps
      }
      HealthKitHelper.shared.getStepHistory() { result, error in
        guard error == nil else { self.error = error!; return }
        
        self.stepHistory = result.reversed()
        self.isChronological = true
      }
    }
  }
  
  public var metricLabel: String {
    switch self.currentMetric {
    case .min: return "Minimum: \(self.dailyMin.shortString)"
    case .max: return "Maximum: \(self.dailyMax.shortString)"
    case .avg: return "Average: \(self.dailyAvg.shortString)"
    }
  }
  
  public func prevMetricTapped() {
    self.currentMetric = self.currentMetric.prev
  }
  
  public func nextMetricTapped() {
    self.currentMetric = self.currentMetric.next
  }
  
  public func toggleOrder() {
    self.stepHistory.reverse()
    self.isChronological.toggle()
  }
}

extension StatsViewModel: StatsDataSource {
  public var dailyAvg: Double {
    guard self.stepHistory.count > 0 else { return 0.0 }
    
    let total: Int = self.stepHistory.reduce(0) { $0 + $1.steps }
    return Double(total) / Double(self.stepHistory.count)
  }
  
  public var dailyMin: Int {
    return self.stepHistory.min()?.steps ?? 0
  }
  
  public var dailyMax: Int {
    return self.stepHistory.max()?.steps ?? 0
  }
  
  public func authorize() {
    HealthKitHelper.shared.getAuthorizationStatus()
  }
  
  @discardableResult
  public func fetchStats() -> Bool {
    return self.fetchStatsIfNeeded()
  }

  private func fetchStatsIfNeeded() -> Bool {
    guard let lastFetched = self.lastFetched else {
      self.fetchBlock()
      self.lastFetched = Date()
      return true
    }
    
    let debounceCutoff = Calendar.current.date(byAdding: .second,
                                               value: kDebounceThreshold,
                                               to: lastFetched)!
    guard Date() > debounceCutoff else {
      return false
    }
    
    self.fetchBlock()
    self.lastFetched = Date()
    return true
  }
}

extension Int {
  var shortString: String {
    guard self > kStepsMaxInteger else { return "\(self)" }
    
    let newUnitvalue = Double(self) / 1000
    return String(format: kStepsFormat, newUnitvalue)
  }
}

extension Double {
  var shortString: String {
    guard self > Double(kStepsMaxInteger) else { return String(format: "%.0f", self) }
    
    let newUnitvalue = self / 1000
    return String(format: kStepsFormat, newUnitvalue)
  }
}

extension StepsStatistic {
  var startDateLabel: String {
    let startDate = DateFormatter()
    startDate.dateFormat = "MMM d"
    
    return startDate.string(from: self.startDate)
  }
  
  var dayOfWeekLabel: String {
    let dow = DateFormatter()
    dow.dateFormat = "E"
    
    return dow.string(from: self.startDate)
  }
}
