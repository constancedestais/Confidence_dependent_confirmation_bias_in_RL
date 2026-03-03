%% Setup workspace/directories/paths 

clear all
close all
clc
format longg

% set directories
filePath = mfilename('fullpath') ; %filePath = matlab.desktop.editor.getActiveFilename;
cwd = fileparts(filePath);
    fprintf('cwd = %s\n',cwd);
cd(cwd);
output_dir  = fullfile(cwd,'Outputs');
data_dir    = fullfile(cwd,'Data');
figures_dir = fullfile(output_dir,'Figures');

% set path
restoredefaultpath
addpath(genpath('Functions'), genpath('Data'), genpath('Outputs'))  % add folder and contained folders
addpath(genpath('../MBB-team_VBA-toolbox')); % add folder and contained folders
