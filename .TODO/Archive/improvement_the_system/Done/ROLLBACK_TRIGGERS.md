# Rollback Triggers: Tender Task Lifecycle

**Purpose**: Data-driven criteria for deciding when to rollback the tender task lifecycle changes  
**Owner**: Engineering Lead + Product Manager  
**Review Frequency**: Daily during rollout

---

## Automatic Rollback Triggers

These conditions trigger an immediate rollback discussion:

### Trigger 1: Stuck Tasks Spike
```sql
-- Run this query daily during rollout
SELECT 
  COUNT(*) FILTER (WHERE awarded_at < NOW() - INTERVAL '72 hours') as stuck_gt_72h,
  COUNT(*) FILTER (WHERE awarded_at < NOW() - INTERVAL '48 hours') as stuck_gt_48h,
  COUNT(*) as total_unpaid_assigned,
  (COUNT(*) FILTER (WHERE awarded_at < NOW() - INTERVAL '72 hours')::float / 
   NULLIF(COUNT(*), 0) * 100) as stuck_percentage
FROM task_requests 
WHERE status = 'accepted' 
  AND payment_status = 'unpaid';
```

| Threshold | Action |
|-----------|--------|
| Stuck > 5% of total | Investigate immediately |
| Stuck > 10% of total | **ROLLBACK** |
| Stuck count > 50 | **ROLLBACK** |

---

### Trigger 2: Price Mismatch Error Spike
```sql
-- Check admin_logs for price mismatch attempts
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as mismatch_count
FROM admin_logs 
WHERE action = 'PRICE_MISMATCH_ATTEMPT'
  AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

| Threshold | Action |
|-----------|--------|
| > 10 mismatches/hour | Monitor closely |
| > 50 mismatches/hour | Investigate UI bug |
| > 100 mismatches/hour | **ROLLBACK** (possible exploit) |

---

### Trigger 3: Acceptance Failure Rate
```sql
-- Check acceptance success vs failure
SELECT 
  action,
  COUNT(*)
FROM admin_logs 
WHERE action IN ('offer_accepted', 'PRICE_MISMATCH_ATTEMPT', 'ACCEPT_ERROR')
  AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY action;
```

| Threshold | Action |
|-----------|--------|
| Failure rate > 20% | Investigate UI/UX issues |
| Failure rate > 50% | **ROLLBACK** |

---

### Trigger 4: Cron Job Failure
```sql
-- Check cron job health
SELECT 
  jobid,
  jobname,
  schedule,
  next_run,
  last_run,
  last_success 
FROM cron.job 
WHERE jobname = 'cleanup-expired-awards';
```

| Condition | Action |
|-----------|--------|
| last_success < last_run | Cron failing - investigate |
| next_run > NOW() + INTERVAL '20 minutes' | Schedule broken - **ROLLBACK** |

---

## Manual Rollback Triggers

These require human judgment:

### User Complaints
- [ ] > 5 user complaints about "accept not working" in 24h
- [ ] Any complaint about "lost money" or "double charge"
- [ ] Social media mentions of bidding bugs

### Performance Issues
- [ ] accept_task_request RPC latency > 2 seconds (p95)
- [ ] cleanup_expired_awards query time > 1 minute
- [ ] Database CPU spike after deployment

### Business Metrics
- [ ] Tender task creation drops > 30% vs previous week
- [ ] Offer acceptance rate drops > 50% vs previous week

---

## Rollback Procedure

If rollback triggered:

1. **Immediate (5 minutes)**:
   ```sql
   -- Unschedule cron to stop auto-expiry
   SELECT cron.unschedule('cleanup-expired-awards');
   ```

2. **Short-term (15 minutes)**:
   ```sql
   -- Revert RPC to previous version (without expected_price param)
   -- See migration: 20260306_rollback_tender_guardrails.sql
   ```

3. **Communication (30 minutes)**:
   - Post in #incidents channel
   - Notify customer support
   - Update status page if user-facing

4. **Investigation (ongoing)**:
   - Preserve admin_logs from incident period
   - Collect affected task_ids
   - Prepare post-mortem

---

## Rollback Checklist

- [ ] Cron unscheduled
- [ ] RPC reverted
- [ ] Index dropped (if causing issues)
- [ ] Flutter code reverted
- [ ] Users notified (if needed)
- [ ] Incident doc created
- [ ] Post-mortem scheduled

---

## Emergency Contacts

| Role | Name | Contact | Escalation |
|------|------|---------|------------|
| Backend Lead | TBD | @backend-lead | CTO |
| Mobile Lead | TBD | @mobile-lead | CTO |
| On-call Engineer | TBD | PagerDuty | Engineering Lead |
| Product Manager | TBD | @pm | VP Product |
