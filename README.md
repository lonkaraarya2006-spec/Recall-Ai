# Recall AI

**AI-Powered Personal Digital Memory Assistant**

Recall AI stores the notes and documents you choose to give it and lets you
find them later by asking natural-language questions. It finds information
by meaning, not just exact keywords, and shows the source behind every answer.

## Features
- Save text memories with optional title, date, topic, people and tags
- Upload TXT, MD, PDF and DOCX files (text is extracted, chunked and indexed)
- Semantic search using Sentence Transformers (all-MiniLM-L6-v2) and ChromaDB
- Metadata filters: topic, person, source and date
- RAG answers through the Google Gemini API, shown with source cards
- Honest fallbacks: a "not enough evidence" response when nothing relevant
  is found, and a labelled evidence preview if the cloud model is unavailable
- Memory library with timeline view, edit (with re-indexing) and delete
  (explicit confirmation required)

## Tech Stack
| Layer | Technology |
|---|---|
| Backend | Python, FastAPI |
| Records | SQLite |
| Vector search | ChromaDB (SQLite fallback) |
| Embeddings | Sentence Transformers (all-MiniLM-L6-v2) |
| LLM | Google Gemini REST API |
| Frontend | Browser UI (React/Vite source included) |
| Testing | pytest |

## How it works
1. Capture: save a note or upload a file
2. Index: text is cleaned, chunked, embedded and stored (SQLite + ChromaDB)
3. Recall: your question is embedded and matched against stored chunks
4. Verify: metadata filters and a relevance check decide if evidence exists
5. Answer: Gemini writes a grounded answer, or the app shows the evidence directly

## Project Status
Local, single-user prototype. The automated API test suite passes (12 tests).
Not yet implemented: authentication, function calling, OCR for scanned PDFs,
load benchmarks and hosted deployment.

## Run the tests
    python -m pytest -q backend/tests

## Configuration
Create a `.env` file (never commit it):
    GEMINI_API_KEY=<your-private-key>
    GEMINI_MODEL=<model-name>
    DATABASE_PATH=backend/data/recall_ai.db
    VECTOR_BACKEND=auto
    EMBEDDING_BACKEND=auto
    EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

## Team
Aarya Lonkar and Jay Mahadik, Shah & Anchor Kutchhi Engineering College (SAKEC), Mumbai
