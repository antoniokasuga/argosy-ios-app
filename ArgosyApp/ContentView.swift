//
//  ContentView.swift
//  ArgosyApp
//
//  Created by Antons Polskihs on 02/02/2025.
//

import SwiftUI
import PassKit

struct ContentView: View {
    @State private var name = ""
    @State private var barcodeNumber = ""
    @State private var selectedClub = ""
    @State private var clubs = [
        "One Family", "Krūza", "Depo", "Drogas", "Cenuklubs.lv",
        "airBaltic Pins", "Nord Baby", "Circle K",
        "Veselība (Mēness aptieka, Centrālā Laboratorija, VCA Poliklīnika)",
        "Dino Zoo", "Aptieku Alianse", "Lidl",
        "Apollo Kino (Test Mode)", "Domina (Test Mode)", "Lido (Test Mode)"
    ]
    @State private var shopComment = ""
    @State private var isGenerating = false
    @State private var showPassAddSheet = false
    @State private var passData: Data?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cardholder Information")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    TextField("Barcode Number", text: $barcodeNumber)
                        .keyboardType(.numbersAndPunctuation)
                }
                Section(header: Text("Club")) {
                    Picker("Select a club", selection: $selectedClub) {
                        Text("Select a club").tag("")
                        ForEach(clubs, id: \.self) { club in
                            Text(club).tag(club)
                        }
                    }
                    .onChange(of: selectedClub) { newValue, _ in
                        fetchComment(for: newValue)
                    }

                    
                    if !shopComment.isEmpty {
                        Text(shopComment)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                Section {
                    Button(action: {
                        generatePass()
                    }) {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate Pass")
                        }
                    }
                    .disabled(selectedClub.isEmpty || name.isEmpty || barcodeNumber.isEmpty || isGenerating)
                }
            }
            .navigationTitle("Create Club Card")
            .sheet(isPresented: $showPassAddSheet) {
                if let data = passData {
                    PassAddView(passData: data)
                }
            }
        }
    }

    /// Fetch the club comment from your backend’s comment API.
    func fetchComment(for club: String) {
        guard !club.isEmpty else {
            shopComment = ""
            return
        }
        let encodedClub = club.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Use the Render address here.
        let urlString = "https://argosy.onrender.com/api/comment?shopName=\(encodedClub)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let comment = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    shopComment = comment
                }
            } else if let error = error {
                print("Error fetching comment: \(error)")
            }
        }.resume()
    }

    /// Generate the pass by calling your backend’s generatePass endpoint.
    func generatePass() {
        isGenerating = true
        let baseUrl = "https://argosy.onrender.com/generatePass"
        let params = [
            "barcodeNumber": barcodeNumber,
            "clubType": selectedClub,
            "name": name
        ]
        
        // Build the URL with query parameters.
        var components = URLComponents(string: baseUrl)!
        components.queryItems = params.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        guard let url = components.url else {
            isGenerating = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isGenerating = false
            }
            if let data = data {
                DispatchQueue.main.async {
                    passData = data
                    showPassAddSheet = true
                }
            } else if let error = error {
                print("Error generating pass: \(error)")
            }
        }.resume()
    }
}

/// A UIViewControllerRepresentable that wraps PKAddPassesViewController to present the pass.
struct PassAddView: UIViewControllerRepresentable {
    let passData: Data

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        do {
            let pass = try PKPass(data: passData)
            guard let vc = PKAddPassesViewController(pass: pass) else {
                fatalError("Could not create PKAddPassesViewController")
            }
            return vc
        } catch {
            fatalError("Failed to initialize PKPass: \(error)")
        }
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {
        // No dynamic updates needed.
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

