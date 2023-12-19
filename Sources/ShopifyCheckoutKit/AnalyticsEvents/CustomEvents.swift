struct CustomEvent {
    var clientId: ClientId?
    var context: Context?
    var customData: [String: Any]?
    var id: Id?
    var name: String?
    var timestamp: Timestamp?
}

public typealias CustomEvents = [String: CustomEvent]
