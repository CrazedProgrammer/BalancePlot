import BalancePlot

if length(ARGS) < 2
    println("Usage: balanceplot <config file> <transaction file>")
    exit(1)
end

config = BalancePlot.load_ing_config_from_file(ARGS[1])
trs = BalancePlot.load_ing_transactions_from_file(ARGS[2])
trs2 = BalancePlot.convert_ing_transactions(trs, config)

BalancePlot.plot_transactions(trs2)
