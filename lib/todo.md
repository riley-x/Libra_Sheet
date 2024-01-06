## Bugs


## High priority features
- Reorder tags
- Add warning to back on CSV transactions
- Start screen, UX
- Better reimbursement/allocation cards in transaction details

## Medium priority features
- Rerun category rule
- Choose category/account on CSV column?
- Delete account
- Range account screen graphs?
- Fix navbar animation


## Refactor
- Replace all database calls with extension (see tags.dart).
- Convert some appState stuff into independent ChangeNotifiers? Be careful with this though...like everything that 
  watches a transaction actually watches both account state and category state...


## Low priority features
- Load more transactions on reach end of transaction grid?
- Reimburse/category multiple transactions?
- Rethink transaction details UI, especially reimbursements?
- Animate bar charts?
- Maybe balance update? Specifically for investments?
