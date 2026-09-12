import AppKit

func yearProgressFraction(_ date: Date) -> (fraction: Double, daysElapsed: Double, daysRemaining: Double) {
    let cal = Calendar.current
    let year = cal.component(.year, from: date)
    var startC = DateComponents()
    startC.year = year; startC.month = 1; startC.day = 1
    var endC = DateComponents()
    endC.year = year + 1; endC.month = 1; endC.day = 1
    let start = cal.date(from: startC)!
    let end = cal.date(from: endC)!
    let total = end.timeIntervalSince(start)
    let elapsed = date.timeIntervalSince(start)
    var fraction = elapsed / total
    if fraction < 0 { fraction = 0 }
    if fraction > 1 { fraction = 1 }
    // Show 100% for the final hour of the year
    if total - elapsed <= 3600.0 { fraction = 1.0 }
    let totalDays = cal.dateComponents([.day], from: start, to: end).day!
    let elapsedDays = cal.dateComponents([.day], from: start, to: date).day!
    let daysElapsed = Double(elapsedDays + 1)          // today counts as elapsed
    let daysRemaining = Double(totalDays - (elapsedDays + 1)) // whole days after today
    return (fraction, daysElapsed, daysRemaining)
}

func monthProgressFraction(_ date: Date) -> Double {
    let cal = Calendar.current
    let comps = cal.dateComponents([.year, .month], from: date)
    var startC = DateComponents()
    startC.year = comps.year!; startC.month = comps.month!; startC.day = 1
    var endC = DateComponents()
    endC.year = comps.year!; endC.month = comps.month! + 1; endC.day = 1
    let start = cal.date(from: startC)!
    let end = cal.date(from: endC)!
    let total = end.timeIntervalSince(start)
    let elapsed = date.timeIntervalSince(start)
    var fraction = elapsed / total
    if fraction < 0 { fraction = 0 }
    if fraction > 1 { fraction = 1 }
    return fraction
}

func dayProgressFraction(_ date: Date) -> Double {
    let cal = Calendar.current
    let comps = cal.dateComponents([.year, .month, .day], from: date)
    let start = cal.date(from: comps)!
    var oneDay = DateComponents()
    oneDay.day = 1
    let end = cal.date(byAdding: oneDay, to: start)!
    let total = end.timeIntervalSince(start)
    let elapsed = date.timeIntervalSince(start)
    var fraction = elapsed / total
    if fraction < 0 { fraction = 0 }
    if fraction > 1 { fraction = 1 }
    return fraction
}

func ringImage(_ progress: Double) -> NSImage {
    let size: CGFloat = 18.0
    let lineWidth: CGFloat = 2.5
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocusFlipped(false)
    defer { image.unlockFocus() }
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = lineWidth / 2.0 + 0.5
    let circleRect = rect.insetBy(dx: inset, dy: inset)

    let track = NSBezierPath(ovalIn: circleRect)
    track.lineWidth = lineWidth
    NSColor.tertiaryLabelColor.setStroke()
    track.stroke()

    if progress > 0.001 {
        let arc = NSBezierPath()
        arc.appendArc(withCenter: NSPoint(x: circleRect.midX, y: circleRect.midY),
                      radius: circleRect.size.width / 2.0,
                      startAngle: 90.0,
                      endAngle: 90.0 - progress * 360.0,
                      clockwise: true)
        arc.lineWidth = lineWidth
        arc.lineCapStyle = .round
        NSColor.labelColor.setStroke()
        arc.stroke()
    }
    image.isTemplate = true
    return image
}

let barSquareSize: CGFloat = 11.0
let barSquareGap: CGFloat = 2.0
let barSquareCount = 20

let menuPad: CGFloat = 10.0
let labelWidth: CGFloat = 46.0
let barWidth: CGFloat = CGFloat(barSquareCount) * barSquareSize + CGFloat(barSquareCount - 1) * barSquareGap
let percentWidth: CGFloat = 38.0
let columnGap: CGFloat = 8.0
let rowHeight: CGFloat = 16.0
let rowGap: CGFloat = 8.0

