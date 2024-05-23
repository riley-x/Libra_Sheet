## Bugs
  

## High priority features
- sort transactions by value
- Bulk edit transactions, multiselect (sum)


## Medium priority features
- Start screen and UX
- Rerun category rule
- Choose category/account on CSV column?
- Delete account


## Refactor
- Undo make AccountState an independent ChangeNotifier; huge hassle, need to watch the state everywhere you use an account.


## Low priority features
- Load more transactions on reach end of transaction grid?
- Animate bar charts?
- Allow reimb/allocs to be negative in UI, just abs them.
- Day-by-day charts
- Include allocation names in filter search
