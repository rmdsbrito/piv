% test_ransac.m
% Teste sintético do RANSAC. Precisa de: RANSAC.m, normalization_homography.m,
% homography.m no path.
% Convenção: matches = [x_tr y_tr x y] (destino primeiro, origem depois).
clear; clc; rng(0);

% ---------- Parâmetros ----------
W = 1280; Hh = 720;                    % tamanho da imagem
H_true = [ 1.1   0.15  200;
          -0.1   0.9   100;
           1e-4  5e-5    1 ];          % perspetiva suave, como numa câmara real
N          = 100;                      % nº de correspondências
sigma      = 1;                        % ruído (px)
min_sin    = 0.05;                     % limiar de colinearidade
thresh     = 2.45 * sigma;             % limiar de inliers (chi2, 95%)
it_max     = 500;
nsuf       = inf;                      % nunca pára cedo (para o teste)

% ---------- Parte A: uma corrida, 30% de outliers ----------
[matches, is_out, ~] = make_data(H_true, N, 0.3, sigma, W, Hh);

[H_r, inl] = RANSAC(it_max, matches, min_sin, thresh, nsuf);
H_all = normalization_homography(matches(:,1:2), matches(:,3:4));  % sem RANSAC

test_pts = [rand(500,1)*W, rand(500,1)*Hh];       % pontos NOVOS, sem ruído
e_ransac = transfer_error(H_true, H_r,   test_pts);
e_all    = transfer_error(H_true, H_all, test_pts);

true_in = ~is_out;
recall    = sum(inl & true_in) / sum(true_in);
precision = sum(inl & true_in) / max(sum(inl), 1);

fprintf('--- Parte A (30%% outliers) ---\n');
fprintf('Erro com RANSAC     : %.3f px\n', e_ransac);
fprintf('Erro DLT sem RANSAC : %.3f px\n', e_all);
fprintf('Recall %.2f | Precisão %.2f | inliers aceites %d\n', recall, precision, sum(inl));

% ---------- Parte B: varrimento da fração de outliers ----------
fracs = [0.3 0.5 0.7 0.8];
reps  = 30;
fprintf('\n--- Parte B (it_max = %d, %d repetições) ---\n', it_max, reps);
fprintf('outliers | erro mediano | recall mediano | falhas (>5px)\n');
for f = fracs
    errs = zeros(reps,1); recs = zeros(reps,1);
    for r = 1:reps
        [m, io, ~] = make_data(H_true, N, f, sigma, W, Hh);
        [Hr, in_r] = RANSAC(it_max, m, min_sin, thresh, nsuf);
        errs(r) = transfer_error(H_true, Hr, test_pts);
        recs(r) = sum(in_r & ~io) / sum(~io);
    end
    fprintf('   %.0f%%   |  %8.3f    |      %.2f      |   %d/%d\n', ...
        100*f, median(errs), median(recs), sum(errs > 5), reps);
end

% =====================================================================
function [matches, is_out, src] = make_data(H, N, frac_out, sigma, W, Hh)
    src = [rand(N,1)*W, rand(N,1)*Hh];
    dst = apply_H(H, src) + sigma * randn(N,2);   % ruido DEPOIS de dividir por w
    k = round(frac_out * N);
    is_out = false(N,1);
    is_out(randperm(N, k)) = true;
    dst(is_out,:) = [rand(k,1)*W, rand(k,1)*Hh];  % outliers: destinos aleatórios
    matches = [dst, src];
end

function p2 = apply_H(H, p)          % p: N x 2
    h = H * [p, ones(size(p,1),1)]';
    p2 = (h(1:2,:) ./ h(3,:))';
end

function e = transfer_error(H_true, H_est, pts)
    if isempty(H_est), e = inf; return; end      % RANSAC falhou
    d = apply_H(H_true, pts) - apply_H(H_est, pts);
    e = mean(sqrt(sum(d.^2, 2)));
end