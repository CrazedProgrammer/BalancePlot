module BalancePlot

export load_ing_config_from_file, load_ing_transactions_from_file, convert_ing_transactions, plot_transactions

import Dates.Date
import Dates
import Base.<
using Plots

include("Transaction.jl")
include("INGConfig.jl")
include("INGSource.jl")

struct DateMonth
    year::Int
    month::Int
end

function date_to_datemonth(date::Date)
    return DateMonth(Dates.year(date), Dates.month(date))
end

function datemonth_to_date(datemonth::DateMonth, day::Int=15)
    return Date(datemonth.year, datemonth.month, day)
end

function inc_month(datemonth::DateMonth)
    if datemonth.month > 11
        return DateMonth(datemonth.year + 1, 1)
    else
        return DateMonth(datemonth.year, datemonth.month + 1)
    end
end

Base.:<(a::DateMonth, b::DateMonth) =
    if a.year == b.year
        a.month < b.month
    else
        a.year < b.year
    end
Base.isless(a::DateMonth, b::DateMonth) = a < b

function inbetween_months_from_dates(dates::Array{Date})::Array{DateMonth}
    minDate = Date(2050)
    maxDate = Date(1970)
    for date in dates
        if date < minDate
            minDate = date
        end
        if date > maxDate
            maxDate = date
        end
    end
    months = [date_to_datemonth(minDate)]
    if minDate != maxDate
        while last(months) < date_to_datemonth(maxDate)
            push!(months, inc_month(last(months)))
        end
    end
    return months
end

function inbetween_value_from_values(values::Array{Float64}, increment::Float64)::Array{Float64}
    minValue = minimum(values)
    maxValue = maximum(values)
    minValueRounded = minValue - minValue % increment
    maxValueRounded = maxValue - maxValue % increment
    return minValueRounded:increment:maxValueRounded
end

function get_category_sum_per_month(transactions::Array{Transaction})::Dict{String, Dict{DateMonth, Float64}}
    accountnames = map(account -> account.name, collect(keys(first(transactions).balance)))
    categories::Array{String} = []
    for transaction in transactions
        if !(transaction.category in categories) && !(transaction.category in accountnames)
            push!(categories, transaction.category)
        end
    end
    months = inbetween_months_from_dates(map(tr -> tr.date, transactions))
    result::Dict{String, Dict{DateMonth, Float64}} = Dict()
    for category in categories
        result[category] = Dict()
        for month in months
            result[category][month] = 0
        end
    end

    for transaction in transactions
        if !(transaction.category in accountnames)
            datemonth = date_to_datemonth(transaction.date)
            result[transaction.category][datemonth] += transaction.change[account_main]
        end
    end

    return result
end

function plot_transactions(transactions::Array{Transaction})
    accounts = collect(keys(first(transactions).balance))
    category_sums_per_month = get_category_sum_per_month(transactions)
    dates = map(transaction -> transaction.date, transactions)
    balances_dates = repeat([dates], length(accounts))
    balances = map(account ->
        map(transaction -> transaction.balance[account], transactions)
    , accounts)
    labels = map(account -> account.name, accounts)

    for category in keys(category_sums_per_month)
        sums::Array{Pair{DateMonth, Float64}} = []
        for month in sort(collect(keys(category_sums_per_month[category])))
            push!(sums, Pair(month, category_sums_per_month[category][month]))
        end

        push!(balances_dates, map(pair -> datemonth_to_date(pair.first), sums))
        push!(balances, map(pair -> pair.second, sums))
        push!(labels, category)
    end

    xlabel = "Date"
    ylabel = "Amount (€)"
    xticks = map(month -> Dates.value.(datemonth_to_date(month, 1)),
                 inbetween_months_from_dates(map(tr -> tr.date, transactions)))
    yticks = inbetween_value_from_values(collect(Iterators.flatten(balances)), 250.0)

    plotly()
    plot(xlabel=xlabel, ylabel=ylabel, xticks=xticks, yticks=yticks, window_title="BalancePlot.jl", size=[1800, 1000])
    map(function(data)
            plot!(data[2], data[1], label=data[3])
        end,
        zip(balances, balances_dates, labels))
    gui()
end

end
