import sys

filepath = 'Final Version/Features/Sequencing/SequencingActivityView.swift'
with open(filepath, 'r') as f:
    content = f.read()

# 1. Remove CelebrationView
start_str = "struct CelebrationView: View {"
end_str = "// MARK: - Placement visuals\n"
idx_start = content.find(start_str)
idx_end = content.find(end_str)
if idx_start != -1 and idx_end != -1:
    content = content[:idx_start] + content[idx_end:]

# 2. Add isStorybookExpanded
content = content.replace(
    "@State private var flipToggleUsesFirstSound = true",
    "@State private var flipToggleUsesFirstSound = true\n    @State private var isStorybookExpanded = false"
)

# 3. Replace showCelebration with isStorybookExpanded in states
content = content.replace(
    "@State private var showCelebration = false",
    ""
)

content = content.replace(
    "showCelebration = false",
    "isStorybookExpanded = false"
)

# 4. Modify sequencingStage
old_stage = """                storybookPanel(cardW: cardW, cardH: cardH)
                    .padding(.horizontal, hPad)
                    .padding(.top, SequencingLayoutMetrics.stageStorybookTopPad)

                Spacer(minLength: 0)

                sourceTray(cardW: cardW, cardH: cardH)
                    .padding(.horizontal, hPad)
                    .padding(.bottom, SequencingLayoutMetrics.stageDeckBottomPad)"""

new_stage = """                storybookPanel(cardW: cardW, cardH: cardH)
                    .padding(.horizontal, isStorybookExpanded ? 0 : hPad)
                    .padding(.top, isStorybookExpanded ? 0 : SequencingLayoutMetrics.stageStorybookTopPad)
                    .frame(maxWidth: .infinity, maxHeight: isStorybookExpanded ? .infinity : nil)
                    .zIndex(100)

                if !isStorybookExpanded {
                    Spacer(minLength: 0)

                    sourceTray(cardW: cardW, cardH: cardH)
                        .padding(.horizontal, hPad)
                        .padding(.bottom, SequencingLayoutMetrics.stageDeckBottomPad)
                        .transition(.opacity)
                }"""
content = content.replace(old_stage, new_stage)

# 5. Remove showCelebration view
old_celeb = """            }

            if showCelebration {
                CelebrationView().allowsHitTesting(false)
            }

            if dimForReward {"""

new_celeb = """            }

            if dimForReward {"""
content = content.replace(old_celeb, new_celeb)

# 6. Modify storybookPanel
old_sb = """            slotsRow(cardW: cardW, cardH: cardH)
                .padding(.horizontal, SequencingLayoutMetrics.storybookSlotsHorizontalPad)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SequencingLayoutMetrics.storybookSlotsTopPad)
                .padding(.bottom, SequencingLayoutMetrics.storybookSlotsBottomPad)
        }"""

new_sb = """            slotsRow(cardW: cardW, cardH: cardH)
                .padding(.horizontal, isStorybookExpanded ? 32 : SequencingLayoutMetrics.storybookSlotsHorizontalPad)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SequencingLayoutMetrics.storybookSlotsTopPad)
                .padding(.bottom, isStorybookExpanded ? 0 : SequencingLayoutMetrics.storybookSlotsBottomPad)
                .scaleEffect(isStorybookExpanded ? 1.2 : 1.0)
            
            if isStorybookExpanded {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Text(lm.t("celebration.title"))
                        .font(.app(size: 48, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    
                    Button(action: {
                        onSequencingComplete?(attemptCount)
                    }) {
                        Text(event.isLastEvent ? lm.t("button.back_to_map") : lm.t("button.next_event"))
                            .font(.app(.title3, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.12, green: 0.64, blue: 0.92))
                                    .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
                            )
                    }
                }
                .padding(.bottom, 60)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isStorybookExpanded)"""
content = content.replace(old_sb, new_sb)

# 7. Modify triggerCelebration
old_trigger = """    @MainActor
    private func triggerCelebration() async {
        AppSettings.hapticSuccess()
        UIAccessibility.post(notification: .announcement, argument: "Correct! Great job!")

        if let onSequencingComplete {
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                showCelebration = true
            }
            try? await Task.sleep(for: .seconds(1.5))
            onSequencingComplete(attemptCount)
        } else if showsReward {
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                showCelebration = true
            }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeIn(duration: 0.4)) { dimForReward = true }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { showReward = true }
        } else {
            onSuccess?()
        }
    }"""

new_trigger = """    @MainActor
    private func triggerCelebration() async {
        AppSettings.hapticSuccess()
        UIAccessibility.post(notification: .announcement, argument: "Correct! Great job!")

        if let onSequencingComplete {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                isStorybookExpanded = true
            }
        } else if showsReward {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                isStorybookExpanded = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.4)) { dimForReward = true }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { showReward = true }
        } else {
            onSuccess?()
        }
    }"""
content = content.replace(old_trigger, new_trigger)

# 8. Fix finalizeDrop and evaluateCompletedBoardIfReady
old_drop = """            let normalizedContents = normalizedSlotContents(nextContents, keeping: cardId, in: targetSlot)

            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                slotContents = normalizedContents
            }

            if isCorrect {
                handleCorrectPlacement(forSlot: targetSlot)
                evaluateCompletedBoardIfReady()
            } else {
                handleIncorrectPlacement(forSlot: targetSlot, revertingTo: previousContents)
            }
            return"""

new_drop = """            let normalizedContents = normalizedSlotContents(nextContents, keeping: cardId, in: targetSlot)

            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                slotContents = normalizedContents
            }

            handlePlacement(forSlot: targetSlot)
            evaluateCompletedBoardIfReady()
            return"""
content = content.replace(old_drop, new_drop)

# 9. Fix evaluateCompletedBoardIfReady check
content = content.replace("!showCelebration", "!isStorybookExpanded")

# 10. Fix handleCorrectPlacement to handlePlacement
old_correct_placement = """    private func handleCorrectPlacement(forSlot slot: Int) {
        AppSettings.hapticImpact(.light)
        SequencingSoundCoordinator.correctPlacement(
            slot: slot,
            correctPlacementsAfter: correctlyPlacedCount
        )
        playCorrectPlacementAnimation(for: slot)
    }"""

new_placement = """    private func handlePlacement(forSlot slot: Int) {
        AppSettings.hapticImpact(.light)
        SequencingSoundCoordinator.correctPlacement(
            slot: slot,
            correctPlacementsAfter: correctlyPlacedCount
        )
        playPlacementAnimation(for: slot)
    }"""
content = content.replace(old_correct_placement, new_placement)

# Remove playCorrectPlacementAnimation
content = content.replace("private func playCorrectPlacementAnimation(for slot: Int) {", "private func playPlacementAnimation(for slot: Int) {")

# Delete handleIncorrectPlacement completely
import re
pattern = r"    private func handleIncorrectPlacement\(forSlot slot: Int, revertingTo previousContents: \[Int\?\]\) \{.*?\n    \}"
content = re.sub(pattern, "", content, flags=re.DOTALL)


with open(filepath, 'w') as f:
    f.write(content)
print("Updated successfully!")
