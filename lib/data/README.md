# Data Processing Info

## Objects

We have several main objects which correspond to respective tables in the database. These are mapped to one another in the following ways:
    - `Account`: no links
    - `Category`: self-links to child categories
    - `CategoryRule`: link to single category
    - `Tag`: no links
    - `Transaction`: single links to `Account` and `Category`, and one-to-many links to `Tag`, `Allocation` and `Reimbursement`
    - `Allocation`: pairings between a category and a transaction
    - `Reimbursement`: unique pairings between two transactions
The respective mappings are stored and respected in memory, with the only exception being the transactions. Therefore, other than the transactions, objects in memory must always have one unique instance per value. For example, never create two `Category` objects representing the same category. 

On the other hand, transactions should never be persisted in memory outside of UI state. For example, `Reimbursement.target` should only be used for UI and obtaining the `id` of the target transaction.  
Of course, this isn't always possible. For example multiple transaction editors can be open at the same time to the same transaction. Must be extra careful to update any references upon any of the editors saving/deleting.


## App (Memory) State

### Top level

We have several top-level states that are global (or declared in `main()` at least), and those that inherit `ChangeNotifier` are provided to the widget tree via `ChangeNotifierProvider.value`.

- `LibraDatabase`: database manager, not a `ChangeNotifier`.
- `GoogleDrive`: relevant info for syncing with Google Drive.
- `LibraAppState`: the main app state containing a variety of info. Manages some sub classes:
  - `AccountState` (is an independent ChangeNotifier, but is this premature optimization?)
  - `CategoryState` (not a ChangeNotifier...)
  - `RuleState` (not a ChangeNotifier...)
  - `TagState` (not a ChangeNotifier...)
- `TransactionsService`: does not actually store any state, but is the main interface class for anything affecting transactions. Objects that rely on transaction data should subscribe to this service to be notified of when to reload their data. Likewise, all actions affecting transactions MUST be interfaced through this service, which will call `notifyListeners` appropriately.


#### For tabs

These are `ChangeNotifier`s for the individual tabs provided at the same level as the ones above.

- `CategoryTabSTate`
- `CashFlowState`
- `TransactionFilterState`: one of these is created for each transaction list widget, but the top-level one is used exclusively for the transactions tab.


### Nested ChangeNotifiers

- `AddCsvState`: Created for each `AddCsvScreen` added to `Navigator`s.
- `TransactionFilterState`: one of these is created for each transaction list widget:
  - `AccountScreen`
  - `CategoryFocusScreen`
  - `ReimbursementEditor`
  - maybe more
- Settings tab states:
  - `EditAccountState`
  - `EditCategoriesState`
  - `EditTagsState`
  - `EditRulesState`


TODO

### Stateful widgets

Be careful with Stateful widgets containing major state because an app rebuild using `RestartWidget`, i.e. when replacing the database file, will NOT reset the state of these widgets.

TODO

- `SettingsTab`: simply stores the current tab open