//
//  TwoFingerTapView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI
import UIKit

struct TwoFingerTapView: UIViewRepresentable {
    var onTwoFingerTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        gesture.numberOfTouchesRequired = 2
        gesture.cancelsTouchesInView = false // Allow touches to pass through
        view.addGestureRecognizer(gesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: onTwoFingerTap)
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            if sender.state == .ended {
                action()
            }
        }
    }
}
