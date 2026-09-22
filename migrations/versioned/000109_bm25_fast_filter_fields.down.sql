-- Restore the original bootstrap index shape from 00-init-db.sql (without
-- the fast filter fields introduced in the matching up migration).
DROP INDEX IF EXISTS embeddings_search_idx;

CREATE INDEX IF NOT EXISTS embeddings_search_idx
USING bm25 (id, knowledge_base_id, content, knowledge_id, chunk_id)
WITH (
    key_field = 'id',
    text_fields = '{
        "content": {
          "tokenizer": {"type": "chinese_lindera"}
        }
    }'
);
