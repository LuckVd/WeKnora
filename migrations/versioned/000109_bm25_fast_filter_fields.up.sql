-- Issue #3301: KeywordsRetrieve filters every keyword search by
-- knowledge_base_id and is_enabled next to the content ||| ? index match.
-- The bootstrap index in 00-init-db.sql carries neither column as a fast
-- field: knowledge_base_id is a plain indexed column (no keyword tokenizer,
-- not fast) and is_enabled is not part of the index at all, so both
-- predicates degrade to heap filters over every candidate row.
--
-- Rebuild the index with knowledge_base_id tokenized as a keyword fast field
-- (keyword-tokenized fields support equality pushdown per the ParadeDB
-- legacy docs shipped with paradedb v0.22.2-pg17) and is_enabled as a
-- boolean fast field. Fresh ParadeDB installs bootstrap through
-- 00-init-db.sql and converge to this shape via this migration.
--
-- CREATE INDEX CONCURRENTLY is deliberately not used: golang-migrate wraps
-- each versioned migration in a transaction, and concurrent builds cannot
-- run inside one. The one-time rebuild cost is accepted.
DROP INDEX IF EXISTS embeddings_search_idx;

CREATE INDEX IF NOT EXISTS embeddings_search_idx
USING bm25 (id, knowledge_base_id, is_enabled, content, knowledge_id, chunk_id)
WITH (
    key_field = 'id',
    text_fields = '{
        "content": {
          "tokenizer": {"type": "chinese_lindera"}
        },
        "knowledge_base_id": {
          "fast": true,
          "tokenizer": {"type": "keyword"}
        }
    }',
    boolean_fields = '{
        "is_enabled": {
          "fast": true
        }
    }'
);
