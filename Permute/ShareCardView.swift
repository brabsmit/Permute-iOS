//
//  ShareCardView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

struct ShareCardView: View {
    let solve: Solve

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1) // Dark background

            VStack(spacing: 20) {
                Spacer()

                Text("NEW PB!")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(Color.yellow)
                    .tracking(2)

                Text(solve.formattedTime)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)

                Text(solve.scramble)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 30)

                Text(solve.date.formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)

                Spacer()

                HStack(spacing: 8) {
                    // Logo representation
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Text("P")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                    }

                    Text("PERMUTE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 30)
            }
        }
        .frame(width: 400, height: 400) // Square aspect ratio
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}

#Preview {
    ShareCardView(solve: Solve(
        id: UUID(),
        time: 12.34,
        scramble: "R U R' U'",
        date: Date(),
        penalty: .none
    ))
}
