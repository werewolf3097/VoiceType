import SwiftUI

struct DashboardDictionaryView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var terms: [String] = []
    @State private var newTerm: String = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let maxTerms = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Словарь").font(.largeTitle.bold())
                Spacer()
                if isLoading || isSaving {
                    ProgressView().controlSize(.small)
                }
                Button {
                    Task { await load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(settings.gapiToken.isEmpty)
            }
            .padding([.horizontal, .top], 24)

            Text("Термины (названия компаний, продуктов, имена), которые gapi будет чаще узнавать в речи. Общий словарь проекта на console.gapi.uz — до \(maxTerms) терминов.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            if settings.gapiToken.isEmpty {
                Text("Сначала укажите токен gapi в Настройках.")
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 24)
                Spacer()
            } else {
                HStack {
                    TextField("Новый термин", text: $newTerm)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTerm)
                    Button("Добавить", action: addTerm)
                        .disabled(newTerm.trimmingCharacters(in: .whitespaces).isEmpty || terms.count >= maxTerms)
                }
                .padding(.horizontal, 24)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                if terms.isEmpty && !isLoading {
                    Text("Словарь пуст.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                    Spacer()
                } else {
                    List {
                        ForEach(terms, id: \.self) { term in
                            HStack {
                                Text(term)
                                Spacer()
                                Button {
                                    remove(term)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.inset)

                    Text("\(terms.count) / \(maxTerms)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
        }
        .task { await load() }
    }

    private func addTerm() {
        let trimmed = newTerm.trimmingCharacters(in: .whitespaces)
        newTerm = ""
        guard !trimmed.isEmpty, terms.count < maxTerms else { return }
        guard !terms.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        terms.append(trimmed)
        Task { await save() }
    }

    private func remove(_ term: String) {
        terms.removeAll { $0 == term }
        Task { await save() }
    }

    private func load() async {
        guard !settings.gapiToken.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            terms = try await GapiClient(token: settings.gapiToken).getVocabulary()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        guard !settings.gapiToken.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await GapiClient(token: settings.gapiToken).setVocabulary(terms)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
