%% test_tracking.m - testa o track_sequence num clip do TrackNet
% Resultados ficam em data/output/tracking (fora do git).
%

%% 0. Caminhos e lista de frames
root = pwd;
assert(isfile(fullfile(root, 'startup.m')), ...
    'Muda a pasta atual do MATLAB para a raiz do repo (piv). Pasta atual: %s', root);
run(fullfile(root, 'startup.m'));               % põe a part1 no path

clip_dir = fullfile(root, 'data', 'trackNet', 'game1', 'Clip1');
out_dir  = fullfile(root, 'data', 'output', 'tracking');
if ~isfolder(out_dir), mkdir(out_dir); end

files = dir(fullfile(clip_dir, '*.jpg'));
assert(~isempty(files), 'Não encontrei .jpg em %s', clip_dir);
[~, ord] = sort({files.name});
files = files(ord);

N_max = 120;                % nº máximo de frames (para ser rápido); Inf = todos
files = files(1:min(N_max, numel(files)));
N = numel(files);
fprintf('%d frames em %s\n', N, clip_dir);

%% 1. Features SIFT no formato do enunciado (kp = 130 x n)
% Provisório: no projeto final isto é feito no main1 (parte do Zé).
% Fica guardado em cache para não repetir a cada teste.
cache = fullfile(out_dir, sprintf('features_%d.mat', N));
if isfile(cache)
    load(cache, 'feats');
    fprintf('Features lidas da cache: %s\n', cache);
else
    feats = cell(1, N);
    for i = 1:N
        G = im2gray(imread(fullfile(clip_dir, files(i).name)));
        pts = detectSIFTFeatures(G);
        [f, vpts] = extractFeatures(G, pts);
        feats{i} = [double(vpts.Location)'; double(f)'];   % 130 x n
        fprintf('frame %3d/%d: %d keypoints\n', i, N, size(feats{i}, 2));
    end
    save(cache, 'feats');
end
feat_ref = feats{1};          % referência = 1º frame (como no enunciado)

%% 2. Tracking (direto à referência, com frame a frame como recurso)
params = struct('it_max', 500, 'limiar_coli', 0.05, 'limiar_inliers', 3, ...
                'nsuf_inliers', Inf, 'min_inliers', 30, 'reanchor_every', 1);
tic;
[H, valid, n_inl, modo] = track_sequence(feats, feat_ref, params);
fprintf(['Tracking: %.1f s | válidos %d/%d | direto à ref: %d | ' ...
         'frame a frame: %d | falhou: %d\n'], ...
        toc, sum(valid), N, sum(modo == 1), sum(modo == 2), sum(modo == 0));

%% 3. Gráfico: inliers por frame e estratégia usada
figure('Name', 'Inliers por frame');
plot(1:N, n_inl, 'k-', 'DisplayName', 'inliers'); hold on;
plot(find(modo == 1), n_inl(modo == 1), 'bo', 'MarkerFaceColor', 'b', ...
     'DisplayName', 'direto à referência');
plot(find(modo == 2), n_inl(modo == 2), 'g.', 'MarkerSize', 14, ...
     'DisplayName', 'frame a frame');
if any(modo == 0)
    plot(find(modo == 0), n_inl(modo == 0), 'rx', 'MarkerSize', 10, ...
         'LineWidth', 2, 'DisplayName', 'falhou');
end
yline(params.min_inliers, 'r--', 'min\_inliers', 'DisplayName', 'min\_inliers');
hold off; grid on;
xlabel('frame'); ylabel('nº de inliers');
legend('Location', 'best');
saveas(gcf, fullfile(out_dir, 'inliers.png'));

%% 4. Verificação visual: frame i deformado para o frame 1
% Cor cinzenta = alinhado; magenta/verde = desalinhado.
Iref  = imread(fullfile(clip_dir, files(1).name));
vista = imref2d([size(Iref, 1) size(Iref, 2)]);
for i = unique([round(N/2), N])
    Ii = imread(fullfile(clip_dir, files(i).name));
    Iw = imwarp(Ii, projtform2d(H(:,:,i) / H(3,3,i)), 'OutputView', vista);
    figure('Name', sprintf('Frame %d -> referência', i));
    imshowpair(Iref, Iw, 'falsecolor');
    title(sprintf('Frame %d deformado para o frame 1 (cinzento = alinhado)', i));
    saveas(gcf, fullfile(out_dir, sprintf('overlay_%04d.png', i)));
end

%% 5. Vídeo estabilizado: original (esq.) | deformado para o frame 1 (dir.)
v = VideoWriter(fullfile(out_dir, 'estabilizado.mp4'), 'MPEG-4');
v.FrameRate = 15;
open(v);
for i = 1:N
    Ii = imread(fullfile(clip_dir, files(i).name));
    Iw = imwarp(Ii, projtform2d(H(:,:,i) / H(3,3,i)), 'OutputView', vista);
    lado = [Ii, Iw];
    if ~valid(i)
        lado = insertText(lado, [20 20], 'FALHOU', 'FontSize', 28, ...
                          'BoxColor', 'red', 'TextColor', 'white');
    end
    writeVideo(v, imresize(lado, 0.5));
end
close(v);
fprintf('Vídeo: %s\n', fullfile(out_dir, 'estabilizado.mp4'));

%% 6. Drift: frame a frame vs direto à referência
% Mesmas features, mas experimentar as duas estratégias. A diferença entre 
% elas em cada frame mostra o erro que frame a frame vai acumulando.

p_ff  = params;  p_ff.reanchor_every  = Inf;   % só frame a frame
p_dir = params;  p_dir.reanchor_every = 1;     % sempre direto à referência
[H_ff,  ~, ~, modo_ff ] = track_sequence(feats, feat_ref, p_ff);
[H_dir, ~, ~, modo_dir] = track_sequence(feats, feat_ref, p_dir);

[gx, gy] = meshgrid(linspace(1, size(Iref, 2), 10), linspace(1, size(Iref, 1), 6));
P = [gx(:)'; gy(:)'; ones(1, numel(gx))];
drift = nan(1, N);
for i = 1:N
    if modo_ff(i) > 0 && modo_dir(i) == 1
        a = H_ff(:,:,i)  * P;  a = a(1:2, :) ./ a(3, :);
        b = H_dir(:,:,i) * P;  b = b(1:2, :) ./ b(3, :);
        drift(i) = mean(vecnorm(a - b));
    end
end
figure('Name', 'Drift');
plot(1:N, drift, '.-'); grid on;
xlabel('frame'); ylabel('diferença média (px)');
title('Frame a frame vs direto à referência (≈ drift acumulado)');
saveas(gcf, fullfile(out_dir, 'drift.png'));
fprintf('Drift no último frame: %.2f px | máximo: %.2f px\n', ...
        drift(find(~isnan(drift), 1, 'last')), max(drift));
