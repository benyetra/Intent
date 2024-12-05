import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    private init() {
        container = NSPersistentCloudKitContainer(name: "Intentsify")

        let description = container.persistentStoreDescriptions.first
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourcompany.Intentsify")

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Error loading persistent stores: \(error), \(error.userInfo)")
            } else {
                print("Persistent store loaded successfully.")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processRemoteStoreChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func processRemoteStoreChange(_ notification: Notification) {
        print("Processing remote store changes from CloudKit.")
        container.viewContext.perform {
            do {
                try self.container.viewContext.save()
            } catch {
                print("Failed to save context after CloudKit sync: \(error)")
            }
        }
    }

    func retryCloudKitSync() {
        container.viewContext.perform {
            do {
                try self.container.viewContext.save()
                print("CloudKit sync retried successfully.")
            } catch {
                print("CloudKit sync retry failed: \(error.localizedDescription)")
            }
        }
    }
}

//
//    // MARK: - Process CloudKit Remote Changes
//    @objc private func processRemoteStoreChange(_ notification: Notification) {
//        print("Processing remote store changes from CloudKit.")
//        container.viewContext.perform {
//            do {
//                try self.container.viewContext.save()
//            } catch {
//                print("Failed to save context after CloudKit sync: \(error)")
//            }
//        }
//    }
//}
