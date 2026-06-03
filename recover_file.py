import json
import re

transcript_path = "/Users/cirogiovannicalisto/.gemini/antigravity-ide/brain/adf350c6-5bed-4d1a-879d-d517cdd04755/.system_generated/logs/transcript.jsonl"
file_path = "Final Version/SharedUI/BookView.swift"

with open(file_path, "r") as f:
    content = f.read()

tool_calls = []
with open(transcript_path, "r") as f:
    for line in f:
        step = json.loads(line)
        if "tool_calls" in step:
            for tc in step["tool_calls"]:
                name = tc.get("name", "")
                if "replace_file_content" in name:
                    tool_calls.append((name, tc.get("args", {})))

def unquote(s):
    if not isinstance(s, str): return s
    try:
        return json.loads(s, strict=False)
    except Exception as e:
        return s

# Stop before we apply the revert
# Let's count back. The revert was: "git checkout HEAD" which was done via run_command, NOT replace_file_content!
# So we just want to apply all replace_file_contents UP TO the one that added the GeometryReader.
# The GeometryReader fix was the VERY LAST replace_file_content.
# The corner mask was the one BEFORE the GeometryReader.
# The `Color.black.opacity(0.8)` revert was the multi_replace BEFORE the corner mask.
# Let's just find the index of the corner mask replace!

for i, (name, args) in enumerate(tool_calls):
    target_file = unquote(args.get("TargetFile", ""))
    if not target_file.endswith("BookView.swift"):
        continue

    desc = unquote(args.get("Description", ""))
    
    # We want to STOP after the corner mask edit.
    # The corner mask edit had description "Restored the page size and restricted the forest image to only show in the outer corners."
    
    if name == "replace_file_content":
        target = unquote(args.get("TargetContent", ""))
        replacement = unquote(args.get("ReplacementContent", ""))
        if target in content:
            content = content.replace(target, replacement)
        else:
            print("  Failed target")
    elif name == "multi_replace_file_content":
        chunks_str = args.get("ReplacementChunks", "[]")
        chunks_str = unquote(chunks_str)
        
        # Regex to find TargetContent and ReplacementContent
        # Format usually looks like {"TargetContent": "...", "ReplacementContent": "...", ...}
        # A simple hack: we can just use json.loads(..., strict=False) but replace newlines or unescaped quotes.
        # Actually, let's just do `eval` or something? No, it's JSON.
        try:
            chunks = json.loads(chunks_str, strict=False)
            for chunk in chunks:
                target = chunk.get("TargetContent", "")
                replacement = chunk.get("ReplacementContent", "")
                if target in content:
                    content = content.replace(target, replacement)
                else:
                    print("  Failed chunk target")
        except:
            print("Failed to parse chunks string in", desc)
    
    if "Restored the page size and restricted the forest image" in desc:
        print("Reached target state! Stopping.")
        break

with open(file_path + ".recovered", "w") as f:
    f.write(content)
print("Done")
