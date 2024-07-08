%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data/Auswertung_L(eye)_to_me/'; % replace this path with your data path
cd(datapath)

%% preprocessing eye tracking data: reading txt file into memory
% this section loads in the data and does some basic preprocessing. See% https://www.fieldtriptoolbox.org/tutorial/continuous/ for more info

% put filename of the txt files that are in your datapath here, without .txt extension
% '10' outlier, '12' '14' nans
% SUBJ = {'2' '3' '4' '5' '6' '7' '9'  '12' '14'  '15' '16' '18' '19' '21' '22' '23' '24' '25' '26' }; 
SUBJ = {'2' '3' '4' '5' '6'  '9'  '12' '14'  '15' '16' '18'  '21' '22' '23' '24' '25' '26' }; 
% SUBJ = {'5' };  %'5' has jump '19' '7'

data = []; timelock_trials=[]; timelock = []; timelock_bl = [];
for isub = 1:length(SUBJ)
  data = read_tobii_txt(fullfile(datapath, [SUBJ{isub} '_Pupille.txt'])); % read txt files one by one
  % add behav data
  behavfile = dir(fullfile(datapath, [SUBJ{isub} '_Verhaltensdaten.csv']));
  disp(behavfile)
  behav = readtable(fullfile(behavfile.folder, behavfile.name)); % read txt files one by one
  for itrial = data.trialinfo.Trialno'
    trlind = find(itrial == behav.Trial);
    % trlind = itrial; % assume behav trials 1:100 match 1:100 pupil
    if isempty(trlind)
      warning ('trial not found');
      continue;
    end
    if itrial > size(behav,1)
      warning('Fewer trials in behav than in pupil'); break
    end
    data.trialinfo.salience(itrial,1) = string(behav.Salienz{trlind,1});
    data.trialinfo.lie(itrial,1) = string(behav.Abfrage_Luege{trlind,1});
  end
  data.trialinfo = data.trialinfo(data.trialinfo.Trialno > 0,:); % drop trials not in behavior
  data.time = cellfun(@(x) x - 3, data.time, 'UniformOutput', false); % shift time axis 3 s
  
  % low pass filter to smoothen the data
  cfg=[];
  cfg.lpfilter = 'yes';
  cfg.lpfreq = 1;
  cfg.lpinstabilityfix = 'reduce'; %'split' (default  = 'no')
  data = ft_preprocessing(cfg, data);

  cfg=[]; cfg.keeptrials = 'yes';
  timelock_trials{end+1} = ft_timelockanalysis(cfg, data); % collect single trials of subjects in timelock_trials

  cfg=[]; cfg.keeptrials = 'no';
  timelock{end+1} = ft_timelockanalysis(cfg, data); % collect average over trials for each subject in timelock
  
  % cfg=[];
  % cfg.baseline = [-2 0];  
  % timelock{end} = ft_timelockbaseline(cfg, timelock{end});
end

cfg=[];
cfg.keepindividual = 'no';
cfg.tolerance = 0.01;
timelock_avg = ft_timelockgrandaverage(cfg, timelock{:}); % timelock_avg has the average over all subjects

cfg.keepindividual = 'yes';
timelock=ft_timelockgrandaverage(cfg, timelock{:}); % timelock has the single subjects

%% save the processed data to file
save( fullfile(datapath, 'singletrials.mat'), 'timelock_trials')
save( fullfile(datapath, 'trialaverage.mat'), 'timelock')
save( fullfile(datapath, 'subjectaverage.mat'), 'timelock_avg')

%% plot the average over subjects
cfg=[];
cfg.xlim = [-3 10];
cfg.channel = 'pupil';
ft_singleplotER(cfg, timelock)
xlabel('Time (s)')
ylabel('Pupil size')
saveas(gcf, 'PupilResponse.png') % save to a figure

%% average trials for each condition
% sal = {'n' 's'}; % nonsalient salient
% lie = {'j' 'f'}; % truth lie
timelock_nonsal_truth = {}; timelock_nonsal_lie = {}; timelock_sal_truth = {}; timelock_sal_lie = {};
for isub = 1:length(timelock_trials)
  cfg=[];
  cfg.avgoverrpt  = 'yes';
  cfg.nanmean  = 'yes';

  cfg.trials = timelock_trials{isub}.trialinfo.salience == "n" & timelock_trials{isub}.trialinfo.lie  == "j";
  timelock_nonsal_truth{isub} = ft_timelockanalysis(cfg, timelock_trials{isub});

  cfg.trials = timelock_trials{isub}.trialinfo.salience == "n" & timelock_trials{isub}.trialinfo.lie  == "f";
  timelock_nonsal_lie{isub} = ft_timelockanalysis(cfg, timelock_trials{isub});

  cfg.trials = timelock_trials{isub}.trialinfo.salience == "s" & timelock_trials{isub}.trialinfo.lie  == "j";
  timelock_sal_truth{isub} = ft_timelockanalysis(cfg, timelock_trials{isub});

  cfg.trials = timelock_trials{isub}.trialinfo.salience == "s" & timelock_trials{isub}.trialinfo.lie  == "f";
  timelock_sal_lie{isub} = ft_timelockanalysis(cfg, timelock_trials{isub});
  %baseline correction
