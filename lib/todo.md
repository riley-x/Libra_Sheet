## Bugs


## High priority features


## Medium priority features
- Start screen and UX
- Choose category/account on CSV column?
- Delete account
- sort transactions by value?
- Loading scrim across full app?
- Load more transactions on reach end of transaction grid?


## Refactor
- Undo make AccountState an independent ChangeNotifier; huge hassle, need to watch the state everywhere you use an account. Alternative is to always fetch the account object from the AccountState instead of making it linked in other objects, to force the watch.
- Remove MutableAllocation


## Low priority features
- Animate bar charts?
- Day-by-day charts?
- Custom other categories
