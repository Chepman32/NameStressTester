import SwiftUI

struct NamifyBadge: View {
    let verdict: TestVerdict
    var compact = false

    var body: some View {
        Text(L(verdict.labelKey))
            .font(NamifyTypography.badge())
            .kerning(0.8)
            .foregroundStyle(Brand.color(for: verdict))
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(Brand.color(for: verdict).opacity(0.12), in: Capsule())
            .scaleEffect(1)
            .accessibilityLabel(verdict.rawValue.capitalized)
    }
}

struct NamifyButton: View {
    enum Style {
        case primary
        case secondary
        case text
        case destructive
    }

    let title: String
    var style: Style = .primary
    var isDisabled = false
    var isLoading = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(style == .primary || style == .destructive ? .white : Brand.accent)
                }
            }
            .font(NamifyTypography.button())
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundShape)
            .overlay(borderOverlay)
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(isDisabled ? 0.55 : 1)
            .animation(NamifyMotion.micro, value: pressed)
            .animation(NamifyMotion.snappy, value: isDisabled)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard isDisabled == false else { return }
                if pressed == false {
                    pressed = true
                    Haptics.impact(.medium)
                }
            }
            .onEnded { _ in
                pressed = false
            }
        )
        .disabled(isDisabled || isLoading)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .text:
            return Brand.accent
        }
    }

    @ViewBuilder
    private var backgroundShape: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .fill(Brand.accent.opacity(isDisabled ? 0.3 : 1))
                .namifyCardShadow(NamifyShadow.glow)
        case .secondary:
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .fill(Brand.card)
                .namifyCardShadow()
        case .text:
            Color.clear
        case .destructive:
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .fill(Brand.fail)
                .namifyCardShadow(NamifyShadow.floating)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(Brand.accent, lineWidth: 1)
        }
    }
}

struct NamifyIconCircle: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(color.opacity(0.12))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(color)
            }
    }
}

struct NamifyDivider: View {
    var body: some View {
        Rectangle()
            .fill(Brand.divider)
            .frame(height: 1)
    }
}

struct NamifyChip: View {
    let title: String
    var tint: Color = Brand.cardAlt
    var foreground: Color = Brand.textSecondary

    var body: some View {
        Text(title)
            .font(NamifyTypography.bodySmall())
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(tint, in: Capsule())
    }
}

struct NamifyTextField: View {
    let title: String
    @Binding var text: String
    var isRequired = false
    var focused: Bool
    var submitLabel: SubmitLabel = .next
    var onClear: (() -> Void)?

    var body: some View {
        HStack(spacing: NamifySpacing.sm) {
            TextField("", text: $text, prompt: Text(isRequired ? "\(title) *" : title)
                .font(NamifyTypography.bodyLarge())
                .foregroundStyle(Brand.textTertiary))
                .font(NamifyTypography.bodyLarge())
                .foregroundStyle(Brand.textPrimary)
                .submitLabel(submitLabel)

            if text.isEmpty == false {
                Button {
                    text = ""
                    Haptics.impact(.light)
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Brand.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, NamifySpacing.md)
        .frame(height: 56)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(focused ? Brand.accent : Brand.divider, lineWidth: focused ? 2 : 1)
        }
        .namifyCardShadow(focused ? NamifyShadow.floating : NamifyShadow.card)
        .animation(NamifyMotion.micro, value: focused)
    }

}

struct NamifyProgressBar: View {
    let progress: Double
    @State private var shimmer = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Brand.divider)
                Capsule()
                    .fill(
                        LinearGradient(colors: [Brand.accent, Brand.pass], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: proxy.size.width * progress)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 20)
                            .blur(radius: 4)
                            .offset(x: shimmer ? proxy.size.width * progress : 0)
                    }
                    .clipShape(Capsule())
            }
            .animation(NamifyMotion.snappy, value: progress)
            .task {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
        }
        .frame(height: 6)
    }
}

struct NamifyScoreRing: View {
    let value: Int
    let total: Int

    private var fraction: Double { total == 0 ? 0 : Double(value) / Double(total) }
    private var tint: Color {
        switch fraction {
        case 0.7...: Brand.pass
        case 0.4...: Brand.warn
        default: Brand.fail
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.divider, lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(value)/\(total)")
                .font(NamifyTypography.badge())
                .foregroundStyle(Brand.textPrimary)
        }
        .frame(width: 36, height: 36)
    }
}

struct NamifyShimmer: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Brand.shimmerStart, Brand.shimmerEnd, Brand.shimmerStart],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.white)
                        .overlay {
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.55), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: proxy.size.width * 0.6)
                            .offset(x: proxy.size.width * offset)
                        }
                }
            }
            .task {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    offset = 1.3
                }
            }
    }
}

struct NamifyCard<Content: View>: View {
    let testType: TestType
    let summary: String
    let verdict: TestVerdict
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            HStack(alignment: .center, spacing: NamifySpacing.md) {
                NamifyIconCircle(systemName: testType.systemImage, color: Brand.color(for: testType))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L(testType.localizedNameKey))
                        .font(NamifyTypography.bodyLarge())
                        .foregroundStyle(Brand.textPrimary)
                    Text(summary)
                        .font(NamifyTypography.bodySmall())
                        .foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                NamifyBadge(verdict: verdict)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(NamifyMotion.smooth, value: isExpanded)
            }

            if isExpanded {
                NamifyDivider()
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(NamifySpacing.md)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(isExpanded ? Brand.color(for: testType).opacity(0.3) : Brand.divider, lineWidth: 1)
        }
        .namifyCardShadow(isExpanded ? NamifyShadow.floating : NamifyShadow.card)
        .animation(NamifyMotion.smooth, value: isExpanded)
        .contentShape(RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .onTapGesture {
            isExpanded.toggle()
            Haptics.selection()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L(testType.localizedNameKey)): \(verdict.rawValue.capitalized). \(summary)")
        .accessibilityHint(L("accessibility.expandHint"))
    }
}

struct NamifySegmentedPicker: View {
    let selection: AppearanceMode
    let onChange: (AppearanceMode) -> Void

    var body: some View {
        HStack(spacing: NamifySpacing.sm) {
            segment(for: .light, icon: "sun.max.fill")
            segment(for: .system, icon: "circle.lefthalf.filled")
            segment(for: .dark, icon: "moon.fill")
        }
    }

    @ViewBuilder
    private func segment(for mode: AppearanceMode, icon: String) -> some View {
        Button {
            onChange(mode)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selection == mode ? .white : Brand.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    (selection == mode ? Brand.accent : Brand.cardAlt),
                    in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

struct NamifyToast: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(spacing: NamifySpacing.md) {
            Text(title)
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(.white)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(NamifyTypography.bodySmall().weight(.semibold))
                    .foregroundStyle(Brand.accent)
            }
        }
        .padding(.horizontal, NamifySpacing.md)
        .padding(.vertical, 12)
        .background(Brand.primary.opacity(0.92), in: RoundedRectangle(cornerRadius: NamifyRadius.large, style: .continuous))
        .namifyCardShadow(NamifyShadow.modal)
    }
}
