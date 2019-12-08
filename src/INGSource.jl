import CSV
using Decimals

@enum INGDirection direction_in=1 direction_out=2

struct INGTransaction
    date::Date
    countername::String
    account::String
    counteraccount::String
    code::String
    direction::INGDirection
    amount::Decimal
    type::String
    description::String
end

function load_ing_transactions_from_file(filePath::String)::Array{INGTransaction}
    csvrows = CSV.File(
      filePath,
      skipto=2,
      quotechar='"',
      escapechar='"',
      delim=",",
      header=["date", "countername", "account", "counteraccount",
              "code", "direction", "amount", "type",
              "description"],
      types=Dict("date" => String, "countername" => String, "account" => String,
                 "counteraccount" => String, "direction" => String, "amount" => String,
                 "type" => String, "description" => String))
    transactions = map(row -> INGTransaction(
        Date(parse(Int, row.date[1:4]), parse(Int, row.date[5:6]), parse(Int, row.date[7:8])),
        row.countername,
        row.account,
        coalesce(row.counteraccount, ""),
        row.code,
        if (row.direction == "Debit") direction_out else direction_in end,
        parse(Decimal, replace(row.amount, "," => ".")) * if (row.direction == "Debit") parse(Decimal, "-1.0") else parse(Decimal,"1.0") end,
        row.type,
        row.description
    ), csvrows)

    return if first(transactions).date > last(transactions).date
        reverse(transactions)
    else
        transactions
    end
end

function categorise(tr::INGTransaction, config::INGConfig)::String
    for matchrule in config.categorymatchrules
        if (typeof(match(Regex(matchrule.matchers.countername), tr.countername)) != Nothing
            && typeof(match(Regex(matchrule.matchers.counteraccount), tr.counteraccount)) != Nothing
            && typeof(match(Regex(matchrule.matchers.description), tr.description)) != Nothing)
            return matchrule.category
        end
    end
    error("Couldn't match transaction " * string(tr))
end

function convert_ing_transactions(transactions::Array{INGTransaction}, config::INGConfig)::Array{Transaction}
    balance::Dict{Account, Float64} = Dict(
        account_main => 0.0,
        account_net => 0.0
    )
    for accountname in config.accountnames
        balance[Account(accountname)] = 0.0
    end
    new_transactions::Array{Transaction} = []
    for tr in transactions
        category = categorise(tr, config)
        change::Dict{Account, Float64} = Dict(
            account_main => Float64(tr.amount)
        )
        if category in config.accountnames
            change[Account(category)] = Float64(-tr.amount)
        end
        if category in config.accountnames && !(category in config.netignoreaccounts)
            change[account_net] = 0.0
        else
            change[account_net] = change[account_main]
        end

        new_balance = Dict()
        for account in keys(balance)
            new_balance[account] = balance[account]
        end
        for account in keys(change)
            new_balance[account] = get(new_balance, account, 0) + change[account]
        end
        push!(new_transactions, Transaction(
            tr.date,
            category,
            tr.countername,
            tr.description,
            change,
            new_balance
           ))
        balance = new_balance
    end
    return new_transactions
end
