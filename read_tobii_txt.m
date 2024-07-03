function [data] = read_tobii_txt(inputfile)
% This function reads in the txt files from your Python experiment and
% converts it into the FieldTrip 'raw' format (see https://github.com/fieldtrip/fieldtrip/blob/master/utilities/ft_datatype_raw.m).
% Once converted, we can plug the data into other FieldTrip functions.

% read the txt file into memory
t = readtable(inputfile); 

% Prepare the ft data struct
data = [];
% data.label = [t.Properties.VariableNames 'pupil'];
% data.label = {'TRIAL_INDEX', 'time', 'gaze_x', 'gaze_y', 'pupil'}; % 5 chans
data.label = {'TRIAL_INDEX'; 'time'; 'pupil'}; % 3 chans
data.trial = {};
data.time = {};
data.fsample = 40; % 120 Hz, pupil sampled every 3rd sample, so effectively 40 Hz
data.trialinfo = [];
time = 0:1/data.fsample:100; % 100 s time axis, used for making single trial time axes

trial_inds = unique(t.TRIAL_INDEX);
% go through all the trials and put them in data
for itrial = trial_inds'
  curtrl = t(t.TRIAL_INDEX == itrial,:);
  smp = not(ismissing(curtrl.left_pupil_measure1)) | not(ismissing(curtrl.right_pupil_measure1)); % only keep samples with pupil measurement
  curtrl = curtrl(smp,:);
  if isempty(curtrl);    continue;  end
  % curtrl.gaze_x = nanmean([curtrl.left_pupil_measure1 curtrl.right_pupil_measure1],2); % good idea if one chan has bad data?  
  % curtrl.gaze_y = nanmean([curtrl.left_pupil_measure1 curtrl.right_pupil_measure1],2); % good idea if one chan has bad data?  
  curtrl.pupil = nanmean([curtrl.left_pupil_measure1 curtrl.right_pupil_measure1],2); % good idea if one chan has bad data?  
  if any(ismissing(curtrl.pupil(1,:)))
    curtrl.pupil(1,:) = nanmean(head(curtrl.pupil, 20)); % to avoid a nan at the start
  end
  if any(ismissing(curtrl(end,:)))
    curtrl.pupil(end,:) = nanmean(tail(curtrl.pupil, 20)); % to avoid a nan at the end
  end
  data.trial{end+1} = [curtrl.TRIAL_INDEX curtrl.time curtrl.pupil]';  
  data.time{end+1} = time(1:length(data.trial{end}));
  data.trialinfo(end+1,1) = curtrl.TRIAL_INDEX(1,:);
end

% only keep trials with more samples than channels
nchan = numel(data.label);
validtrials = cellfun(@(x) size(x,2) > nchan, data.trial);
data.trial = data.trial(validtrials);
data.time = data.time(validtrials);
data.trialinfo = data.trialinfo(validtrials);

if isempty(data.trial)
  return
end
% check if fieldtrip approves the data and add sampleinfo
data = ft_checkdata(data, 'datatype', {'raw'}, 'feedback', 'yes', 'hassampleinfo', 'yes');

% Artifact rejection: interpolate blinks and spikes
movement = [];
for itrial = 1:length(data.trial)
  pkdat = data.trial{itrial}(3,:); 
  pkdat = abs(pkdat-mean(pkdat));
  [~,peakinds,peakwidth,proms] = findpeaks(pkdat); 
  pkthresh = 0.15;
  peakinds = peakinds(proms>pkthresh)';
  peakwidth = peakwidth(proms>pkthresh)';
  begtrl = round(peakinds-(peakwidth));
  endtrl = round(peakinds+(peakwidth));
  trlsmp = data.sampleinfo(itrial,1):data.sampleinfo(itrial,2);
  begtrl(begtrl<2) = 2;
  endtrl(endtrl>=length(trlsmp)) = length(trlsmp)-1;  
  begsample = trlsmp(1, begtrl)'; 
  endsample = trlsmp(1, endtrl)'; 
  movement = [movement; [begsample endsample]];
end

% plot the artifacts in databrowser
% cfg = [];
% cfg.artfctdef.blinks.artifact = movement(:,1:2);
% cfg.channel =  'right_pupil_measure1';
% cfg.demean = 'yes'; % this makes the data zero-centered 
% cfg = ft_databrowser(cfg, data); 

% replace the artifacts with nans
cfg=[];
cfg.artfctdef.reject = 'nan';
cfg.artfctdef.jumps.artifact = movement;
data = ft_rejectartifact(cfg, data);

% linear interpolation of nan timepoints
cfg=[];
cfg.prewindow = 1./data.fsample;
cfg.postwindow = 1./data.fsample;
data = ft_interpolatenan(cfg, data); % what if a channel only has nans?

data.trialinfo = table(data.trialinfo, 'VariableNames', {'Trialno'});

% plotting again
% cfg = [];
% cfg.artfctdef.blinks.artifact = movement(:,1:2);
% cfg.channel =  'pupil';
% cfg.demean = 'yes'; % this makes the data zero-centered 
% cfg = ft_databrowser(cfg, data); 

