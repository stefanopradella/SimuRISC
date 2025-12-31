function lookupResult = lutLookup(table, value)
    lookupResult = table(table(:, 1) == value, 2);
end