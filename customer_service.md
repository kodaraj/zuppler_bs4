Order states:
  - executing
  - missed
  - canceled
  - confirmed
  - editing
  - invoiced

Contains:
  - order v4 url
  - state
  - due date
  - restaurant

OrderQueueManager
  - .notify order - sends order notifications
  - removes expired orders (past due)

Sending to (queues):
  - customer service (all)
  - restaurant staff
  - restaurant owner
  - ambassadors

Order Search service
