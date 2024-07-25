%% Example script for pupil analysis
restoredefaultpath; clear; % this clears the path
addpath('/Users/kloosterman/Documents/MATLAB/fieldtrip-20240603') % add fieldtrip to path, download from https://download.fieldtriptoolbox.org/
ft_defaults % this sets up fieldtrip toolbox for use, see https://www.fieldtriptoolbox.org/faq/installation/
addpath('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/FoPra_pupilanalysis') % the read_tobii_txt should be in this path

datapath = '/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data/ArousingEyecatchers/eye'; % replace this path with your data path
cd(datapath)

%% preprocessing eye tracking data: reading txt file into memory 
% this section loads in the data and does some basic preprocessing. See% https://www.fieldtriptoolbox.org/tutorial/continuous/ for more info

% % put filename of the txt files that are in your datapath here, without .txt extension
% SUBJ = { 'VP03'  'VP05' 'VP07' 'VP08' 'VP11' 'VP12' 'VP13' 'VP14' 'VP15' 'VP16' 'VP17' 'VP20' 'VP23' 'VP25' };
% % 'VP02' huge pupil vals   'VP18' also big pupil vals   'VP01' below chance
% % 'VP04' hitrate 0 in bin 1

SUBJ = [ 3 5 7 8 11 12 13 14 15 16 17 20 23 25 ];


pers = readtable('/Users/kloosterman/Library/CloudStorage/Dropbox/PROJECTS/Teaching/23-24SS/FoPra_pupil/data/ArousingEyecatchers/Extraversion + Acc.xlsx');
pers = pers(SUBJ,:)
data = []; timelock_trials=[]; timelock = [];
for isub = 1:length(SUBJ)
  if SUBJ(isub) < 10
    data = read_tobii_txt(fullfile(datapath, sprintf('VP0%d.txt', SUBJ(isub)))); % read txt files one by one
    behavfile = dir(fullfile(datapath, sprintf('Processed_Acc_VP0%d.csv', SUBJ(isub))));
  else
    data = read_tobii_txt(fullfile(datapath, sprintf('VP%d.txt', SUBJ(isub)))); % read txt files one by one
    behavfile = dir(fullfile(datapath, sprintf('Processed_Acc_VP%d.csv', SUBJ(isub))));
  end
  % todo read in extra-version score and performance
  disp(behavfile)
  behav = readtable(fullfile(behavfile.folder, behavfile.name)); % read txt files one by one
  behav = behav(behav.TRIAL_INDEX > 0,:);
  for itrial = 1:length(data.trialinfo.Trialno)
    trlind = find(data.trialinfo.Trialno(itrial) == behav.TRIAL_INDEX);
    if isempty(trlind)
      warning ('trial not found');
      continue;
    end
    data.trialinfo.correct(itrial,1) = behav.Treffer(trlind,1);
    data.trialinfo.H(itrial,1) = behav.H(trlind,1);
    data.trialinfo.M(itrial,1) = behav.M(trlind,1);
    data.trialinfo.CR(itrial,1) = behav.CR(trlind,1);
    data.trialinfo.FA(itrial,1) = behav.FA(trlind,1);
    data.trialinfo.targetpresent(itrial,1) = behav.H(trlind,1)+behav.FA(trlind,1);
    data.trialinfo.targetabsent(itrial,1) = behav.FA(trlind,1)+behav.CR(trlind,1);    
  end
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
% cfg.xlim = [0 1.5];
cfg.channel = 'pupil';
ft_singleplotER(cfg, timelock) 
xlabel('Time (s)')
ylabel('Pupil size')
saveas(gcf, 'PupilResponse.png') % save to a figure

