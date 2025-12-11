//
//  PassportCardView.swift
//  Permute
//
//  Created by Jules for WCA Profile Integration.
//

import SwiftUI

struct PassportCardView: View {
    let user: WCAUser

    var body: some View {
        HStack(spacing: 20) {
            // Avatar
            if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(user.name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                if let wcaID = user.wcaID {
                    Text(wcaID)
                        .font(.headline)
                        .monospaced()
                        .foregroundColor(.yellow)
                } else {
                    Text("No WCA ID")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.gray)
                }

                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(user.countryISO2)
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        PassportCardView(user: WCAUser(
            id: 1,
            wcaID: "2025SMIT01",
            name: "John Smith",
            countryISO2: "US",
            avatarURL: "https://www.worldcubeassociation.org/assets/wca_logo.png"
        ))
        .padding()
    }
}
