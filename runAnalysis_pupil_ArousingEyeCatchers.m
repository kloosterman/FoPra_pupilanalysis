%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data/ArousingEyecatchers'; % replace this path with your data path
cd(datapath)

%% preprocessing eye tracking data: reading txt file into memory 
% this section loads in the data and does some basic preprocessing. See% https://www.fieldtriptoolbox.org/tutorial/continuous/ for more info

% put filename of the txt files that are in your datapath here, without .txt extension
SUBJ = {'VP01' 'VP02' 'VP03' 'VP04' 'VP05' 'VP07' 'VP08' 'VP11' 'VP12' 'VP13' 'VP14' 'VP15' 'VP16' 'VP17' 'VP18' 'VP20' 'VP23' 'VP25' };

data = []; timelock_trials=[]; timelock = [];
for isub = 1:length(SUBJ)
  data = read_tobii_txt(fullfile(datapath, [SUBJ{isub} '.txt'])); % read txt files one by one
  cfg=[]; cfg.keeptrials = 'yes';
  timelock_trials{end+1} = ft_timelockanalysis(cfg, data); % collect single trials of subjects in timelock_trials

  cfg=[]; cfg.keeptrials = 'no';
  timelock{end+1} = ft_timelockanalysis(cfg, data); % collect average over trials for each subject in timelock
end

cfg=[];
cfg.keepindividual = 'no';
timelock_avg=ft_timelockgrandaverage(cfg, timelock{:}); % timelock_avg has the average over all subjects
cfg=[];
cfg.keepindividual = 'yes';
timelock=ft_timelockgrandaverage(cfg, timelock{:}); % timelock has the single subjects

%% save the processed data to file
save( fullfile(datapath, 'singletrials.mat'), 'timelock_trials')  
save( fullfile(datapath, 'trialaverage.mat'), 'timelock')  
save( fullfile(datapath, 'subjectaverage.mat'), 'timelock_avg')  

%% plot the average over subjects
cfg=[];
cfg.xlim = [0 1.5];
cfg.channel = 'pupil';
ft_singleplotER(cfg, timelock) 
xlabel('Time (s)')
ylabel('Pupil size')
saveas(gcf, 'PupilResponse.png') % save to a figure

%% select 0-0.5 s interval and average within that interval for each subject and for each trial
cfg=[];
cfg.channel = 'pupil';
cfg.latency = [0 0.5];
cfg.avgovertime = 'yes';
prestimpupil = [];
for isub = 1:length(timelock_trials)
  prestimpupil{end+1} = ft_selectdata(cfg, timelock_trials{isub});
end
% prestimpupil.trial now has the single trial values per subject, e.g.
% prestimpupil{1}.trial for the first subject

cfg=[];
cfg.keepindividual = 'yes';
prestimpupil=ft_timelockgrandaverage(cfg, prestimpupil{:}); % timelock has the single subjects

