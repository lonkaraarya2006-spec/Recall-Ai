# Recall AI — Stage 3 end-to-end demo guide

## Target architecture

```text
React/no-build browser UI
       |
       v
FastAPI backend  <--------------------> Gemini API (direct prompt/output + grounded answer)
       |
       +---- memory extraction, chunking, metadata, source tracking
       |
       +---- SQLite (local records/cache)
       |
       +---- ChromaDB (local vector retrieval)
       |
       +---- Supabase Postgres + pgvector (optional cloud sync and remote vector retrieval)
       |
       +---- public webpage ingestion (validated URL -> text -> memory/index)
       |
       +---- browser speech recognition / speech synthesis (voice UI)
```

The intended RAG path is **question → embedding → retrieve relevant chunks → evidence check → Gemini API → answer + sources**. If evidence is absent, return no-evidence. If Gemini is unavailable, show a clearly labelled evidence preview, not a fabricated answer.

## A. Run on Windows

1. Extract the whole ZIP into a folder.
2. In the project root, copy `.env.example` to `.env` if it does not exist.
3. Add the Gemini key to `GEMINI_API_KEY` inside `.env`. Keep it server-side; never put it in React code or share it in screenshots.
4. Double-click `run_local.bat`. First run creates `.venv`, installs Python dependencies, and launches the FastAPI server. Keep the terminal open.
5. Open `http://127.0.0.1:8000`. API docs: `http://127.0.0.1:8000/docs`.

## B. Verify compulsory live API input/output

1. In **Live LLM Playground**, submit: `Explain Retrieval-Augmented Generation in two short sentences for a college presentation.`
2. Show the prompt input and the returned output, including the actual model name.
3. Click **Test API connection**. A successful response proves that this request reached Gemini. A configured key alone does not prove connectivity.

## C. Verify the core RAG workflow

1. Click **Load sample data** if the local database is empty.
2. Ask: `Which vector database did the team choose, and what does SQLite store?`
3. Show the answer and source cards. Explain that the language model receives retrieved memory evidence in its prompt.
4. Ask something not in the collection, e.g. `What is the exact deadline for our project submission?` Check that the app does not invent a deadline.
5. Edit a memory and repeat the question to show that indexing refreshes; deletion requires confirmation.

## D. Configure the cloud database (Supabase Postgres)

1. Create a Supabase project and copy its project URL and a server-only **Secret API key** (`sb_secret_...`) from the Dashboard. Legacy `service_role` JWTs are also supported, but new projects should prefer the current secret key. Never put a secret key in the browser.
2. Open Supabase **SQL Editor** and run the complete `supabase/schema.sql` file. It creates `recall_memories`, `recall_chunks`, a pgvector index, and the `match_recall_chunks` RPC.
3. Put these values in the project-root `.env` and restart the server:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SECRET_KEY=your-server-only-secret-key
```

4. In the app, click **Test cloud connection**. It should report Supabase Postgres reachable once both tables exist.
5. Click **Sync saved memories**. This writes local records and chunks to Supabase.
6. The cloud pgvector search path is available only when the active embedding model emits 384 dimensions, matching `sentence-transformers/all-MiniLM-L6-v2`. If the model falls back to an 8192-dimensional hashing vectorizer, the app continues to sync smaller record metadata/text, but it falls back to the local vector index for searching. Check `/api/health` for the actual embedding backend and dimension.

Note: this is a local-first, single-user classroom prototype with best-effort cloud synchronization. It has not been configured with your project credentials in this build environment, so live cloud connectivity must be verified on your machine.

## E. Additional features to demonstrate

- **Smart memory connections:** click Connections on a saved memory; the app explains why records are linked (semantic similarity, shared topics, people, tags).
- **Online fetching:** submit a public HTML/text URL. Recall extracts readable content, stores the original URL as the source, and indexes it. Some sites block automated access; private/local addresses and redirects are blocked.
- **Voice:** use Speak to transcribe a question and Read answer to hear the result. Requires Chrome/Edge speech support and microphone permission.

## Troubleshooting

- `GEMINI_API_KEY is not configured`: check `.env` in the same folder as `run_local.bat`, then restart the backend.
- Gemini returns `401/403`: check that the key is active and has API access. A 429/503 may be quota or temporary provider capacity; don't present it as a successful generation.
- Supabase `401`: check URL/key pairing and make sure a server-only secret/service-role key is used. New `sb_secret_...` keys are sent via `apikey`; legacy service-role JWTs are also sent as bearer tokens.
- Supabase `404`/missing relation or RPC: run `supabase/schema.sql` against the correct project and check the REST API/schema exposure.
- Cloud search not enabled: confirm `/api/health` reports the Sentence Transformers model and dimension `384`. Otherwise local retrieval remains the fallback.
- `python` missing: install Python 3.11/3.12 with **Add Python to PATH**, reopen the terminal, and launch again.

## Verification note

21 automated tests passed in the build environment, including mocked LLM/cloud API tests. Those tests validate application logic and payloads but do not replace a live Gemini call or a live Supabase connection test using your credentials.
