classdef fileList
    properties
        fileNames (1,:) cell
        path (1,:) cell
        plainFileNames (1,:) cell
        ext (1,:) cell
        filtExt (1,:) cell = {'*'}
    end
    methods
        function obj = fileList(fileNames,possibleExtensions)
            if nargin == 2
                obj.filtExt = possibleExtensions;
            end
            if nargin ~= 0
                assert(iscellstr(fileNames),'Input cell has to be [1 x N] cell of "chars" containing filenames!');
                existFlags = fileList.checkExistence(fileNames);
                if all(existFlags)
                    for i = 1:numel(fileNames)
                        [folderPath, plainFilename, ext] = fileparts(fileNames{i});
                        folderPath = fullpath(folderPath);
                        if fileList.checkExtension([plainFilename, ext],obj.filtExt)
                            obj.fileNames{i} = fullfile(folderPath,[plainFilename, ext]);
                            obj.path{i} = folderPath;
                            obj.plainFileNames{i} = plainFilename;
                            obj.ext{i} = ext;
                        else
                            warning('Input file "%s" does not have required extension and will not be listed!',[plainFilename, ext])
                        end
                    end
                else
                    nonExistingFiles = fileNames(~existFlags);
                    error('File "%s" does not exist, not possible to create fileList object!',nonExistingFiles{1});
                end
            end
        end
    end
    methods (Static)
        function fileExistFlag = checkExistence(flist)
            assert(iscellstr(flist),'Input cell has to be [1 x N] cell of "chars" containing filenames!');
            fileExistFlag = false(1,numel(flist));
            for i = 1:numel(flist)
                if exist(flist{i},'file') == 2
                    fileExistFlag(i) = true;
                end
            end
        end
        function checkFilenames(fileNameCell)
            for i = 1:numel(fileNameCell)
                if nnz(fileNameCell{i} == '.') ~= 1
                    warning('Unusual number of Input filename "%s" contains several "." chars.',fileNameCell{i});
                end
            end
        end
        function ok = checkExtension(fileName,extensions)
            validateattributes(fileName,{'char'},{'size',[1,NaN]},1);
            validateattributes(extensions,{'cell'},{'size',[1,NaN]},2);
            ok = false;
            [~,~,fe] = fileparts(fileName);
            if numel(extensions) == 1
               if strcmp(extensions{1},'.*') || strcmp(extensions{1},'*')
                    ok = true;
                    return
               end
               if strcmp(fe(2:end),extensions{1})
                    ok = true;
                    return
               end
            else
                if ismember(fe(2:end),extensions)
                    ok = true;
                end
            end
         end
    end
end