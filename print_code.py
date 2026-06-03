import json
import ast
import re

transcript_path = "/Users/cirogiovannicalisto/.gemini/antigravity-ide/brain/adf350c6-5bed-4d1a-879d-d517cdd04755/.system_generated/logs/transcript.jsonl"
with open(transcript_path, "r") as f:
    for line in f:
        step = json.loads(line)
        if "tool_calls" in step:
            for tc in step["tool_calls"]:
                name = tc.get("name", "")
                if name == "replace_file_content":
                    args = tc.get("args", {})
                    desc = args.get("Description", "")
                    if "Restored the page size and restricted the forest image" in desc:
                        print("==== CORNER MASK PAGE CONTAINER ====")
                        print(args.get("ReplacementContent", ""))
                elif name == "multi_replace_file_content":
                    args = tc.get("args", {})
                    desc = args.get("Description", "")
                    if "Changed the layout so text is always on the left" in desc:
                        print("==== 2 COLUMN LAYOUT ====")
                        raw = args.get("ReplacementChunks", "[]")
                        # Since raw is a JSON string of a JSON array, we can use ast.literal_eval if it's single quoted, or json.loads
                        try:
                            chunks = json.loads(raw, strict=False)
                            for c in chunks:
                                print("--- REPLACE: ---")
                                print(c.get("ReplacementContent", ""))
                        except Exception as e:
                            print("ERROR PARSING", e)
                            print(raw[:200])
                    if "Flattened layout" in desc or "Continuous" in desc:
                        print("==== FLATTENED ====")
                        raw = args.get("ReplacementChunks", "[]")
                        try:
                            chunks = json.loads(raw, strict=False)
                            for c in chunks:
                                print("--- REPLACE: ---")
                                print(c.get("ReplacementContent", ""))
                        except Exception as e:
                            print("ERROR PARSING", e)
                            
