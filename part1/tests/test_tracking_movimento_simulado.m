%% test_tracking_movimento_simulado.m - tracking com movimento de câmara
% O Clip1 do TrackNet tem a câmara parada. Aqui a câmara faz pan e zoom 
% sobre os frames reais: cada frame simulado é uma janela do
% frame original, que se desloca e encolhe ao longo do tempo, para simular 
% uma câmara não estática.
% Como o movimento é conhecido, sabemos a homografia verdadeira de cada
% frame para o frame 1 e podemos medir o erro (em píxeis) de cada estratégia
% em relação ao esperado.
%

%% 0. Caminhos e lista de frames
root = pwd;
assert(isfile(fullfile(root, 'startup.m')), ...
    'Muda a pasta atual do MATLAB para a raiz do repo (piv). Pasta atual: %s', root);
run(fullfile(root, 'startup.m'));

clip_dir   = fullfile(root, 'data', 'trackNet', 'game1', 'Clip1');
out_dir    = fullfile(root, 'data', 'output', 'movimento_simulado');
frames_dir = fullfile(out_dir, 'frames');
if ~isfolder(frames_dir), mkdir(frames_dir); end

files = dir(fullfile(clip_dir, '*.jpg'));
assert(~isempty(files), 'Não encontrei .jpg em %s', clip_dir);
[~, ord] = sort({files.name});
files = files(ord);
N = min(120, numel(files));
files = files(1:N);

I1 = imread(fullfile(clip_dir, files(1).name));
[Hh, W, ~] = size(I1);
vista = imref2d([Hh W]);

%% 1. Câmara virtual: janela que faz zoom-in e pan (vai e volta)
% largura da janela: 85% -> 60% da imagem (zoom de ~1.4x no fim)
% centro: pan horizontal de +-6% da largura, pequeno movimento vertical
t       = linspace(0, 1, N);
largura = W * (0.85 - 0.25 * (1 - cos(pi * t)) / 2);
altura  = largura * Hh / W;
cx      = W/2  + 0.06 * W  * sin(2 * pi * t);
cy      = Hh/2 + 0.03 * Hh * sin(4 * pi * t);

% G(:,:,i) leva píxeis do frame ORIGINAL para o frame SIMULADO i
% (recorta a janela e estica-a para o tamanho da imagem)
G = zeros(3, 3, N);
for i = 1:N
    s = W / largura(i);
    G(:,:,i) = [s 0 -s * (cx(i) - largura(i) / 2);
                0 s -s * (cy(i) - altura(i)  / 2);
                0 0 1];
end

% Homografia verdadeira: frame simulado i -> frame simulado 1
%   (volta ao original com inv(G_i) e vai para o frame 1 com G_1)
H_true = zeros(3, 3, N);
for i = 1:N
    H_true(:,:,i) = G(:,:,1) / G(:,:,i);
end

%% 2. Gerar os frames simulados e extrair SIFT (com cache)
cache = fullfile(out_dir, sprintf('features_sim_%d.mat', N));
if isfile(cache)
    load(cache, 'feats');
    fprintf('Features lidas da cache: %s\n', cache);
else
    feats = cell(1, N);
    for i = 1:N
        I  = imread(fullfile(clip_dir, files(i).name));
        Is = imwarp(I, projtform2d(G(:,:,i)), 'OutputView', vista);
        imwrite(Is, fullfile(frames_dir, sprintf('sim_%04d.jpg', i)), 'Quality', 95);
        Gs = im2gray(Is);
        pts = detectSIFTFeatures(Gs);
        [f, vpts] = extractFeatures(Gs, pts);
        feats{i} = [double(vpts.Location)'; double(f)'];
        fprintf('frame %3d/%d: %d keypoints\n', i, N, size(feats{i}, 2));
    end
    save(cache, 'feats');
end

%% 3. Comparar as três estratégias com a verdade
params = struct('it_max', 500, 'limiar_coli', 0.05, 'limiar_inliers', 3, ...
                'nsuf_inliers', Inf, 'min_inliers', 30);
estrategias = {'frame a frame', Inf;
               'híbrida (10)',  10;
               'direto à ref',  1};

% grelha de pontos no frame i onde se mede o erro de transferência
[gx, gy] = meshgrid(linspace(1, W, 10), linspace(1, Hh, 6));
P = [gx(:)'; gy(:)'; ones(1, numel(gx))];

erro = nan(size(estrategias, 1), N);
for k = 1:size(estrategias, 1)
    p = params;
    p.reanchor_every = estrategias{k, 2};
    tic;
    [Hk, val] = track_sequence(feats, feats{1}, p);
    tempo = toc;
    for i = 1:N
        a = Hk(:,:,i)     * P;  a = a(1:2, :) ./ a(3, :);
        b = H_true(:,:,i) * P;  b = b(1:2, :) ./ b(3, :);
        erro(k, i) = mean(vecnorm(a - b));
    end
    fprintf('%-14s | erro médio %5.2f px | máx %5.2f px | último frame %5.2f px | falhas %d | %.1f s\n', ...
            estrategias{k, 1}, mean(erro(k, :)), max(erro(k, :)), erro(k, end), ...
            sum(~val), tempo);
    if k == 2
        H_hib = Hk;  val_hib = val;
    end
end

figure('Name', 'Erro vs verdade');
plot(1:N, erro', '.-'); grid on;
xlabel('frame'); ylabel('erro médio de transferência (px)');
legend(estrategias(:, 1), 'Location', 'best');
title('Erro de cada estratégia face à homografia verdadeira');
saveas(gcf, fullfile(out_dir, 'erro_estrategias.png'));

%% 4. Verificação visual: último frame simulado deformado para o frame 1
Is1 = imread(fullfile(frames_dir, sprintf('sim_%04d.jpg', 1)));
IsN = imread(fullfile(frames_dir, sprintf('sim_%04d.jpg', N)));
Iw  = imwarp(IsN, projtform2d(H_hib(:,:,N) / H_hib(3,3,N)), 'OutputView', vista);
figure('Name', 'Último frame -> frame 1');
subplot(1, 3, 1); imshow(Is1); title('frame 1 (referência)');
subplot(1, 3, 2); imshow(IsN); title(sprintf('frame %d (com zoom e pan)', N));
subplot(1, 3, 3); imshowpair(Is1, Iw, 'falsecolor'); title('frame N deformado (cinzento = alinhado)');
saveas(gcf, fullfile(out_dir, 'overlay_ultimo.png'));

%% 5. Vídeo: frame simulado (esq.) | estabilizado com a híbrida (dir.)
v = VideoWriter(fullfile(out_dir, 'estabilizado_simulado.mp4'), 'MPEG-4');
v.FrameRate = 15;
open(v);
for i = 1:N
    Is = imread(fullfile(frames_dir, sprintf('sim_%04d.jpg', i)));
    Iw = imwarp(Is, projtform2d(H_hib(:,:,i) / H_hib(3,3,i)), 'OutputView', vista);
    lado = [Is, Iw];
    if ~val_hib(i)
        lado = insertText(lado, [20 20], 'FALHOU', 'FontSize', 28, ...
                          'BoxColor', 'red', 'TextColor', 'white');
    end
    writeVideo(v, imresize(lado, 0.5));
end
close(v);
fprintf('Vídeo: %s\n', fullfile(out_dir, 'estabilizado_simulado.mp4'));