end
cfg=[];
cfg.keepindividual = 'yes';
cfg.tolerance = 0.01;
timelock_nonsal_truth=ft_timelockgrandaverage(cfg, timelock_nonsal_truth{:}); % timelock has the single subjects
timelock_nonsal_lie=ft_timelockgrandaverage(cfg, timelock_nonsal_lie{:}); % timelock has the single subjects
timelock_sal_truth=ft_timelockgrandaverage(cfg, timelock_sal_truth{:}); % timelock has the single subjects
timelock_sal_lie=ft_timelockgrandaverage(cfg, timelock_sal_lie{:}); % timelock has the single subjects

% cfg=[];
% cfg.baseline = [-2 0];
% timelock_nonsal_truth = ft_timelockbaseline(cfg, timelock_nonsal_truth);
% timelock_nonsal_lie = ft_timelockbaseline(cfg, timelock_nonsal_lie);
% timelock_sal_truth = ft_timelockbaseline(cfg, timelock_sal_truth);
% timelock_sal_lie = ft_timelockbaseline(cfg, timelock_sal_lie);
% 
%% average 4-8 s and export table
latencies = [1 4; 4 8];
for ilat = 1:length(latencies)
  cfg=[];
  cfg.avgovertime = 'yes';
  cfg.nanmean = 'yes';
  cfg.latency = latencies(ilat,:);
  cfg.channel = 'pupil';
  timelock_nonsal_truth_sel=ft_selectdata(cfg, timelock_nonsal_truth); % timelock has the single subjects
  timelock_nonsal_lie_sel=ft_selectdata(cfg, timelock_nonsal_lie); % timelock has the single subjects
  timelock_sal_truth_sel=ft_selectdata(cfg, timelock_sal_truth); % timelock has the single subjects
  timelock_sal_lie_sel=ft_selectdata(cfg, timelock_sal_lie); % timelock has the single subjects

  t = table(string(SUBJ'), timelock_nonsal_truth_sel.individual, timelock_nonsal_lie_sel.individual, ...
    timelock_sal_truth_sel.individual, timelock_sal_lie_sel.individual, ...
    'VariableNames', {'subject#', 'nonsal_truth', 'nonsal_lie', 'sal_truth', 'sal_lie'});
  writetable(t, sprintf('Pupil_conditions_%d-%ds', cfg.latency))
end
%% export table with time courses
cfg=[];
cfg.channel = 'pupil';
timelock_nonsal_truth_sel=ft_timelockanalysis(cfg, timelock_nonsal_truth); % timelock has the single subjects
timelock_nonsal_lie_sel=ft_timelockanalysis(cfg, timelock_nonsal_lie); % timelock has the single subjects
timelock_sal_truth_sel=ft_timelockanalysis(cfg, timelock_sal_truth); % timelock has the single subjects
timelock_sal_lie_sel=ft_timelockanalysis(cfg, timelock_sal_lie); % timelock has the single subjects

t = table(timelock_nonsal_truth_sel.time', timelock_nonsal_truth_sel.avg', timelock_nonsal_lie_sel.avg', ...
  timelock_sal_truth_sel.avg', timelock_sal_lie_sel.avg', ...
  'VariableNames', {'time', 'nonsal_truth', 'nonsal_lie', 'sal_truth', 'sal_lie'});
writetable(t, sprintf('Pupil_avg_timecourses'))

%% baseline correct with mean for each subject
% cfg=[];
% cfg.latency = [0 3];
% cfg.avgovertime = 'yes';
% baseline = ft_selectdata(cfg, timelock);
% cfg=[];
% cfg.operation = '(x1-x2)./x2*100';
% cfg.parameter = 'individual';
% timelock_nonsal_truth = ft_math(cfg, timelock_nonsal_truth, baseline);
% timelock_nonsal_lie = ft_math(cfg, timelock_nonsal_lie, baseline);
% timelock_sal_truth = ft_math(cfg, timelock_sal_truth, baseline);
% timelock_nonsal_truth = ft_math(cfg, timelock_nonsal_truth, baseline);
%% plot the average over subjects for each cond
cfg=[];
% cfg.xlim = [0 3];
cfg.xlim = [-3 10];
cfg.linewidth = 2;
cfg.channel = 'pupil';
ft_singleplotER(cfg, timelock_nonsal_lie, timelock_nonsal_truth, timelock_sal_lie, timelock_sal_truth)
xlabel('Time (s)'); ylabel('Pupil size'); xline(0)
leg = {'nonsal lie', 'nonsal truth', 'sal lie', 'sal truth'};
legend(leg)
saveas(gcf, 'PupilResponse.png') % save to a figure
saveas(gcf, 'PupilResponse.pdf') % save to a figure

%% plot ohne ft
figure; plot(t.time, [t.nonsal_lie t.nonsal_truth, t.sal_lie, t.sal_truth])
[t.nonsal_lie t.nonsal_truth, t.sal_lie, t.sal_truth]

%% plot with SEM
ydat = [squeeze(timelock_nonsal_lie.individual(:,3,:)) squeeze(timelock_nonsal_lie.individual(:,3,:))]
figure;
ft_plot_vector(timelock_nonsal_lie.time, ydat)
