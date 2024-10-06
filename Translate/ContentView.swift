//
//  ContentView.swift
//  Translate
//
//  Created by Yandel Gil on 10/1/24.
//

import SwiftUI
import Combine // Importar Combine
@preconcurrency import WebKit
import UniformTypeIdentifiers
import ServiceManagement
import AVFoundation
import Speech

struct ContentView: View {
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @StateObject private var viewModel = WebViewModel() // Crear instancia del ViewModel

    var body: some View {
        VStack {
            WebView(viewModel: viewModel) // Pasar el ViewModel al WebView
                .frame(width: 400, height: 500)

            HStack {
                Button(action: {
                    // Al presionar refrescar, simplemente recarga la URL actual
                    viewModel.url = URL(string: viewModel.url.absoluteString)!
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5)

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("Salir")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5)

                Button(action: {
                    clearCookiesAndRefresh()
                }) {
                    Text("Borrar Cookies")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5)

                Toggle("Abrir al inicio", isOn: $launchAtLogin)
                    .padding(.horizontal, 10)
                    .onChange(of: launchAtLogin) { newValue in
                        let appService = SMAppService.mainApp
                        do {
                            if newValue {
                                try appService.register()
                            } else {
                                try appService.unregister()
                            }
                        } catch {
                            print("Error al cambiar el estado de inicio al iniciar: \(error)")
                        }
                    }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            viewModel.url = URL(string: "https://translate.google.com/")! // Asignar la URL inicial
            requestPermissions()
        }
    }

    func clearCookiesAndRefresh() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: [WKWebsiteDataTypeCookies]) { records in
            dataStore.removeData(ofTypes: [WKWebsiteDataTypeCookies], for: records) {
                print("Cookies borradas")
                // Volver a cargar la URL después de borrar las cookies
                viewModel.url = URL(string: viewModel.url.absoluteString)!
            }
        }
    }

    func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("Permiso para usar el micrófono concedido")
            } else {
                print("Permiso para usar el micrófono denegado")
            }
        }

        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Permiso para el reconocimiento de voz concedido")
            case .denied, .restricted, .notDetermined:
                print("Permiso para el reconocimiento de voz denegado")
            @unknown default:
                print("Estado de autorización desconocido")
            }
        }
    }
}
