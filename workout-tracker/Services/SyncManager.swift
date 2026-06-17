import Foundation
import SwiftData

@Observable
final class SyncManager {
    private let modelContext: ModelContext
    private let apiClient = APIClient.shared
    var pendingSyncCount = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        updatePendingCount()

        NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isConnected = notification.userInfo?["isConnected"] as? Bool, isConnected {
                Task { await self?.processQueue() }
            }
        }
    }

    func processQueue() async {
        let descriptor = FetchDescriptor<SyncQueueItem>(sortBy: [SortDescriptor(\.createdAt)])
        guard let items = try? modelContext.fetch(descriptor), !items.isEmpty else { return }

        for item in items {
            guard item.retryCount < 5 else { continue }

            do {
                try await processItem(item)
                modelContext.delete(item)
                try modelContext.save()
            } catch {
                item.retryCount += 1
                try? modelContext.save()
            }
        }

        updatePendingCount()
    }

    private func processItem(_ item: SyncQueueItem) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch item.operationType {
        case "create_session":
            let decoder = JSONDecoder()
            let dto = try decoder.decode(SessionCreateDTO.self, from: item.payload)
            let _: SessionDTO = try await apiClient.request(Endpoints.createSession(dto))

            // Mark the local draft as synced
            let entityId = item.entityId
            let descriptor = FetchDescriptor<SessionDraft>(predicate: #Predicate { $0.id == entityId })
            if let draft = try? modelContext.fetch(descriptor).first {
                draft.isSynced = true
            }

        case "create_template":
            let decoder = JSONDecoder()
            let dto = try decoder.decode(TemplateCreateDTO.self, from: item.payload)
            let _: TemplateDTO = try await apiClient.request(Endpoints.createTemplate(dto))

        case "update_template":
            let decoder = JSONDecoder()
            let dto = try decoder.decode(TemplateCreateDTO.self, from: item.payload)
            let _: TemplateDTO = try await apiClient.request(Endpoints.updateTemplate(id: item.entityId, dto))

        case "delete_template":
            try await apiClient.requestVoid(Endpoints.deleteTemplate(id: item.entityId))

        default:
            break
        }
    }

    private func updatePendingCount() {
        let descriptor = FetchDescriptor<SyncQueueItem>()
        pendingSyncCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
