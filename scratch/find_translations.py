import json
import os

log_path = "/Users/marcelloguida/.gemini/antigravity-ide/brain/b1ccf09e-9a3a-4ecd-beda-c05fc310fa75/.system_generated/logs/transcript.jsonl"

with open(log_path, "r", encoding="utf-8") as f:
    for line in f:
        try:
            data = json.loads(line)
            tool_calls = data.get("tool_calls", [])
            for call in tool_calls:
                if call.get("name") == "write_to_file":
                    args = call.get("args", {})
                    if isinstance(args, str):
                        args = json.loads(args)
                    
                    target = args.get("TargetFile", "")
                    content = args.get("CodeContent", "")
                    
                    if ".lproj" in target:
                        target = target.strip('"').strip("'")
                        
                        # Properly decode the string to resolve escape characters like \n and \"
                        if isinstance(content, str):
                            content_stripped = content.strip()
                            if content_stripped.startswith('"') and content_stripped.endswith('"'):
                                try:
                                    content = json.loads(content_stripped)
                                except Exception:
                                    pass
                        
                        print(f"Recreating file: {target}")
                        os.makedirs(os.path.dirname(target), exist_ok=True)
                        with open(target, "w", encoding="utf-8") as out_f:
                            out_f.write(content)
        except Exception as e:
            pass
