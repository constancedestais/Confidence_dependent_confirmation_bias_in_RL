% Helper function to report missing indices
function reportMissingIndices(cellArray, arrayName)
    if ~isempty(cellArray)
        emptyIndices = find(cellfun(@isempty, cellArray));
        if ~isempty(emptyIndices)
            warning('Missing or failed to load some %s files: indices %s', ...
                arrayName, mat2str(emptyIndices));
        end
    end
end