//
//  CueLog.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import CoreData

@objc(CueLog)
public class CueLog: NSManagedObject {
    
    @NSManaged public var date: Date
    @NSManaged public internal(set) var reminder: Reminder!
    
    public class func fetchLogsWithinTimeRange(context: NSManagedObjectContext, startTime: Date, endTime: Date) -> [CueLog] {
        let dateOfLogPredicate = NSPredicate(format: "date >= %@ AND date < %@", startTime as NSDate, endTime as NSDate)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(NSStringFromClass(Self.self)))
        fetchRequest.predicate = dateOfLogPredicate

        let logs = (try? context.fetch(fetchRequest) as? [CueLog]) ?? []
        return logs
    }
}
