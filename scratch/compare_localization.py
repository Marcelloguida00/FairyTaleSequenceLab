import os
import json
import re

base_dir = "/Users/marcelloguida/Desktop/Progetto FInale/Final Version/Final Version"
languages = ["en.lproj", "it.lproj", "ru.lproj", "sq.lproj"]

def parse_strings_file(file_path):
    keys = {}
    if not os.path.exists(file_path):
        return keys
    
    pattern = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"\s*=\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*;')
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("/*") or line.startswith("//") or not line:
                continue
            match = pattern.search(line)
            if match:
                key, val = match.groups()
                keys[key] = val
    return keys

all_strings = {}
for lang in languages:
    path = os.path.join(base_dir, lang, "Localizable.strings")
    all_strings[lang] = parse_strings_file(path)

# Find union of all keys
all_keys = set()
for keys in all_strings.values():
    all_keys.update(keys.keys())

missing_by_lang = {}
for lang in languages:
    missing = all_keys - set(all_strings[lang].keys())
    missing_by_lang[lang] = {
        "count": len(missing),
        "keys": sorted(list(missing))
    }

output_path = "/Users/marcelloguida/Desktop/Progetto FInale/Final Version/scratch/missing_keys.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(missing_by_lang, f, indent=2, ensure_ascii=False)

print("Saved missing keys report to scratch/missing_keys.json")
