function fullFilePath = save_file_with_increment(basePath, baseFilename, extension)
    % create name to save file with automatic numbering
    % first check if this name exists in said directory, if so, add an increment at the end of the file name (e.g. _2 _3 etc)

    % Ensure extension starts with a dot
    if ~startsWith(extension, '.')
        extension = ['.' extension];
    end
    
    % Start with the original filename
    filename = baseFilename;
    counter = 1;
    
    % Build the full path to the file, starting with counter = 1
    fullFilePath = fullfile(basePath,  filename+string(counter)+extension);
    
    % Keep checking if the file exists, incrementing the counter if needed
    while exist(fullFilePath, 'file')
        counter = counter + 1;
        % update fullFilePath accordingly
        fullFilePath = fullfile(basePath,  filename+string(counter)+extension);
    end

    % Now fullFilePath contains a non-existing file path
    % You can use it to save your file
   
end

