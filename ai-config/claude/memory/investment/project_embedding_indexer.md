---
name: disclosure_embedding_indexer 新規追加（2026-04-17）
description: knowledge.embeddings 書き込み側パイプラインとして tools/analytics/disclosure_embedding_indexer を新設
type: project
originSessionId: e7e17beb-8903-4542-84ea-c6951fc28e0e
---
`knowledge.embeddings` (pgvector 768次元 + HNSW cos) は ARCH-003 Step 3-B で
canonical 化済みだったが書き込み側が欠落していた。2026-04-17 に
`tools/analytics/disclosure_embedding_indexer/` を新設して埋めた。

**Why:** semantic search / RAG 導線の前提となる pgvector テーブルが空で、
disclosure_search（全文検索）と対になる意味検索レーンが立ち上がっていなかった。

**How to apply:**
- 書き込み元: `knowledge.sections.content` → sentence 分割 → 400字 chunk → `knowledge.embeddings`
- Embedding backend: Ollama `/api/embeddings` with `nomic-embed-text`（768次元）。
  事前に `ollama pull nomic-embed-text` が必要
- source_type='knowledge.sections' で運用。将来 passages / memos を足すときは
  同じ table に source_type を増やす設計
- Scheduler: `disclosure-embedding-index-daily` が
  `disclosure-search-index-daily` の後段で走る（manifest depends_on）
- 環境変数: `EMBEDDING_PROVIDER/MODEL/DIM/MAX_CHARS/OLLAMA_TIMEOUT_SEC/MAX_RETRIES`
- Chunker は `disclosure_search.sentence_tokenizer.tokenize_sentences` を再利用
- Alembic が knowledge 系 authority（`docs/decisions/knowledge-schema-authority.md`）
  なので greenfield DDL 増補は不要、既存 84_knowledge.sql の embeddings 表をそのまま使う
