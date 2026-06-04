import re

with open("Final Version/SharedUI/BookView.swift", "r") as f:
    content = f.read()

# Remove isDyslexiaEnabled and titleFont
content = re.sub(r"        let isDyslexiaEnabled = UserDefaults.standard.bool\(forKey: AppFontSettings.dyslexiaFontKey\)\n", "", content)
content = re.sub(r"        let titleFont = isCompact \? Font.app\(\.headline, weight: \.bold\) : Font.app\(\.title, weight: \.bold\)\n", "", content)

# Fix onChange
content = content.replace(".onChange(of: lm.currentLanguage) { _ in", ".onChange(of: lm.currentLanguage) {")
content = content.replace(".onChange(of: currentPage) { _ in", ".onChange(of: currentPage) {")

with open("Final Version/SharedUI/BookView.swift", "w") as f:
    f.write(content)
