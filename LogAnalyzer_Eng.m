clc; clear; close all;

% Read the log file
logFile = 'Enter file path here'; % Update the file path
fid = fopen(logFile, 'r');

if fid == -1
    error('Unable to open the log file. Check the file path.');
end

data = textscan(fid, '%s %s %s %s %s %s', 'Delimiter', ' ', 'CollectOutput', true);
fclose(fid);

% Parse the data
timestamps = data{1};
users = data{2};
tools = data{3};

timeFormat = 'yyyy-MM-dd HH:mm:ss'; % Default time format

% Create a structure to store user usage times
usageData = containers.Map('KeyType', 'char', 'ValueType', 'any');

for i = 1:length(timestamps)
    try
        currentTime = datetime(timestamps{i}, 'InputFormat', timeFormat);
    catch
        warning('Invalid time format: %s', timestamps{i});
        continue;
    end
    
    key = sprintf('%s_%s', users{i}, tools{i});
    
    if isKey(usageData, key)
        usageData(key) = [usageData(key), currentTime];
    else
        usageData(key) = [currentTime];
    end
end

% Calculate usage times
userUsageSummary = struct();

totalUsage = []; % Store usage times for visualization
userNames = {};  % Store user names

for key = keys(usageData)
    times = sort(usageData(key{1}));
    totalDuration = calculateTotalUsageTime(times);
    
    % Extract user and tool
    parts = split(key{1}, '_');
    userName = parts{1};
    toolName = parts{2};
    
    fprintf('User: %s, Tool: %s, Total Duration: %.2f hours\n', userName, toolName, totalDuration);
    
    if isfield(userUsageSummary, userName)
        userUsageSummary.(userName) = userUsageSummary.(userName) + totalDuration;
    else
        userUsageSummary.(userName) = totalDuration;
    end
    
    totalUsage = [totalUsage, totalDuration];
    userNames = [userNames, userName];
end

% Display usage times as a bar chart
figure;
bar(categorical(userNames), totalUsage);
title('Total Usage Time per User');
xlabel('User');
ylabel('Total Duration (hours)');
grid on;

% List the most used tools and users
[maxUsage, maxIdx] = max(totalUsage);
fprintf('\nMost active user: %s, %.2f hours\n', userNames{maxIdx}, maxUsage);

% Calculate total usage time
totalTime = sum(totalUsage);
fprintf('Total Usage Time: %.2f hours\n', totalTime);

function totalDuration = calculateTotalUsageTime(times)
    totalDuration = 0;
    if length(times) < 2
        return;
    end
    for i = 2:length(times)
        duration = hours(times(i) - times(i-1));
        totalDuration = totalDuration + duration;
    end
end
