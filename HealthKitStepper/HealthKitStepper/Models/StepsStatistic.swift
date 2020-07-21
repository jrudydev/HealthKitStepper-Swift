//
//  StepStatistic.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation

public struct StepsStatistic: Hashable {
  let startDate: Date
  let steps: Int
}

extension StepsStatistic: Comparable {
  public static func ==(lhs: StepsStatistic, rhs: StepsStatistic) -> Bool {
    return lhs.steps == rhs.steps
  }
  
  public static func <(lhs: StepsStatistic, rhs: StepsStatistic) -> Bool {
    return lhs.steps < rhs.steps
  }
}
