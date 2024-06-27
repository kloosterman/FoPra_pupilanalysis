%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data/EyEmotion/'; % replace this path with your data path
cd(datapath)

%% preprocessing eye tracking data: reading txt file into memory
% this section loads in the data and does some basic preprocessing. See% https://www.fieldtriptoolbox.org/tutorial/continuous/ for more info

% put filename of the txt files that are in your datapath here, without .txt extension
SUBJ = {'1' '2' '3' '5' '7' '8' '10' '12' '14' '16' '20' '21' '22' '23' '24' '27' '28' '29' '31' '32' '35' '36' '37' '38' '39' };

data = []; timelock_trials=[]; timelock = [];
for isub = 1:length(SUBJ)
  data = read_tobii_txt(fullfile(datapath, 'MATLAB_txt_files', [SUBJ{isub} '_FoPra.txt'])); % read txt files one by one
  % add behav data
  behavfile = dir(fullfile(datapath, 'Verhaltensdaten', [SUBJ{isub} '_*.csv']));
  disp(behavfile)
  behav = readtable(fullfile(behavfile.folder, behavfile.name)); % read txt files one by one
  behav = behav(behav.Trialindex > 0,:);
  for itrial = data.trialinfo.Trialno'
    trlind = find(itrial == behav.Trialindex);
    if isempty(trlind)
      warning ('trial not found');
      continue;
    end
    data.trialinfo.correct(itrial,1) = behav.Antwortcorrect(trlind,1);
    data.trialinfo.rt(itrial,1) = behav.Antwort__rt(trlind,1);
    data.trialinfo.emotion(itrial,1) = behav.Emotion(trlind,1);
    % data.trialinfo.rt = behav.Antwort__rt;
    % data.trialinfo.emotion = behav.Emotion;
  end
  data.trialinfo = data.trialinfo(data.trialinfo.Trialno > 0,:); % drop trials not in behavior

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
cfg.xlim = [0 3];
cfg.channel = 'pupil';
ft_singleplotER(cfg, timelock)
xlabel('Time (s)')
ylabel('Pupil size')
saveas(gcf, 'PupilResponse.png') % save to a figure

%% select 0-0.5 s interval and average within that interval for each subject and for each trial
nbins = 5;
for isub = 1:length(timelock_trials)
  cfg=[];
  cfg.channel = 'pupil';
  cfg.latency = [2 3];
  cfg.avgovertime = 'yes';
  cfg.nanmean = 'yes';
  prestimpupil = ft_selectdata(cfg, timelock_trials{isub});
  timelock_trials{isub}.trialinfo.prestimpupil = prestimpupil.trial;
  cfg = [];
  cfg.trials = not(isnan(timelock_trials{isub}.trialinfo.prestimpupil)) & ... % remove trials without pupil data
    not(isnan(timelock_trials{isub}.trialinfo.rt)); % remove trials without RT data
  timelock_trials{isub} = ft_selectdata(cfg, timelock_trials{isub});

  conds = {'Alltrials' 'Freude' 'Notfreude'};
  for iemo = 1:3
    trialinfo = timelock_trials{isub}.trialinfo;
    if iemo == 2
      trialinfo = trialinfo(trialinfo.emotion == "Freude",:);
    elseif iemo == 3
      trialinfo = trialinfo(not(trialinfo.emotion == "Freude"),:);
    end
    ntrials = size(trialinfo,1);
    trialinfo = sortrows(trialinfo, "prestimpupil");
    [pupilbin, binedges] = discretize(1:ntrials, nbins);
    trialinfo.pupilbin = pupilbin';
    for ibin = 1:nbins
      out_accuracy(isub,ibin) = mean(trialinfo.correct(trialinfo.pupilbin == ibin));
      out_rt(isub,ibin) = mean(trialinfo.rt(trialinfo.pupilbin == ibin));
      writematrix(out_accuracy, ['Accuracy_pupilbinned' conds{iemo}])
    end
  end
end
%% plot
figure; subplot(2,2,1); plot(mean(out_accuracy)); title('Accuracy per bin')
subplot(2,2,2); plot(mean(out_rt)); title('RT per bin')
% prestimpupil.trial now has the single trial values per subject, e.g.
% prestimpupil{1}.trial for the first subject



% cfg=[];
% cfg.keepindividual = 'yes';
% prestimpupil=ft_timelockgrandaverage(cfg, prestimpupil{:}); % timelock has the single subjects

