//
//  WebView.swift
//  Translate
//
//  Created by Yandel Gil on 10/1/24.
//

import SwiftUI
@preconcurrency import WebKit
import UniformTypeIdentifiers

struct WebView: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @preconcurrency
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator // Manejo de diálogos

        // Configurar el almacenamiento de cookies
        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore

        // Sincronizar cookies de HTTPCookieStorage con WKWebView
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            cookieStore.setCookie(cookie)
        }

        // Configurar la política de cookies
        webView.configuration.websiteDataStore = dataStore

        // Configurar preferencias de la página web
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = preferences

        // Configurar permisos de medios
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        let request = URLRequest(url: url)
        webView.load(request)

        // Agregar observador para refrescar el WebView
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RefreshWebView"), object: nil, queue: .main) { _ in
            webView.reload()
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No es necesario realizar actualizaciones adicionales
    }

    // Agregar @preconcurrency aquí para suprimir advertencias
    @preconcurrency
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // Manejo de la selección de archivos usando allowedContentTypes
        func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.allowedContentTypes = [.jpeg, .png, .pdf, .data] // Permitir solo estos

            // Asegurarse de que la ventana del Finder se mantenga visible y en primer plano
            panel.level = .modalPanel

            // Hacer que la aplicación sea visible en el dock y en primer plano
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            panel.begin { response in
                if response == .OK {
                    completionHandler(panel.urls)
                } else {
                    completionHandler(nil)
                }

                // Restaurar la aplicación a su estado normal
                NSApp.setActivationPolicy(.accessory)
            }

            // Mantener la ventana del Finder en primer plano
            panel.makeKeyAndOrderFront(nil)
        }

        // Manejo de cookies al recibir respuesta
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse,
               let url = httpResponse.url,
               let headers = httpResponse.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
                cookies.forEach { cookie in
                    HTTPCookieStorage.shared.setCookie(cookie)
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
            decisionHandler(.allow)
        }

        // Manejo de permisos de medios
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant) // Conceder todos los permisos de medios
        }
    }
}
