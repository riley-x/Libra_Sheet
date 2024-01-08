## Bugs


## High priority features
- Reorder tags
- Start screen, UX
- Better reimbursement/allocation cards in transaction details

## Medium priority features
- Rerun category rule
- Choose category/account on CSV column?
- Delete account
- Range account screen graphs?
- Fix navbar animation (maybe just add a delay on the expanded change that matches the animation speed of the navbar)


## Refactor
- Undo make AccountState an independent ChangeNotifier; huge hassle, need to watch the state everywhere you use an account.


## Low priority features
- Load more transactions on reach end of transaction grid?
- Bulk edit transactions
- Rethink transaction details UI, especially reimbursements?
- Animate bar charts?
- Maybe balance update? Specifically for investments?
