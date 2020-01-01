# BalancePlot

Bank account balance plotter (graph generator) written in Julia.

Currently only supports ING Bank transaction exports.

# Features

- Generates a time/money graph of the following:
  - The balance of the main and savings accounts.
  - Net worth (sum of main + savings accounts).
  - The monthly income/expenses of transactions grouped by category.
- Exports the graph as HTML for viewing in the browser. This file can be saved
  for later viewing.
- Uses PlotlyJS as the backend. This means easy zooming in/scrolling/filtering
  by category.
- Only uses a provided CSV transaction file. Does not use a network connection.

# How to use

Open the Julia REPL and install the dependencies:
```
$ julia
julia> ]dev .
julia> exit()
```

Run the program with:  
`julia src/Main.jl <path/to/config.json>
<path/to/transactions.csv>`

The resulting HTML file with the graph will be opened in the browser.

# Configuration

Configuration is done via a JSON file (`config.json`). The JSON structure is a
table with the following attributes:

`accountnames` Array of names of savings accounts  
`netignoreaccounts` Array of names of savings accounts that don't count towards
                    the "net worth" account  
`categorymatchrules` Array of category matching rules  
Each category matching rule is an array of two elements. The first element is
the category name. The second element is a table with one or more attributes:
"countername", "counterbalance", or "description". The values of these
attributes are PCRE regexes.

An example configuration would be:
```
{
    "accountnames": [
        "Savings Main",
        "Savings Student Loan"
    ],
    "netignoreaccounts": [
        "Savings Student Loan"
    ],
    "categorymatchrules": [
        ["Savings Main", {
            "countername": "Oranje Spaarrekening ABC123456"
        }],
        ["Savings Student Loan", {
            "countername": "Oranje Spaarrekening DEF789123"
        }],
        ["Salary", {
            "counteraccount": "NL55INGB5555555555",
            "description": "(?i)Salary for month(?-i)"
        }],
        ["Health Insurance", {
            "countername": "ABCDEF Health Insurance",
            "description": "Automatic withdrawal for period"
        }]
    ]
}
```

## Transaction categories

The basic premise of the configuration file is to group the transactions into
categories. The categories are completely customizable.
Common examples would be: salary, student loans, food expenses and health
insurance.

Transactions are grouped into categories by rules. Each one of these rules
contain regex expressions for either the counter account name, counter account
bank number, and/or the description. If all of the given expressions match the
transaction data, the transaction is given the specified category.

## Savings accounts

If the balance of savings accounts are to be displayed, the transactions need
to be matched manually, the same way as with categories. The name of the
category must be the same as the name of the savings account.

# Getting transactions

The list of transactions can be downloaded from the ING Bank online portal.
When logged in, click on the download icon near the balance of the main
account. Select "Comma-separated CSV (English)". It is recommended that
the earliest possible start date is selected, so that the calculated balance
corresponds to the current balance. After that, click on "Download" and
the CSV file is downloaded.

# Limitations

Take the graph data with a grain of salt; always carefully check to see whether
it corresponds before taking conclusions. Bank account names and descriptions
for the same kind of transaction can change anytime when getting a new
transactions file from the bank, which might result in skewed results.

This program does not do more than what is described in this README.

There is no way to specify a starting balance for each account. This means that
the program assumes a balance of zero at the beginning of the transactions. If
an incomplete transaction file is used, a beginning transaction needs to be
added manually for the calculated balance to be correct.

Transactions that occur on the same day might not get sorted in the correct
order. This means that negative balances are possible when they did not happen
in actuality.

Things like window title, axis labels, X- and Y-axis steps cannot be configured
without editing the source code.

There are currently no unit tests, so there is a higher likelyhood of hitting
an untested edge case. This program was written as a script for personal use.
There is a high probability that unit tests will get added in the future.

# Feedback

If you encounter a bug, please file an issue. It would be greatly appreciated.

If you want to add support for another bank, I'll gladly accept pull requests.
Do note that I cannot test whether the implementation is correct, because I do
not have such an account. To remedy this, add an example transaction file that
can be tested against.
Don't put any personal data in this, of course ;)

For other kinds of feature requests, a well-written PR is most likely to
get merged. If you think of a feature that is also valuable to me and file an
issue, that is also likely to get implemented.
