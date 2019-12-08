import JSON

struct INGCategoryMatchers # PCRE regex
    countername::String
    counteraccount::String
    description::String
end

struct INGCategoryMatchRule
    category::String
    matchers::INGCategoryMatchers
end

struct INGConfig
    accountnames::Array{String}
    netignoreaccounts::Array{String}
    categorymatchrules::Array{INGCategoryMatchRule}
end

function parse_ing_config(text::String)::INGConfig
    json = JSON.parse(text)
    return INGConfig(
        json["accountnames"],
        json["netignoreaccounts"],
        map(mr -> INGCategoryMatchRule(
            mr[1],
            INGCategoryMatchers(
                get(mr[2], "countername", ""),
                get(mr[2], "counteraccount", ""),
                get(mr[2], "description", "")
            )
        ), json["categorymatchrules"])
    )
end

function load_ing_config_from_file(path::String)::INGConfig
    open(path, "r") do f
        return parse_ing_config(join(eachline(f), "\n"))
    end
end
