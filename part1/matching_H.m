function [H, n_inl, inliers, matches] = matching_H(kp_dst, kp_src, params)
% MATCHING_H:  Homografia entre duas imagens a partir dos keypoints.
%
%   [H, n_inl, inliers, matches] = matching_H(kp_dst, kp_src, params)
%
%   Matching + RANSAC entre duas imagens quaisquer, indiferente se por 
%   frame anterior ou imagem de referência), função não sabe nem 
%   precisa de saber qual é qual.
%
%   Entradas:
%     kp_dst  kp da imagem de destino (130 x n): linhas 1-2 = (x, y),
%             linhas 3-130 = descritor
%     kp_src  kp da imagem de origem, mesmo formato
%     params  struct; todos os campos são opcionais
%
%   Saídas:
%     H        3x3 que leva píxeis da imagem src para a imagem dst,
%              ou [] se não houver pelo menos o numero minimo de inliers
%              (que é 'min_inliers').
%     n_inl    nº de inliers do RANSAC
%     inliers  true/false dos inliers (nº de matches x 1)
%     matches  [x_dst y_dst x_src y_src], todos os matches (antes do RANSAC)
%
%   Parâmetros (params.<nome>, valor por omissão)
%     it_max          500    iterações do RANSAC
%     limiar_coli     0.05   limiar de quase-colinearidade (seno do ângulo)
%     limiar_inliers  3      erro máximo (px) para um match ser inlier
%     nsuf_inliers    Inf    RANSAC pára cedo se atingir este nº de inliers
%     min_inliers     30     mínimo de inliers para aceitar a homografia
%     match_fn        @match_provisorio
%                            função matches = f(kp_dst, kp_src) que devolve
%                            [x_dst y_dst x_src y_src] (convenção do RANSAC)
%
%   Usa: RANSAC.m e normalization_homography.m

if nargin < 3, params = struct(); end
it_max         = get_param(params, 'it_max', 500);
limiar_coli    = get_param(params, 'limiar_coli', 0.05);
limiar_inliers = get_param(params, 'limiar_inliers', 3);
nsuf_inliers   = get_param(params, 'nsuf_inliers', Inf);
min_inliers    = get_param(params, 'min_inliers', 30);
match_fn       = get_param(params, 'match_fn', @match_provisorio);

H = [];  n_inl = 0;
matches = match_fn(kp_dst, kp_src);
inliers = false(size(matches, 1), 1);

if size(matches, 1) < max(min_inliers, 4)
    return;                                     % poucos matches: nem tenta
end

[H_r, inliers] = RANSAC(it_max, matches, limiar_coli, limiar_inliers, nsuf_inliers);
n_inl = sum(inliers);
if ~isempty(H_r) && n_inl >= min_inliers
    H = H_r;
end
end


% -------------------------------------------------------------------------
function m = match_provisorio(kp_dst, kp_src)
% PROVISÓRIO, até vir o match_features do Zé.
% Segue lógica de vizinho mais próximo.
% So emparalha descritores, NÃO remove outliers geométricos 
% (isso fica para o RANSAC). 
% MatchThreshold = 100 desliga o limiar absoluto,
% para o critério ser só o ratio test.

if isempty(kp_dst) || isempty(kp_src)
    m = zeros(0, 4);
    return;
end
f_dst = single(kp_dst(3:end, :))';
f_src = single(kp_src(3:end, :))';
pares = matchFeatures(f_dst, f_src, 'MaxRatio', 0.8, 'Unique', true, ...
                      'MatchThreshold', 100);
m = double([kp_dst(1:2, pares(:, 1))', kp_src(1:2, pares(:, 2))']);
end


function v = get_param(params, nome, omissao)
if isfield(params, nome) && ~isempty(params.(nome))
    v = params.(nome);
else
    v = omissao;
end
end