%% Bin accuracy based on pupil
nbins = 5;
% conds = {'Alltrials' 'Freude' 'Notfreude'};
conds = {'Alltrials' };
out_accuracy=[]; out_dprime=[]; out_pupilperbin = [];
for icond = 1%:3
  for isub = 1:length(timelock_trials)
    cfg=[];
    cfg.channel = 'pupil';
    % cfg.latency = [0 0.5];
    cfg.latency = [0 0.5];
    cfg.avgovertime = 'yes';
    cfg.nanmean = 'yes';
    prestimpupil = ft_selectdata(cfg, timelock_trials{isub});
    timelock_trials{isub}.trialinfo.prestimpupil = prestimpupil.trial;
    cfg = [];
    cfg.trials = not(isnan(timelock_trials{isub}.trialinfo.prestimpupil)); %& ... % remove trials without pupil data
      % not(isnan(timelock_trials{isub}.trialinfo.rt)); % remove trials without RT data
    timelock_trials{isub} = ft_selectdata(cfg, timelock_trials{isub});

    trialinfo = timelock_trials{isub}.trialinfo;
    % if icond == 2
    %   trialinfo = trialinfo(trialinfo.emotion == "Freude",:);
    % elseif icond == 3
    %   trialinfo = trialinfo(not(trialinfo.emotion == "Freude"),:);
    % end
    ntrials = size(trialinfo,1);
    trialinfo = sortrows(trialinfo, "prestimpupil");
    [pupilbin, binedges] = discretize(1:ntrials, nbins);
    trialinfo.pupilbin = pupilbin';
    for ibin = 1:nbins
      out_accuracy(isub,ibin) = mean(trialinfo.correct(trialinfo.pupilbin == ibin));
      curtrl = trialinfo(trialinfo.pupilbin == ibin,:);
      
      Hitrate = sum(curtrl.H)/sum(curtrl.targetpresent);
      if Hitrate == 1; Hitrate = 0.95; end
      FArate = sum(curtrl.FA)/sum(curtrl.targetabsent);
      if FArate == 0; FArate = 0.05; end

      out_dprime(isub,ibin) = norminv(Hitrate) - norminv(FArate);

      out_pupilperbin(isub,ibin) = mean(trialinfo.prestimpupil(trialinfo.pupilbin == ibin)); 
    end
  end
  t = table(string(SUBJ'), out_accuracy, out_dprime, out_pupilperbin, ...
    'VariableNames', {'subject#', 'accuracy', 'dprime', 'Pupil size'});
  t = [t pers];
  t = sortrows(t, 'Extraversion');
  extrabin = discretize(1:size(t,1), 2)';
  t.Extraversionbin = extrabin;
  writetable(t, sprintf('Pupil_binned_%s', conds{icond}))
end

%% plot average accuracy across bins
% figure; hold on
% % plot(t.("Pupil size"), t.("accuracy"))
% plot(mean(t.("Pupil size")), mean(t.("dprime")))
f=figure; hold on; f.Position=   [476   540   311   240];
clear s
t1 = t(t.Extraversionbin == 1,:);
t2 = t(t.Extraversionbin == 2,:);
s(1) = scatter(mean(t1.("Pupil size")), mean(t1.("dprime")), 'blue', 'filled');
ft_plot_vector(mean(t1.("Pupil size")), mean(t1.("dprime")), 'color', 'blue')
SEMx =  [mean(t1.("Pupil size")) ...
  fliplr(mean(t1.("Pupil size")))]';
SEMy =  [mean(t1.("dprime")) + std(t1.("dprime"))/sqrt(size(t1,1)) ...
  fliplr(mean(t1.("dprime")) - std(t1.("dprime"))/sqrt(size(t1,1)))]';
ft_plot_patch(SEMx, SEMy, 'facecolor', 'blue', 'facealpha', 0.25)

s(2) = scatter(mean(t2.("Pupil size")), mean(t2.("dprime")), 'red', 'filled');

ft_plot_vector(mean(t2.("Pupil size")), mean(t2.("dprime")), 'color', 'red')
SEMx =  [mean(t2.("Pupil size")) ...
  fliplr(mean(t2.("Pupil size")))]';
SEMy =  [mean(t2.("dprime")) + std(t2.("dprime"))/sqrt(size(t2,1)) ...
  fliplr(mean(t2.("dprime")) - std(t2.("dprime"))/sqrt(size(t2,1)))]';
ft_plot_patch(SEMx, SEMy, 'facecolor', 'red', 'facealpha', 0.25)

xlabel('Pupil size (Tobii units)')
ylabel('SDT dprime')
legend(s, {'Introverts' 'Extraverts'}); legend boxoff
saveas(gcf, 'Extraversion_pupil.pdf')
saveas(gcf, 'Extraversion_pupil.png')


% %% select 0-0.5 s interval and average within that interval for each subject and for each trial
% cfg=[];
% cfg.channel = 'pupil';
% cfg.latency = [0 0.5];
% cfg.avgovertime = 'yes';
% prestimpupil = [];
% for isub = 1:length(timelock_trials)
%   prestimpupil{end+1} = ft_selectdata(cfg, timelock_trials{isub});
% end
% % prestimpupil.trial now has the single trial values per subject, e.g.
% % prestimpupil{1}.trial for the first subject
% 
% cfg=[];
% cfg.keepindividual = 'yes';
% prestimpupil=ft_timelockgrandaverage(cfg, prestimpupil{:}); % timelock has the single subjects
