import AppKit
import SwiftUI

struct TickedSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var tickCount: Int = 19

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(
            value: value,
            minValue: range.lowerBound,
            maxValue: range.upperBound,
            target: context.coordinator,
            action: #selector(Coordinator.valueChanged(_:))
        )
        slider.isContinuous = true
        slider.numberOfTickMarks = tickCount
        slider.tickMarkPosition = .below
        slider.allowsTickMarkValuesOnly = false
        slider.controlSize = .regular
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        if nsView.doubleValue != value {
            nsView.doubleValue = value
        }
        nsView.minValue = range.lowerBound
        nsView.maxValue = range.upperBound
        nsView.numberOfTickMarks = tickCount
    }

    final class Coordinator: NSObject {
        @Binding var value: Double

        init(value: Binding<Double>) {
            _value = value
        }

        @objc func valueChanged(_ sender: NSSlider) {
            value = sender.doubleValue
        }
    }
}
