//
//  Scales.swift
//  Circular Bells
//
//  Created by Andrea Franceschini on 02/12/2020.
//

import Foundation

struct Scale: Codable {
    let id: String;
    let name: [String: String];
    let notes: [Int];
}

typealias Scales = [Scale];
