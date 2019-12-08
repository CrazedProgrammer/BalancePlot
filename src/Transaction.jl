import CSV

struct Account
    name::String
end

account_main = Account("Main")
account_net = Account("Net")

struct Transaction
    date::Date
    category::String
    countername::String
    description::String
    change::Dict{Account,Float64}
    balance::Dict{Account,Float64}
end
