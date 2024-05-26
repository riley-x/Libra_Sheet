## Bugs
  

## High priority features
- Allow reimb/allocs to be negative in UI, just abs them.


## Medium priority features
- Start screen and UX
- Choose category/account on CSV column?
- Delete account
- Include allocation names in filter search
- sort transactions by value?
- Loading scrim across full app?


## Refactor
- Undo make AccountState an independent ChangeNotifier; huge hassle, need to watch the state everywhere you use an account.
- Remove MutableAllocation


## Low priority features
- Load more transactions on reach end of transaction grid?
- Animate bar charts?
- Day-by-day charts?
