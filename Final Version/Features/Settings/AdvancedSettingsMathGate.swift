import SwiftUI
import UIKit

struct MathAdditionProblem: Equatable {
    let first: Int
    let second: Int

    var answer: Int { first + second }

    /// Operands from 1–10 (e.g. 4 + 1, 7 + 3).
    static func randomSimple() -> MathAdditionProblem {
        MathAdditionProblem(
            first: Int.random(in: 1...10),
            second: Int.random(in: 1...10)
        )
    }
}

struct AdvancedSettingsMathGate: View {
    let problem: MathAdditionProblem
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @Environment(LanguageManager.self) private var lm
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var userAnswer = ""
    @State private var showWrongAnswer = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @FocusState private var answerFocused: Bool

    private var promptText: Text {
        Text(lm.t("settings.advanced_gate.placeholder"))
            .font(.app(.title3, weight: .bold))
            .foregroundStyle(SettingsGateTheme.secondaryText)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.45)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)
                    .onTapGesture {
                        answerFocused = false
                        onCancel()
                    }

                modalCard
                    .frame(maxWidth: modalMaxWidth(in: proxy.size.width))
                    .position(
                        x: proxy.size.width * 0.5,
                        y: modalCenterY(totalHeight: proxy.size.height)
                    )
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            .onAppear { containerHeight = proxy.size.height }
            .onChange(of: proxy.size.height) { _, height in
                containerHeight = height
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }

            let overlap = max(0, containerHeight - frame.origin.y)
            keyboardHeight = overlap
        }
    }

    private func modalMaxWidth(in totalWidth: CGFloat) -> CGFloat {
        let horizontalInset: CGFloat = 40
        let cap: CGFloat = dynamicTypeSize.isAccessibilitySize ? 520 : 480
        return min(totalWidth - horizontalInset, cap)
    }

    private func modalCenterY(totalHeight: CGFloat) -> CGFloat {
        guard keyboardHeight > 0 else {
            return totalHeight * 0.5
        }

        let visibleHeight = totalHeight - keyboardHeight
        return max(visibleHeight * 0.5, totalHeight * 0.22)
    }

    private var modalCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical, showsIndicators: false) {
                    modalCardContent
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                modalCardContent
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SettingsGateTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SettingsGateTheme.panelBorder, lineWidth: 2.5)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }

    private var modalCardContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(lm.t("settings.advanced_gate.title"))
                    .font(.app(.title3, weight: .bold))
                    .foregroundStyle(SettingsGateTheme.rowText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(lm.t("settings.advanced_gate.message"))
                    .font(.app(.subheadline))
                    .foregroundStyle(SettingsGateTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }

            equationEntry

            if showWrongAnswer {
                Text(lm.t("settings.advanced_gate.wrong"))
                    .font(.app(.caption, weight: .semibold))
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            actionButtons
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
    }

    private var equationEntry: some View {
        HStack(spacing: 12) {
            equationText
            answerField
        }
        .frame(maxWidth: .infinity)
    }

    private var equationText: some View {
        Text("\(problem.first) + \(problem.second) =")
            .font(.app(.title2, weight: .bold))
            .foregroundStyle(SettingsGateTheme.rowText)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .accessibilityLabel("\(problem.first) plus \(problem.second) equals")
    }

    private var answerField: some View {
        TextField("", text: $userAnswer, prompt: promptText)
            .font(.app(.title3, weight: .bold))
            .foregroundStyle(SettingsGateTheme.rowText)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.oneTimeCode)
            .frame(width: 88, height: 48)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SettingsGateTheme.fieldFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                showWrongAnswer
                                    ? Color.red.opacity(0.75)
                                    : SettingsGateTheme.panelBorder,
                                lineWidth: 2
                            )
                    )
            )
            .focused($answerFocused)
            .onChange(of: userAnswer) { _, newValue in
                showWrongAnswer = false
                let sanitized = sanitizeDigits(newValue)
                if sanitized != newValue {
                    userAnswer = sanitized
                }
            }
            .onSubmit(submitAnswer)
            .accessibilityLabel(lm.t("settings.advanced_gate.placeholder"))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            cancelButton
            submitButton
        }
        .frame(maxWidth: .infinity)
    }

    private var cancelButton: some View {
        Button {
            answerFocused = false
            onCancel()
        } label: {
            Text(lm.t("button.cancel"))
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(SettingsGateTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: GameButtonMetrics.minimumTouchTarget)
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget()
        .accessibilityLabel(lm.t("button.cancel"))
    }

    private var submitButton: some View {
        Button(action: submitAnswer) {
            Text(lm.t("settings.advanced_gate.submit").uppercased())
                .font(.app(.headline, weight: .bold))
                .foregroundStyle(GameButtonAppearance.label)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GamePillButtonBackground())
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget(minWidth: 156, minHeight: 52)
        .accessibilityLabel(lm.t("settings.advanced_gate.submit"))
    }

    private func sanitizeDigits(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(2))
    }

    private func submitAnswer() {
        answerFocused = false

        guard let value = Int(userAnswer),
              value == problem.answer else {
            showWrongAnswer = true
            AppSettings.hapticImpact(.rigid)
            UIAccessibility.post(notification: .announcement, argument: lm.t("settings.advanced_gate.wrong"))
            return
        }

        AppSettings.hapticSuccess()
        UIAccessibility.post(notification: .announcement, argument: lm.t("settings.advanced_gate.success"))
        onSuccess()
    }
}

private enum SettingsGateTheme {
    static let panelFill = Color(red: 0.98, green: 0.95, blue: 0.86)
    static let panelBorder = Color(red: 0.722, green: 0.631, blue: 0.420)
    static let rowText = Color(red: 0.18, green: 0.10, blue: 0.08)
    static let secondaryText = Color(red: 0.549, green: 0.451, blue: 0.333)
    static let fieldFill = Color(red: 0.945, green: 0.918, blue: 0.827)
}

#Preview {
    ZStack {
        Color.gray
        AdvancedSettingsMathGate(
            problem: MathAdditionProblem(first: 4, second: 1),
            onSuccess: {},
            onCancel: {}
        )
    }
    .environment(LanguageManager())
}
