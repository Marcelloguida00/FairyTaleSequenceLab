import os
import re
import urllib.request
import urllib.parse
import json
import time

def translate(text, target_lang):
    if not text.strip():
        return text
    # Keep format specifiers safe by not translating if it's just a specifier
    if text in ["%@", "%d", "%i", "%s"]:
        return text
        
    try:
        url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl={target_lang}&dt=t&q={urllib.parse.quote(text)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            translated = "".join([part[0] for part in data[0] if part[0]])
            # Clean up potential spacing errors with format specifiers introduced by translation
            translated = translated.replace("% @", "%@").replace("% d", "%d").replace("% i", "%i").replace("% s", "%s")
            return translated
    except Exception as e:
        print(f"Error translating '{text[:20]}' to {target_lang}: {e}")
        return text

def translate_file(source_path, target_path, target_lang):
    print(f"Translating {source_path} -> {target_path} ({target_lang})...")
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    
    # Pattern to match: "key" = "value";
    pattern = re.compile(r'^(\s*"[^"]+"\s*=\s*")((?:[^"\\]|\\.)*)("\s*;\s*)$')
    
    lines_written = 0
    with open(source_path, "r", encoding="utf-8") as src_f, open(target_path, "w", encoding="utf-8") as tgt_f:
        for line in src_f:
            match = pattern.match(line)
            if match:
                prefix = match.group(1)
                value = match.group(2)
                suffix = match.group(3)
                
                # Unescape quotes and newlines for translation
                unescaped_value = value.replace(r'\"', '"').replace(r'\n', '\n')
                
                # Translate
                translated_value = translate(unescaped_value, target_lang)
                
                # Re-escape quotes and newlines
                escaped_translated = translated_value.replace('"', r'\"').replace('\n', r'\n')
                
                tgt_f.write(f"{prefix}{escaped_translated}{suffix}\n")
                lines_written += 1
                # Small sleep to prevent rate limiting
                time.sleep(0.08)
            else:
                tgt_f.write(line)
                
    print(f"Done! Translated {lines_written} lines.")

languages = {
    "es": "es",
    "pt": "pt",
    "fa": "fa",
    "zh-Hans": "zh-CN" # Google Translate uses zh-CN for Simplified Chinese
}

source_dir = "/Users/marcelloguida/Desktop/Progetto FInale/Final Version/Final Version"

for lang_code, google_code in languages.items():
    # Translate Localizable.strings
    src_loc = os.path.join(source_dir, "en.lproj", "Localizable.strings")
    tgt_loc = os.path.join(source_dir, f"{lang_code}.lproj", "Localizable.strings")
    translate_file(src_loc, tgt_loc, google_code)
    
    # Translate InfoPlist.strings
    src_info = os.path.join(source_dir, "en.lproj", "InfoPlist.strings")
    tgt_info = os.path.join(source_dir, f"{lang_code}.lproj", "InfoPlist.strings")
    translate_file(src_info, tgt_info, google_code)
