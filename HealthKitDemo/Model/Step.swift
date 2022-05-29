//
//  Step.swift
//  HealthKitDemo
//
//  Created by Praks on 29/05/2022.
//

import Foundation
struct Step: Identifiable {
    let id = UUID()
    let count: Int
    let date: Date
}
