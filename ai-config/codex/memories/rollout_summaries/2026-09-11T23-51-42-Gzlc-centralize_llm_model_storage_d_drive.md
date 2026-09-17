thread_id: 01a092e2-5a68-7e92-8aab-a5fdfc7ef13e
updated_at: 2026-09-12T01:12:50+00:00
rollout_path: C:\Users\kazum\.codex\sessions\2026\09\12\rollout-2026-09-12T08-51-42-01a092e2-5a68-7e92-8aab-a5fdfc7ef13e.jsonl
cwd: \\?\D:\

# Consolidated the user's Windows LLM model storage under `D:\Models` and documented the remaining compatibility and verification gaps.

Rollout context: From `D:\`, the user wanted model files centralized and discoverable by AI and tools such as LM Studio, Unsloth, llama.cpp, and vLLM. After asking about tradeoffs, the user explicitly approved a plan and said, “PLEASE IMPLEMENT THIS PLAN.” The plan prohibited stopping models in use, deleting duplicate models, redownloading or converting existing models, and treating unverified runtimes as verified.

## Task 1: Centralize and document local model storage

Outcome: partial

Preference signals:
- The user asked for “モデル使用場所っていうのを統一させて、今後AIにも分かるような形” and later explicitly approved implementation. For similar storage-management tasks, create both a shared physical organization and AI-readable instructions/catalog, rather than merely recommending a folder.
- The approved plan says not to stop models in use, remove duplicates, redownload or convert models, and to keep compatibility links when relocating files. Preserve existing paths and verify actions before cleanup.
- The user said chat testing “あんまり重視しているわけじゃない” -> prioritize reliable model organization and usable paths; basic chat checks are secondary to the storage goal.

Key steps:
- Inspected `D:\Models`, LM Studio/Bionic settings, Unsloth Studio's SQLite settings, caches, and installed tools. Existing models included GGUF and safetensors; several Python processes were not fully inspectable, so the in-use Qwen GGUF was not moved or unloaded.
- Implemented `D:\Models\model_library.py` and `model-library.ps1`, catalog and verification records, setup guidance, recovery procedures, and `D:\Models\AGENTS.md` for future AI discovery.
- Moved eligible models and caches into organized D-drive locations while retaining old paths with links. Set LM Studio to `D:\Models\gguf`; configured Unsloth and Windows/WSL cache paths under `D:\Models`. Kept application-owned LM Studio embedding data and other explicitly excluded caches/settings intact.
- Downloaded small public GGUF test models through LM Studio, Unsloth's standard download service, and the shared command, then recorded them in the library. A malformed GGUF test artifact was retained as a flagged exception rather than presented as usable.
- Ran the model-library test suite; final output was 13 tests passing. Final inventory had 24 entries and no scan issues; all recorded storage settings matched. A separate migration check verified 13 old-path links and 232 preserved file references/sizes.
- Checked selected local workloads: two OCR models and a layout-detection model produced outputs, and an embedding model produced a 768-dimensional vector. Recorded dependency, memory, and incomplete-model problems for other candidates rather than labeling them working.

Failures and how to do differently:
- The original directory switch in LM Studio had not exposed the existing models because the expected library hierarchy was missing. Use supported import/library paths or a managed linked view, and validate actual Library visibility rather than assuming a changed root recursively indexes arbitrary folders.
- File format and runtime compatibility are separate from storage. GGUF, safetensors, CTranslate2, embeddings, assistant/draft models, and cloud references require distinct catalog entries and runtime expectations; do not call a cache entry or cloud tag a locally runnable model.
- Full rollout verification remains incomplete: app restart behavior was not tested; WSL-specific new model download and Ollama inference were not tested; vLLM was not installed or exercised. Avoid presenting the whole catalog as validated by the partial workload checks.
- The final catalog retained six findings for incomplete/invalid models or missing metadata. Consult `D:\Models\STATUS.md` for per-model status and causes.

Reusable knowledge:
- `D:\Models\README.md` is the operational guide; `D:\Models\AGENTS.md` points future agents to the catalog and rules; `D:\Models\models.json` is the current inventory; `D:\Models\verification.json` is the execution history. `STATUS.md` summarizes this rollout's results and limitations.
- The shared manager implements `sync`, `get`, and `check`; it avoids duplicating weights where hardlinks work and retains legacy paths. Newly introduced apps still need their own storage configuration.
- LM Studio's Bionic settings were in `C:\Users\kazum\.lmstudio\apps\bionic\settings.json`; its library can display linked GGUFs. Unsloth's `studio.db` stores custom scan folders and HF cache settings.
- WSL accesses the shared Windows drive at `/mnt/d/Models`; its Hugging Face download cache is deliberately isolated under `cache/huggingface/wsl-native` to avoid simultaneous Windows/WSL cache writes.

References:
- `D:\Models\README.md`, `AGENTS.md`, `STATUS.md`, `models.json`, `verification.json`, `model_library.py`, `model-library.ps1`, and `test_model_library.py`.
- Evidence and recovery snapshots: `D:\Models\management\unified-v2\` and `D:\Models\management\20260912\`.
- Final checks: 13 tests passed; 13 old-path links and 232 preserved file references/sizes verified; inventory had 24 entries and no scan issues; settings matched, while six catalog findings remained.

