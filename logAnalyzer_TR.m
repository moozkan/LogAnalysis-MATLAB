clc; clear; close all;

% Log dosyasını oku
logFile = 'Dosya Yolunu Giriniz..'; % Dosya yolunu güncelle
fid = fopen(logFile, 'r');

if fid == -1
    error('Log dosyası açılamadı. Dosya yolunu kontrol edin.');
end

data = textscan(fid, '%s %s %s %s %s %s', 'Delimiter', ' ', 'CollectOutput', true);
fclose(fid);

% Verileri ayrıştır
timestamps = data{1};
users = data{2};
tools = data{3};

timeFormat = 'yyyy-MM-dd HH:mm:ss'; % Varsayılan zaman formatı

% Kullanıcı sürelerini saklamak için bir yapı oluştur
usageData = containers.Map('KeyType', 'char', 'ValueType', 'any');

for i = 1:length(timestamps)
    try
        currentTime = datetime(timestamps{i}, 'InputFormat', timeFormat);
    catch
        warning('Geçersiz zaman formatı: %s', timestamps{i});
        continue;
    end
    
    key = sprintf('%s_%s', users{i}, tools{i});
    
    if isKey(usageData, key)
        usageData(key) = [usageData(key), currentTime];
    else
        usageData(key) = [currentTime];
    end
end

% Kullanım sürelerini hesapla
userUsageSummary = struct();

totalUsage = []; % Görselleştirme için kullanım süreleri saklanacak
userNames = {};  % Kullanıcı isimleri saklanacak

for key = keys(usageData)
    times = sort(usageData(key{1}));
    toplamSure = hesaplaToplamSure(times);
    
    % Kullanıcı ve araç ayrıştırma
    parts = split(key{1}, '_');
    userName = parts{1};
    toolName = parts{2};
    
    fprintf('Kullanıcı: %s, Araç: %s, Toplam Süre: %.2f saat\n', userName, toolName, toplamSure);
    
    if isfield(userUsageSummary, userName)
        userUsageSummary.(userName) = userUsageSummary.(userName) + toplamSure;
    else
        userUsageSummary.(userName) = toplamSure;
    end
    
    totalUsage = [totalUsage, toplamSure];
    userNames = [userNames, userName];
end

% Kullanım sürelerini grafik olarak göster
figure;
bar(categorical(userNames), totalUsage);
title('Kullanıcı Bazında Toplam Kullanım Süreleri');
xlabel('Kullanıcı');
ylabel('Toplam Süre (saat)');
grid on;

% En çok kullanılan araçları ve kullanıcıları listele
[maxUsage, maxIdx] = max(totalUsage);
fprintf('\nEn çok kullanım yapan kullanıcı: %s, %.2f saat\n', userNames{maxIdx}, maxUsage);

% Toplam süre hesaplama fonksiyonu
totalTime = sum(totalUsage);
fprintf('Toplam Kullanım Süresi: %.2f saat\n', totalTime);

function toplamSure = hesaplaToplamSure(times)
    toplamSure = 0;
    if length(times) < 2
        return;
    end
    for i = 2:length(times)
        sure = hours(times(i) - times(i-1));
        toplamSure = toplamSure + sure;
    end
end
