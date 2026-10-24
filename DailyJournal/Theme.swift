import SwiftUI

enum Theme {
    static let background = Color(red: 0.925, green: 0.925, blue: 0.933)
    static let card = Color.white
    static let ink = Color(red: 0.235, green: 0.235, blue: 0.255)
    static let body = Color(red: 0.30, green: 0.30, blue: 0.32)
    static let secondary = Color(red: 0.56, green: 0.56, blue: 0.58)
    static let icon = Color(red: 0.50, green: 0.50, blue: 0.53)
    static let logo = Color(red: 0.80, green: 0.80, blue: 0.82)
    static let border = Color(red: 0.82, green: 0.82, blue: 0.84)
    static let divider = Color(red: 0.90, green: 0.90, blue: 0.91)
    static let pill = Color(red: 0.95, green: 0.95, blue: 0.96)
    static let tile = Color(red: 0.20, green: 0.20, blue: 0.22)

    static let indigo = Color(red: 0.357, green: 0.373, blue: 0.925)
    static let inboxBlue = Color(red: 0.37, green: 0.42, blue: 0.90)
    static let blue = Color(red: 0.20, green: 0.50, blue: 0.97)
    static let pink = Color(red: 1.0, green: 0.33, blue: 0.60)
    static let red = Color(red: 0.94, green: 0.34, blue: 0.31)
    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let yellow = Color(red: 1.0, green: 0.76, blue: 0.24)
    static let avatar = Color(red: 1.0, green: 0.90, blue: 0.62)
}

enum CairoWeight: String {
    case regular = "Cairo-Regular"
    case medium = "Cairo-Medium"
    case semibold = "Cairo-SemiBold"
    case bold = "Cairo-Bold"
    case extraBold = "Cairo-ExtraBold"
    case black = "Cairo-Black"
}

extension Font {
    static func cairo(_ size: CGFloat, _ weight: CairoWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

extension View {
    func card(cornerRadius: CGFloat = 28) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 4)
        )
    }

    /// Arabic right-to-left layout, Cairo font and the light look, applied to the root and every sheet.
    func journalEnvironment() -> some View {
        font(.cairo(17))
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Format.locale)
            .preferredColorScheme(.light)
    }
}

extension Calendar {
    static let journal: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ar")
        calendar.firstWeekday = 1
        return calendar
    }()

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}

enum Format {
    static let locale = Locale(identifier: "ar@numbers=latn")

    private static func makeFormatter(_ template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }

    private static let timeFormatter = makeFormatter("hmma")
    private static let dayMonthFormatter = makeFormatter("dMMM")
    private static let fullFormatter = makeFormatter("dMMMhmma")
    private static let monthYearFormatter = makeFormatter("MMMMyyyy")

    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }
    static func dayMonth(_ date: Date) -> String { dayMonthFormatter.string(from: date) }
    static func full(_ date: Date) -> String { fullFormatter.string(from: date) }
    static func monthYear(_ date: Date) -> String { monthYearFormatter.string(from: date) }
}
