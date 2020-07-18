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
