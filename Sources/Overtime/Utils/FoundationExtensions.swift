//
//  FoundationExtensions.swift
//  
//
//  Created by Daniel Baldonado on 9/11/24.
//

import Foundation
import Combine

extension ProcessInfo.ThermalState {
    public var stringValue: String {
        switch self {
        case .critical:
            return "critical"
        case .fair:
            return "fair"
        case .nominal:
            return "nominal"
        case .serious:
            return "serious"
        @unknown default:
            return "unknown"
        }
    }
}

extension Double {
    public func withPrecision(_ precision: Int) -> String {
        let factor = pow(10.0, Double(precision))
        if Int(self * factor) == Int(self) * Int(factor) {
            return String(format: "%0.0f", self)
        } else {
            return String(format: "%0.\(precision)f", self)
        }
    }

    public var truncatedString: String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}

extension Int {
    public var kString: String {
        self >= Int(1e12) ?
            "\( (Double(self) / 1e12).withPrecision(1) )t"
            : self >= Int(1e9) ?
            "\( (Double(self) / 1e9).withPrecision(1) )b"
            : self >= Int(1e6) ?
            "\( (Double(self) / 1e6).withPrecision(1) )m"
            : self >= Int(1e3) ?
            "\( (Double(self) / 1e3).withPrecision(1) )k"
            : "\(self)"
    }

    public var ordinal: String {
        "\(self)\(self % 10 == 1 && self != 11 ? "st" : self % 10 == 2 && self != 12 ? "nd" : self % 10 == 3 && self != 13 ? "rd" : "th" )"
    }

    public var timeString: String {
        let (minutes, seconds) = (self / 60, self % 60)
        return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
}

public class Throttle<T> {
    let cancellable: AnyCancellable?
    let subject = PassthroughSubject<T, Never>()

    public init(for stride: RunLoop.SchedulerTimeType.Stride, closure: @escaping (T) -> Void) {
        cancellable = subject
            .throttle(for: stride, scheduler: RunLoop.main, latest: true)
            .sink { arg in
                closure(arg)
            }
    }

    public func send(_ arg: T) {
        subject.send(arg)
    }
}

public extension Throttle where T == Void {
    public func send() {
        subject.send()
    }
}

public class Debounce<T> {
    let cancellable: AnyCancellable?
    let subject = PassthroughSubject<T, Never>()

    public init(for stride: RunLoop.SchedulerTimeType.Stride, closure: @escaping (T) -> Void) {
        cancellable = subject
            .debounce(for: stride, scheduler: RunLoop.main)
            .sink { arg in
                closure(arg)
            }
    }

    public func send(_ arg: T) {
        subject.send(arg)
    }
}

public extension Debounce where T == Void {
    func send() {
        subject.send()
    }
}
