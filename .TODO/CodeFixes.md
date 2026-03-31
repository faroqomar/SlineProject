 Not fixed (by design):                                                          
  - A7 (core service imports feature views) and A8 (business logic in views) — not
   reliably detectable via grep. These need code review, not CI automation.       
  - Architecture guard still exits 0 — this is the documented Phase A decision. 
  Phase B will change to exit 1.  