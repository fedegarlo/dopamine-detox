import Foundation
import SwiftUI
import UIKit

struct DetoxInterventionWall: View {
    let intervention: DetoxIntervention
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 54))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 12)

                    VStack(spacing: 12) {
                        Text("Respira antes de abrir \(intervention.displayName)")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("Estás en pleno detox. Date unos segundos para reconectar contigo antes de entrar en \(intervention.displayName). Si lo necesitas puedes continuar igualmente.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Recuerda tu porqué", systemImage: "sparkles")
                            .font(.headline)
                        Text("Piensa en cómo te quieres sentir hoy y qué harías con el tiempo que recuperarás si pospones esta app unos minutos más.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label("Plan B", systemImage: "checkmark.circle")
                            .font(.headline)
                        Text("Si decides continuar, vuelve luego a Dopamine Detox para registrar cómo te fue. Cada decisión consciente suma.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(spacing: 12) {
                        Button {
                            onDismiss()
                        } label: {
                            Text("Seguir en detox")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        if let redirectURL = intervention.redirectURL {
                            Button {
                                onDismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    UIApplication.shared.open(redirectURL, options: [:], completionHandler: nil)
                                }
                            } label: {
                                Text("Continuar a \(intervention.displayName)")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear {
            onDismiss()
        }
    }
}

#Preview {
    DetoxInterventionWall(
        intervention: DetoxIntervention(appName: "Instagram", redirectURL: URL(string: "instagram://app")),
        onDismiss: {}
    )
}
