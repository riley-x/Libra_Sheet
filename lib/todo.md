## Bugs
- Add warning if trying to save trans reimb the same target twice (database ignores since primary key on target).

## High priority features


## Medium priority features
- Rerun category rule
- Choose category/account on CSV column?
- Delete account
- Range account screen graphs?


## Refactor
- Replace all database calls with extension (see tags.dart).
- Convert some appState stuff into independent ChangeNotifiers? Be careful with this though...like everything that 
  watches a transaction actually watches both account state and category state...


## Low priority features
- Load more transactions on reach end of transaction grid?
- Animate bar charts?
- Automatic cloud backup?
- Maybe balance update? Specifically for investments?
