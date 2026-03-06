# Audit Skills: Storage Signed URLs Flow

- **Skills selected**:
  1. **Evidence-First Reading**: To ensure all claims about TTLs and storage paths are backed by actual code (`avatar_service.dart`, `attachment_service.dart`).
  2. **Threat Modeling (Security)**: To analyze the risk of URL leakage, token reuse, and unauthorized bucket access.
  3. **RLS & Privilege Boundaries**: To verify that the storage bucket policies correctly restrict access even if a path is guessed.
  4. **Diagram Crafting (Mermaid)**: To redesign the flow into a more secure and production-ready state.
  5. **State Machine & Lifecycle**: To model the lifecycle of a signed URL from generation to expiration.

- **Why these skills fit**:
  This diagram describes a security-sensitive mechanism (accessing private data). Threat modeling and RLS verification are critical to ensure the "private" data stays private. Evidence-first reading is necessary to correct discrepancies between the diagram and the actual implementation.

- **Skills intentionally not used**:
  - **DB-First Financial Modeling**: No financial transactions are involved in the image retrieval flow.
  - **Idempotency & Concurrency**: While important for uploads, the signed URL generation itself is a read operation where idempotency is trivial.
