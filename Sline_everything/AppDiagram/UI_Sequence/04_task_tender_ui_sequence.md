# 8.6 Task Details Flow

# 8.7 Create / Edit Task Flow

# 8.8 Tender Requests / Offer Flow

## Purpose

Managing the core tender task lifecycle: A client creates a task, freelancers submit price/day proposals, and the client awards/pays for one proposal.

## Sequences

### Create Task Sequence

```mermaid
sequenceDiagram
    participant Client
    participant CreateTaskUI
    participant TaskVM
    participant Storage
    participant DB

    Client->>CreateTaskUI: Fill title, budget, description, select images
    Client->>CreateTaskUI: Tap "Publish Task"

    CreateTaskUI->>TaskVM: createTask(data)
    TaskVM->>CreateTaskUI: Show Loading Overlay

    alt Has Images
        TaskVM->>Storage: uploadBinary(task-images)
        Storage-->>TaskVM: Image Paths
    end

    TaskVM->>DB: insert('tasks', { status: 'open', task_type: 'tender' })
    DB-->>TaskVM: Task Row

    TaskVM->>CreateTaskUI: Hide Overlay
    CreateTaskUI->>TaskDetails: Push Replacement to Task Page
```

### Submit Proposal & Award Flow (Tender)

```mermaid
flowchart TD
    Freelancer[Freelancer] -->|View Task| Details[Task Details]
    Details -->|Tap Submit Bid| BidModal[[Submit Proposal Sheet]]
    BidModal -->|Enter Price/Days| Submit[TaskRequestsService]
    Submit -->|Insert DB| Success[Pop Sheet & Show Toast]

    Client[Client Owner] -->|Checks Task| Inbox[Task Requests Inbox]
    Inbox -->|Views Offer| Offer[Review Candidate]
    Offer -->|Accept & Pay| AwardFlow((Award -> Checkout))

    AwardFlow -->|Verify Price| RPC_Award[rpc: award_task_offer]
    RPC_Award --> PaymentService[QiCard Payment]
    PaymentService -->|Success| Ledger[Release to Held/Assigned]
```

## Implementation Alignment

- **Award locks price**: `award_task_offer` uses an optimistic price lock (`expectedPriceCents`). If the freelancer changed the price right before the award, it fails safely, showing `PriceMismatchException` to the client.
- **Auto-Expiration**: Unpaid awards expire. Countdown is shown via `AwardExpirationMonitor` on the Dashboard and Task details.

## Screen Details

- **Task Details Screen**: Analyzes whether viewer is Owner, Bidder, or Unrelated to resolve the main Call to Action (CTA) button state.
