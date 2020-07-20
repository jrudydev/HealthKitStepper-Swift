//
//  StepStatistic.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation

struct StepsStatistic: Hashable {
  let startDate: Date
  let steps: Int
}

extension StepsStatistic: Comparable {
  static func ==(lhs: StepsStatistic, rhs: StepsStatistic) -> Bool {
    return lhs.steps == rhs.steps
  }
  
  static func <(lhs: StepsStatistic, rhs: StepsStatistic) -> Bool {
    return lhs.steps == rhs.steps
  }
}