final class MenuContentView: NSView {
    var yearProgress: Double = 0
    var monthProgress: Double = 0
    var dayProgress: Double = 0
    var daysText: String = ""

    static var contentSize: NSSize {
        let width = menuPad * 2 + labelWidth + columnGap + barWidth + columnGap + percentWidth
        let height = menuPad * 2 + 3 * rowHeight + 2 * rowGap + rowHeight
        return NSSize(width: width, height: height)
    }

    override var isFlipped: Bool { true }

    private func drawBar(in barRect: NSRect, progress: Double) {
        var filled = Int(progress * Double(barSquareCount) + 0.5)
        if filled > barSquareCount { filled = barSquareCount }
        let y = barRect.minY
        for i in 0..<barSquareCount {
            let x = barRect.minX + CGFloat(i) * (barSquareSize + barSquareGap)
            let square = NSRect(x: x, y: y, width: barSquareSize, height: barSquareSize).insetBy(dx: 1.0, dy: 1.0)
            if i < filled {
                NSColor.labelColor.setFill()
                NSBezierPath(roundedRect: square, xRadius: 2.0, yRadius: 2.0).fill()
            } else {
                NSColor.tertiaryLabelColor.setStroke()
                let p = NSBezierPath(roundedRect: square, xRadius: 2.0, yRadius: 2.0)
                p.lineWidth = 1.0
                p.stroke()
            }
        }
    }

    private func drawString(_ string: String, at point: NSPoint, forWidth width: CGFloat, font: NSFont, color: NSColor) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byClipping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style,
        ]
        let size = string.size(withAttributes: attrs)
        string.draw(at: NSPoint(x: point.x, y: point.y + (rowHeight - size.height) / 2.0), withAttributes: attrs)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rowFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let labels = ["Year", "Month", "Day"]
        let progresses = [yearProgress, monthProgress, dayProgress]

        for i in 0..<3 {
            let rowTop = menuPad + CGFloat(i) * (rowHeight + rowGap)
            let progress = progresses[i]

            drawString(labels[i],
                       at: NSPoint(x: menuPad, y: rowTop),
                       forWidth: labelWidth,
                       font: rowFont,
                       color: .secondaryLabelColor)

            drawBar(in: NSRect(x: menuPad + labelWidth + columnGap, y: rowTop + 1.0, width: barWidth, height: rowHeight - 2.0),
                    progress: progress)

            let percentText = String(format: "%.0f%%", floor(progress * 100))
            drawString(percentText,
                       at: NSPoint(x: menuPad + labelWidth + columnGap + barWidth + columnGap, y: rowTop),
                       forWidth: percentWidth,
                       font: rowFont,
                       color: .labelColor)
        }

        let daysTop = menuPad + 3 * (rowHeight + rowGap)
        drawString(daysText,
                   at: NSPoint(x: menuPad, y: daysTop),
                   forWidth: menuPad * 2 + labelWidth + columnGap + barWidth + columnGap + percentWidth,
                   font: NSFont.systemFont(ofSize: 12),
                   color: .secondaryLabelColor)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer!
    var menuContent: MenuContentView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let button = statusItem.button!
        button.imagePosition = .imageLeft
        button.imageHugsTitle = true

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu

        let contentSize = MenuContentView.contentSize
        menuContent = MenuContentView(frame: NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))

        let rowItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        rowItem.isEnabled = false
        rowItem.view = menuContent
        menu.addItem(rowItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)

        update()

        timer = Timer(timeInterval: 60.0, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
    }

    func menuWillOpen(_ menu: NSMenu) {
        update()
    }

    @objc func update() {
        let (fraction, daysElapsed, daysRemaining) = yearProgressFraction(Date())

        statusItem.button?.image = ringImage(fraction)
        statusItem.button?.title = String(format: "%.0f%%", floor(fraction * 100))

        let now = Date()
        menuContent.yearProgress = fraction
        menuContent.monthProgress = monthProgressFraction(now)
        menuContent.dayProgress = dayProgressFraction(now)
        menuContent.daysText = String(format: "%.0f days elapsed · %.0f days left", daysElapsed, daysRemaining)
        menuContent.needsDisplay = true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
