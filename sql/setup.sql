-- Supabase setup for the Enterprise Policy Q&A Bot
-- Run in the Supabase SQL editor, one block at a time.

-- 1. Enable pgvector
create extension if not exists vector;

-- 2. Table that holds one row per chunk (4,096 = Qwen3-Embedding-8B dimension)
create table documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(4096)
);

-- 3. Row Level Security: on, with no policies. The public keys get no access;
--    the n8n secret (service role) key bypasses RLS.
alter table documents enable row level security;

-- 4. Search function used by the n8n Supabase Vector Store node
create or replace function match_documents (
  query_embedding vector(4096),
  match_count int default null,
  filter jsonb default '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Check: chunks loaded per document
-- select metadata->>'doc_name' as document, count(*) as chunks
-- from documents group by 1 order by 1;

-- Reset before re-ingesting (for example after changing the chunk size)
-- truncate table documents;
