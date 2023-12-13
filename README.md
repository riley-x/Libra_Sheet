# Libra Sheet

This is a Flutter app for tracking and categorizing your expenses. It is designed for desktop environments.

## Preview

You can preview a web-based sample at [riley-x.github.io/Libra_Sheet](https://riley-x.github.io/Libra_Sheet/). This naturally doesn't link to any database, but is a nice way to preview the UI.

### Your accounts and net worth at a glance

![Home screen](docs/screen_home.png)

### See where you spend your money

![Categories screen](docs/screen_categories.png)

### And how it changes over time

![Cashflow screen](docs/screen_cashflow.png)

### Or view details for a specific category

![Category focus screen](docs/screen_categoryfocus.png)


## Features

* Fully customizable categories and sub-categories
* Fully customizable transaction tags
* **Input transactions via CSV**
  * Automatic categorizing, but you have to define your own rules
* Reimburse transactions
  * Imagine you paid $60 for dinner with a friend and they Venmo you back $30
  * Your real expense is only $30, and the Venmo transaction shouldn't count as income
* Dark/light theme
* Fully offline; no internet connection used. Everything is saved to a local SQLite file.
