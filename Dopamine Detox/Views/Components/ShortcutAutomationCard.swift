import Foundation
import SwiftUI
import UIKit

struct ShortcutAutomationCard: View {
    @State private var appName: String = "Instagram"
    @State private var redirectTarget: String = "instagram://app"
    @State private var didCopyLink = false

    private var shortcutURL: URL? {
        var components = URLComponents()
        components.scheme = AppConfiguration.detoxInterventionScheme
        components.host = AppConfiguration.detoxInterventionHost

        var items: [URLQueryItem] = []
        if !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "app", value: appName))
        }
        if !redirectTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "redirect", value: redirectTarget))
        }
        components.queryItems = items.isEmpty ? nil : items

        return components.url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Automatiza tus muros")
                    .font(.headline)
            } icon: {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                StepView(number: 1, text: "En la app Atajos, crea una Automatización Personal al abrir la app que te distrae.")
                StepView(number: 2, text: "Selecciona Ejecutar Atajo y elige el atajo Dopamine Detox (lo verás tras crearlo una vez).")
                StepView(number: 3, text: "Configura el atajo para abrir este enlace personalizado y mostrarte el muro de calma antes de continuar.")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Personaliza el enlace")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TextField("Nombre de la app", text: $appName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)

                TextField("URL para continuar", text: $redirectTarget)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)

                if let urlString = shortcutURL?.absoluteString {
                    Text(urlString)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

                Button {
                    if let urlString = shortcutURL?.absoluteString {
                        UIPasteboard.general.string = urlString
                        didCopyLink = true
                    }
                } label: {
                    Label("Copiar enlace para Atajos", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if didCopyLink {
                    Text("Enlace copiado. Pégalo en la acción \"Abrir URL\" de tu atajo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                Link("Abrir la app Atajos", destination: URL(string: "shortcuts://")!)
                    .font(.footnote)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.default, value: didCopyLink)
        .onChange(of: appName) { _ in
            didCopyLink = false
        }
        .onChange(of: redirectTarget) { _ in
            didCopyLink = false
        }
    }
}

private struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    ShortcutAutomationCard()
        .padding()
}
