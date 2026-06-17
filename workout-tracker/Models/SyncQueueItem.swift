import Foundation
import SwiftData

@Model
final class SyncQueueItem {
    var id: UUID
    var operationType: String
    var entityId: UUID
    var payload: Data
    var createdAt: Date
    var retryCount: Int

    init(
        id: UUID = UUID(),
        operationType: String,
        entityId: UUID,
        payload: Data,
        createdAt: Date = .now,
        retryCount: Int = 0
    ) {
        self.id = id
        self.operationType = operationType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}
