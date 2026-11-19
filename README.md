# Enterprise Policy Q&A Bot (Pharma Compliance RAG)

A no-code RAG assistant built in n8n. It answers plain-English questions about pharma compliance guidance, cites the document and page for every claim, and replies "I could not find this in the indexed documents." when the answer is not there.

Project 1, Track 1 (n8n) of The Gen Academy Week 2 RAG project.

## Corpus
Four public PDFs, 141 pages, 404 chunks: PhRMA Code (2022), OIG Special Fraud Alert on Speaker Programs (2020), OIG Compliance Program Guidance for Pharmaceutical Manufacturers (2003), OIG General Compliance Program Guidance (2023). See `corpus/SOURCES.md`.

## Architecture
Two n8n workflows share one Supabase table.

1. `workflows/01_Ingestion.json`: form upload of a PDF, page-by-page loader (Split Pages in PDF enabled) with metadata (`doc_name`, `publisher`, `year`, page), recursive splitter (1,200 characters, 200 overlap), Nebius embeddings (`Qwen/Qwen3-Embedding-8B`, 4,096 dimensions), insert into Supabase pgvector.
2. `workflows/02_policy_qa_agent.json`: chat trigger, AI Agent (`Qwen/Qwen3-30B-A3B-Instruct-2507` on Nebius, temperature 0) with a `policy_search` tool: embed the question, fetch the top 25 chunks from Supabase, rerank with Cohere `rerank-v3.5`, keep the top 8.

## Repository contents
| Path | What it is |
| --- | --- |
| `workflows/` | Exported n8n workflow JSON (no secrets; credentials are referenced by name only) |
| `sql/setup.sql` | pgvector extension, `documents` table, `match_documents` function |
| `prompts/system_prompt_v2.md` | Final agent system prompt |
| `prompts/system_prompt_v1.md` | First version of the system prompt (kept for comparison) |
| `corpus/SOURCES.md` | Where the four PDFs came from |

## How to rebuild
1. Create a Supabase project and run `sql/setup.sql`.
2. In n8n, create credentials for Nebius (OpenAI-compatible, base URL `https://api.tokenfactory.nebius.com/v1/`), Supabase and Cohere.
3. Import both workflow JSON files and select your credentials in each node.
4. Run `01_Ingestion` once per PDF, then open the chat in `02_policy_qa_agent`.

## Evaluation
15-question evaluation (ambiguous, multi-document and unanswerable questions) with retrieval and faithfulness scores, iterations and failure analysis: see the project documentation (link below).

Known limitations: a key sentence can fall in a neighbouring chunk (alcohol rule question), and the consultant-arrangement sections are not always retrieved for broad control questions. Ideas: smaller chunks with more overlap, hybrid keyword and vector search.

## Links
- Documentation: TODO
- Demo video: TODO
