import Foundation
import SwiftUI
import UIKit

struct ShortcutAutomationCard: View {
    @State private var appName: String = "Instagram"
    @State private var redirectTarget: String = "instagram://app"
    @State private var didCopyLink = false
    @State private var showingInstructions = false

    private var shortcutURL: URL? {
        AppConfiguration.makeDetoxInterventionURL(appName: appName, redirectTarget: redirectTarget)
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

            Text("Crea una automatización personal que abra Dotox antes de tus apps más tentadoras.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                showingInstructions = true
            } label: {
                Label("Añadir app", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

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
        .sheet(isPresented: $showingInstructions) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Sigue estos pasos para mostrar el muro de calma antes de abrir una app concreta.")
                            .font(.subheadline)

                        VStack(alignment: .leading, spacing: 16) {
                            StepView(number: 1, text: "En la app Atajos, crea una Automatización Personal al abrir la app que te distrae.")
                            StepView(number: 2, text: "Pulsa Añadir acción, ve a Apps → Dotox y selecciona \"Mostrar muro de calma\".")
                            StepView(number: 3, text: "Rellena el nombre de la app y pega el enlace personalizado. Desactiva \"Preguntar antes de ejecutar\".")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Si no ves Dotox en la lista de apps, ábrela una vez y vuelve a Atajos para actualizar las acciones disponibles.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Text("El campo \"URL para continuar\" te permite volver automáticamente a la app original tras completar el muro de calma.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Link("Abrir la app Atajos", destination: URL(string: "shortcuts://")!)
                            .font(.footnote)
                    }
                    .padding()
                }
                .navigationTitle("Añadir app")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") {
                            showingInstructions = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
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
