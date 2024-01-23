import SwiftUI

struct WebPixelsEventsView: View {
	@State private var logs: [String?] = WebPixelsLogReader.shared.readLogs() ?? []

	var body: some View {
		VStack {
			List {
				if logs.isEmpty {
					HStack {
						Spacer()
						Text("No logs available")
							.font(.system(size: 12))
							.padding()
						Spacer()
					}
				} else {
					ForEach(logs, id: \.self) { log in
						Text(log ?? "No log available")
							.font(.system(size: 12))
					}

					HStack {
						Spacer()
						Button(action: clearLogs) {
							Text("Clear logs")
								.foregroundColor(.red)
								.background(.white)
								.font(.system(size: 12))
						}
						Spacer()
					}
				}
			}
		}
		.navigationTitle("Events")
		.navigationBarItems(
			trailing: Button(action: clearLogs) {
				Text("Clear")
			}
		)
		.onAppear {
			logs = readLogs()
		}
	}

	private func clearLogs() {
		appConfiguration.webPixelsLogger.clearLogs()
		logs = readLogs()
	}

	private func readLogs() -> [String?] {
		return WebPixelsLogReader.shared.readLogs() ?? []
	}
}
