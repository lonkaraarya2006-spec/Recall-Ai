# Recall AI — End-to-End Architecture and AI-DS Rationale

## 1. Core idea

**Recall AI is an evidence-linked personal memory and decision-intelligence assistant.** It stores user-provided notes/documents and selected public webpages, retrieves the most relevant passages for a natural-language query, and uses a cloud LLM to explain the answer with supporting source evidence. It can also surface related memories and flag when evidence is missing or potentially conflicting.

The project is not intended to be a general chatbot that makes up personal facts. Its differentiator is the connection between a generated answer and the specific memories that support it.

## 2. Architecture

```text
React / included browser UI
        |  save memory / ask question / upload / fetch URL
        v
Python + FastAPI backend
        |
        +--> Ingestion service: validate -> extract -> chunk -> metadata
        |         |                         |
        |         v                         v
        |      SQLite                 Embedding service
        |   (local source of truth)          |
        |                                    +--> ChromaDB (local vector index)
        |                                    |
        |                                    +--> Supabase Postgres + pgvector (cloud, when configured)
        |
        +--> RAG query service: embed query -> retrieve -> filter/rank -> evidence check
        |                                                      |
        |                                                      v
        |                                                  Gemini API
        |                                                      |
        +<---------------- answer + source references + response mode
        |
        v
UI shows grounded answer, citations/source snippets, or explicit evidence preview/no-evidence result
```

## 3. End-to-end memory ingestion

1. The user enters text, uploads a supported PDF/DOCX/TXT/MD file, or submits a public webpage URL.
2. FastAPI validates input and extracts readable text while keeping source metadata.
3. Text is split into chunks. Each chunk points to its parent memory and source location when available.
4. SQLite stores the original memory, metadata, and indexing state.
5. The embedding service generates a vector for each chunk. ChromaDB stores the local vector index.
6. If Supabase is configured, the record and chunk content are synced to Postgres. With the expected 384-dimensional Sentence Transformers model active, the vector is also stored in pgvector for cloud-side semantic retrieval.

## 4. End-to-end RAG question answering

1. The user asks a natural-language question.
2. The same embedding model transforms the question into a vector.
3. The backend searches the configured retrieval path, applies available metadata filters, and ranks relevant chunks.
4. The evidence gate checks whether the collection has useful supporting passages.
5. When evidence is adequate and Gemini is configured, FastAPI sends Gemini the question and the selected excerpts with instructions to stay grounded in them.
6. The UI returns the model answer with the supporting sources. If generation fails, it must identify the fallback as an evidence preview; if evidence is absent, it should say so instead of inventing a personal fact.

RAG reduces the need to put private memory into model training; content is supplied at query time. It does not guarantee truth by itself, so source inspection, a no-evidence path, and testing remain important.

## 5. Why these components

| Component | Responsibility | Subject significance |
|---|---|---|
| React / browser UI | Forms, library, question display, voice controls | Human-computer interaction |
| FastAPI / Python | Input validation, API routes, orchestration | Backend/API integration |
| Gemini API | Direct LLM prompt-output and grounded generation | Cloud AI model integration; prompt design |
| Sentence Transformers | Text/query embeddings (384 dimensions in the configured model) | Representation learning / NLP |
| ChromaDB | Local approximate vector retrieval | Vector databases and similarity search |
| SQLite | Local source records and metadata | Persistence and structured data |
| Supabase Postgres + pgvector | Optional cloud persistence and remote vector search | Cloud database connectivity and vector SQL |
| Source evidence and fallback | Visible provenance and controlled unsupported-answer handling | Evaluation, transparency, responsible AI |

## 6. Cloud database responsibilities

SQLite and ChromaDB keep the prototype usable locally. Supabase is an additional remote store to demonstrate cloud connectivity and allow remote pgvector search. Run `supabase/schema.sql`, set `SUPABASE_URL` and the server-only `SUPABASE_SECRET_KEY` in the project-root `.env`, restart the backend, test the cloud connection, and sync saved memories.

**Important:** Supabase connectivity is not live until credentials are configured and the dashboard connection check succeeds. Keep the secret key on the backend only. Supabase states that secret keys have elevated privileges and bypass Row Level Security, so they must not be exposed in browser code. See the [Supabase API key security guide](https://supabase.com/docs/guides/getting-started/api-keys). The supplied SQL uses pgvector for embedding storage and similarity retrieval; Supabase's [pgvector guide](https://supabase.com/docs/guides/database/extensions/pgvector) documents this architecture.

## 7. Implemented features and limits

Implemented in this codebase: text/document memory ingestion, metadata, local persistence, embedding/chunk retrieval, Gemini REST integration, RAG source evidence, explicit preview fallback, direct LLM playground, webpage text ingestion with URL restrictions, browser voice input/output, on-demand related-memory connections, optional Supabase sync/pgvector search, and Windows startup script.

Environment-dependent and requiring live verification: real Gemini API responses, actual Supabase connection and SQL migration, browser microphone support, and remote pgvector results.

Not implemented as production features: multi-user authentication and tenant isolation, image/OCR ingestion, permanent graph storage, and unrestricted autonomous agents/function calling. The current project is a single-user classroom prototype; do not claim production deployment or untested features.

## 8. Demonstration order

1. Open the app and show the health/status indicators.
2. Save or load a sample memory and show it in the library.
3. Ask a paraphrased question, then show the retrieved source evidence.
4. Use Live LLM Playground for a separate, direct API input/output proof.
5. Test the Gemini connection using the UI control.
6. If configured, test Supabase connection and sync local memories, then show cloud status.
7. Open Smart Memory Connections, then try a public webpage and voice input if the browser allows them.
8. Ask an unanswerable question to demonstrate the no-evidence path.

## 9. Verification policy

The automated test suite exercises application logic and mocks external LLM/cloud responses. A passing mocked test is not proof of live external connectivity. For final submission, record the actual date and screen evidence for `/api/llm/test`, `/api/cloud/status`, a successful LLM playground output, one RAG answer with sources, and one no-evidence query. Do not record a cloud or LLM integration as successful unless the live request succeeds.
